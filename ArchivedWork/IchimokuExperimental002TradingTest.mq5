//+------------------------------------------------------------------+
//|                                     IchimokuExperimental002TradingTest.mq5 |
//|                                   Copyright 2017, investdatasystems@yahoo.com|
//|                                   https://ichimoku-expert.blogspot.com |
//+------------------------------------------------------------------+

//notif:android mt5,mt4=DB4F3016,EEF637E9,997CD24C,E0358708,96ABD519,B22E3F84
//contient aussi le code pour dumper les données ichimoku vers csv

//A n'utiliser que sur l'EURUSD ; Backtest sur 01/01/2016 au 25/01/2017 : 10000-13083,40
//A n'utiliser que sur timeframe 15 minute !

//ok en profit eurusd eurcad
//a creuser : nzdchf


#property copyright "Copyright 2017, investdatasystems@yahoo.com"
#property link      "https://ichimoku-expert.blogspot.com"
#property version   "1.01"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

CAccountInfo accountInfo;
double initialEquity = 0;
double currentEquity = 0;

input bool exportPrices=false;
int file_handle=INVALID_HANDLE; // File handle
input int scanPeriod=20;
input bool onlySymbolsInMarketwatch=true;
input string symbolToIgnore="EURCZK";
// TODO : Gérer plusieurs symboles séparés par des virgules

string appVersion="PEqSSB-CTF";
string versionInfo="This version scans for price == SSB on current timeframe ("+EnumToString(Period())+")";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0');

   string output="";
   output = timestamp + " Starting Ichimoku EA 2017 " + appVersion + " investdatasystems@yahoo.com";
   output = output + " Version info : " + versionInfo;
   output = output + " https://ichimoku-ea.000webhostapp.com/";
   printf(output);
   SendNotification(output);
//resetAllRemoteData();
//output="Version info : "+versionInfo;
//printf(output);
//SendNotification(output);
//output = "exportPrices = " + exportPrices;
//printf(output);
//SendNotification(output);
   if(exportPrices)
     {
      printf("exportDir = "+TerminalInfoString(TERMINAL_COMMONDATA_PATH));
     }

   ObjectsDeleteAll(0,"",-1,-1);
//CloseAllPositions();
//--- create timer
   EventSetTimer(scanPeriod); // 30 secondes pour tout (pas seulement marketwatch)

   initialEquity=accountInfo.Equity();
//ReadLinearRegressionChannelData();

   if(exportPrices)
     {
      //--- Create file to write data in the common folder of the terminal
      //C:\Users\Idjed\AppData\Roaming\MetaQuotes\Terminal\Common\Files
      MqlDateTime mqd;
      TimeCurrent(mqd);
      string timestamp=string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');

      file_handle=FileOpen(timestamp+"_backup.csv",FILE_CSV|FILE_WRITE|FILE_ANSI|FILE_COMMON);
      if(file_handle>0)
        {
         FileWrite(file_handle,"Timestamp;Name;Period;Buy;Sell;Tenkan;Kijun;Chikou(t-26);SSA;SSB");
        }
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

//CloseAllPositions();

   if(exportPrices)
     {
      //--- Close the file
      FileClose(file_handle);
     }

// Synthèse à la fin d'un backtest
   color BuyColor =clrBlue;
   color SellColor=clrRed;
//--- request trade history 
   HistorySelect(0,TimeCurrent());
//--- create objects 
   string   name;
   uint     total=HistoryDealsTotal();
   ulong    ticket=0;
   double price;
   double   profit;
   double totalprofit;
   datetime time;
   string   symbol;
   long     type;
   long     entry;
//--- for all deals 
   int winning= 0;
   int losing = 0;
   for(uint i=0;i<total;i++)
     {
      //--- try to get deals ticket 
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- get deals properties 
         price =HistoryDealGetDouble(ticket,DEAL_PRICE);
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         if(price && time && symbol==Symbol())
           {
            name="TradeHistory_Deal_"+string(ticket);
            //printf("type=" + type);
            if(type==1) printf("name = "+name+" profit= "+string(profit));
            if(profit>=0 && type==1) winning++;
            if(profit<0 && type==1) losing++;

            totalprofit+=profit;
           }
        }
     }

   printf("Total profit = "+NormalizeDouble(totalprofit,2));

   double percentlosing=0;
   double percentwinning=0;

   if(winning+losing!=0)
     {
      percentlosing=losing*100/(winning+losing);
      percentwinning=winning*100/(winning+losing);
     }

   printf("Winning trades = "+winning);
   printf("Losing trades = "+losing);
   printf("Total trades = "+(winning+losing));

   printf("Percent losing trades = "+NormalizeDouble(percentlosing,2));
   printf("Percent winning trades = "+NormalizeDouble(percentwinning,2));

//--- apply on chart 
//ChartRedraw();

//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   Ichimoku();

   return;

   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);
   double sell=lasttick.bid,buy=lasttick.ask,spread=buy-sell;
   ulong vol=lasttick.volume;
//printf("sell="+string(sell)+" ; buy="+string(buy)+ " ; spread="+string(spread) + " ; vol="+string(vol));

  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
datetime allowed_until=D'2017.12.15 00:00';
bool expiration_notified=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*if(TimeCurrent()>allowed_until)
     {
      if(expiration_notified==false)
        {
         string output = "Ichimoku EA 2017 " + appVersion + " : EXPIRED. Please contact investdatasystems@yahoo.com ";
         printf(output);
         SendNotification(output);
         expiration_notified=true;
        }
      return;
     }

   Ichimoku();*/

//currentEquity = accountInfo.Equity();
//double deltaEquity = currentEquity-initialEquity;
//printf("currentEquity-initialEquity=" + string(deltaEquity));
//SendNotification("currentEquity-initialEquity=" + deltaEquity);
  }

bool first_run_done[];

int maxhisto=64;

bool initdone=false;
int stotal=0;
//bool onlySymbolsInMarketwatch=true;
//datetime allowed_until = D'2016.01.15 00:00';
//bool expiration_notified = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ichimoku()
  {
   int tenkan_sen = 9;              // period of Tenkan-sen
   int kijun_sen = 26;              // period of Kijun-sen
   int senkou_span_b = 52;          // period of Senkou Span B

//--- indicator buffer
   double tenkan_sen_buffer[];
   double kijun_sen_buffer[];
   double senkou_span_a_buffer[];
   double senkou_span_b_buffer[];
   double chikou_span_buffer[];

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   if(!initdone)
     {
      ArrayResize(first_run_done,stotal,stotal);

      //initialisation de tout le tableau à false car sinon la première valeur vaut true par défaut (bug?).
      for(int sindex=0; sindex<stotal; sindex++)
        {
         first_run_done[sindex]=false;
        }

      initdone=true;
     }

/*int processingStart=GetTickCount();
   string output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" ("+EnumToString(Period())+")";
   output+=" Processing start = "+IntegerToString(processingStart);
   printf(output);*/

// Attention on récupère ici les données de l'avant dernière bougie (la bougie avant la bougie en cours) ; index = 1
   double open_array[];
   ArraySetAsSeries(open_array,true);
   int numO=CopyOpen(Symbol(),Period(),0,5,open_array);

   double high_array[];
   ArraySetAsSeries(high_array,true);
   int numH=CopyHigh(Symbol(),Period(),0,5,high_array);

   double low_array[];
   ArraySetAsSeries(low_array,true);
   int numL=CopyLow(Symbol(),Period(),0,5,low_array);

   double close_array[];
   ArraySetAsSeries(close_array,true);
   int numC=CopyClose(Symbol(),Period(),0,5,close_array);

   int handle;

   double price= 0;
   double sell = 0;
   double buy=0;
   double spread=0;
   double vol=0;

   handle=iIchimoku(Symbol(),Period(),tenkan_sen,kijun_sen,senkou_span_b);
   if((handle!=INVALID_HANDLE))
     {
      int max=maxhisto;

      int nbt = CopyBuffer(handle, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
      int nbk = CopyBuffer(handle, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
      int nbssa = CopyBuffer(handle, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
      int nbssb = CopyBuffer(handle, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
      int nbc=CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

      MqlTick lasttick;
      SymbolInfoTick(Symbol(),lasttick);
      price= lasttick.ask;
      sell = lasttick.bid; buy = lasttick.ask; spread = buy-sell;
      ulong vol=lasttick.volume;

      //printf("buy p="+buy+ " ; ssb="+senkou_span_b_buffer[0]);

      MqlDateTime mqd;
      TimeCurrent(mqd);
      string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0')+"."+GetTickCount();
      double chikou=0;
      if(ArraySize(chikou_span_buffer)>26)
        {
         chikou=chikou_span_buffer[26];
        }

      if(exportPrices)
        {
         if(file_handle>0)
           {
            FileWrite(file_handle,timestamp+";"+Symbol()+";"+EnumToString(Period())+";"+DoubleToString(buy)+";"+DoubleToString(sell)+";"+DoubleToString(tenkan_sen_buffer[0])+";"+DoubleToString(kijun_sen_buffer[0])+";"+DoubleToString(chikou)+";"+DoubleToString(senkou_span_a_buffer[0])+";"+DoubleToString(senkou_span_b_buffer[0]));
            //sell affiché par défaut dans MT5
           }
        }

      // Pour n'avoir qu'une position par instrument...         
      int postotal=PositionsTotal();
      bool positionOpened=false;
      for(int i=0;i<postotal;i++)
        {
         bool b=PositionSelect(Symbol());
         if(b==true)
           {
            // Il y a une position de trouvée pour cet instrument financier
            positionOpened=true;
            //double profit = PositionGetDouble(POSITION_PROFIT);
            //printf("profit for "+sname+" = "+DoubleToString(profit));
/*if (profit > 1){
                  CTrade trade;
                  trade.PositionClose(sname);                 
               }*/
              } else {
            //printf("no position opened for " + sname);
           }
        }

      // 31/101 perdants eurusd avec checkperiod M5 et en tf M15 sur 1 an, sans test ts>ks
      bool isNewBar=IsNewBar();

      //ssa-ssb worst trade : 1.040710-1.038710=0.00200
      if(positionOpened==false
         && isNewBar
         //&& checkPeriod(PERIOD_M10)
         && checkPeriodUp(PERIOD_M5)
         //&& checkPeriodUp(PERIOD_M15)
         )
        {

         // si passe au-dessus du kumo avec SSA>SSB
         if(
            (numO!=-1 && numH!=-1 && numL!=-1 && numC!=-1)
            && (senkou_span_a_buffer[0]>senkou_span_b_buffer[0])
            && (
            ((high_array[2]>senkou_span_a_buffer[2]) && (low_array[2]<senkou_span_a_buffer[2]))
            || ((high_array[2]<senkou_span_a_buffer[2]) && (low_array[2]<senkou_span_a_buffer[2]))
            )
            && ((high_array[1]>senkou_span_a_buffer[1]) && (low_array[1]>senkou_span_a_buffer[1]))
            )
           {
            double takeprofit=buy+0.00200;
            double stoploss=buy-0.00400;
            BUY(Symbol(),buy,stoploss,takeprofit);
            string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0');
            string output="";
            output=timestamp+" BUY "+Symbol()+" "+EnumToString(Period())+ " spread=" + NormalizeDouble(spread,6);
            output=output + " buy=" + buy + " tp=" + NormalizeDouble(takeprofit,6) + "(+" + NormalizeDouble(takeprofit-buy,6) + ")" + " sl=" + NormalizeDouble(stoploss,6) + "(-" + NormalizeDouble(buy-stoploss,6) + ")";
            printf(output);
            SendNotification(output);
           }

        }


      // Pour n'avoir qu'une position par instrument...         
      postotal=PositionsTotal();
      positionOpened=false;
      for(int i=0;i<postotal;i++)
        {
         bool b=PositionSelect(Symbol());
         if(b==true)
           {
            // Il y a une position de trouvée pour cet instrument financier
            positionOpened=true;
              } else {
            //printf("no position opened for " + sname);
           }
        }


      //ssa-ssb worst trade : 1.040710-1.038710=0.00200
      if(positionOpened==false
         && isNewBar
         //&& checkPeriod(PERIOD_M10)
         && checkPeriodDown(PERIOD_M5)
         //&& checkPeriodUp(PERIOD_M15)
         )
        {

         // si passe sous le kumo avec SSB>SSA
         if(
            (numO!=-1 && numH!=-1 && numL!=-1 && numC!=-1)
            && (senkou_span_b_buffer[0]>senkou_span_a_buffer[0])
            && (
                  ( (high_array[2]>senkou_span_a_buffer[2]) && (low_array[2]<senkou_span_a_buffer[2]) )
                  || ((high_array[2]>senkou_span_a_buffer[2]) && (low_array[2]>senkou_span_a_buffer[2]))
            )
            && ((high_array[1]<senkou_span_a_buffer[1]) && (low_array[1]<senkou_span_a_buffer[1]))
            )
           {
            double takeprofit=sell-0.00200;
            double stoploss=sell+0.00400;
            SELL(Symbol(),sell,stoploss,takeprofit);
            string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0');
            string output="";
            output=timestamp+" SELL "+Symbol()+" "+EnumToString(Period())+ " spread=" + NormalizeDouble(spread,6);
            output=output + " sell=" + sell + " tp=" + NormalizeDouble(takeprofit,6) + "(-" + NormalizeDouble(takeprofit-sell,6) + ")" + " sl=" + NormalizeDouble(stoploss,6) + "(+" + NormalizeDouble(sell-stoploss,6) + ")";
            printf(output);
            SendNotification(output);
           }

        }

      IndicatorRelease(handle);

      ArrayFree(tenkan_sen_buffer);
      ArrayFree(kijun_sen_buffer);
      ArrayFree(senkou_span_a_buffer);
      ArrayFree(senkou_span_b_buffer);
      ArrayFree(chikou_span_buffer);

     } // fin boucle sur sindex (symbol index)

/*int processingEnd=GetTickCount();
   int processingDelta=processingEnd-processingStart;
   int seconds=processingDelta/1000;
   output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" ("+EnumToString(Period())+") : Total processing time = "+IntegerToString(processingDelta)+"ms = "+IntegerToString(seconds)+"s";
   output+= " Memory used = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE));
   output+= " Memory total = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_TOTAL));
   printf(output);*/
//SendNotification(output);

   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkPeriodUp(ENUM_TIMEFRAMES period)
  {
   bool result=false;

   double open_array[];
   ArraySetAsSeries(open_array,true);
   int numO=CopyOpen(Symbol(),period,0,5,open_array);

   double high_array[];
   ArraySetAsSeries(high_array,true);
   int numH=CopyHigh(Symbol(),period,0,5,high_array);

   double low_array[];
   ArraySetAsSeries(low_array,true);
   int numL=CopyLow(Symbol(),period,0,5,low_array);

   double close_array[];
   ArraySetAsSeries(close_array,true);
   int numC=CopyClose(Symbol(),period,0,5,close_array);

   int tenkan_sen = 9;              // period of Tenkan-sen
   int kijun_sen = 26;              // period of Kijun-sen
   int senkou_span_b = 52;          // period of Senkou Span B

//--- indicator buffer
   double tenkan_sen_buffer[];
   double kijun_sen_buffer[];
   double senkou_span_a_buffer[];
   double senkou_span_b_buffer[];
   double chikou_span_buffer[];

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   int handle;

   handle=iIchimoku(Symbol(),period,tenkan_sen,kijun_sen,senkou_span_b);
   if((handle!=INVALID_HANDLE))
     {
      int max=maxhisto;

      int nbt = CopyBuffer(handle, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
      int nbk = CopyBuffer(handle, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
      int nbssa = CopyBuffer(handle, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
      int nbssb = CopyBuffer(handle, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
      int nbc=CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

      MqlTick lasttick;
      SymbolInfoTick(Symbol(),lasttick);
      double price= lasttick.ask;
      double sell = lasttick.bid;
      double buy=lasttick.ask;
      double spread=buy-sell;
      ulong vol=lasttick.volume;

      MqlDateTime mqd;
      TimeCurrent(mqd);
      string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0')+"."+GetTickCount();
      double chikou=0;

      if(
         //(tenkan_sen_buffer[0]>kijun_sen_buffer[0])
         (chikou_span_buffer[26]>senkou_span_a_buffer[26])
         && (chikou_span_buffer[26]>senkou_span_b_buffer[26])
         && (chikou_span_buffer[26]>tenkan_sen_buffer[26])
         && (chikou_span_buffer[26]>kijun_sen_buffer[26])
         && (high_array[1]>senkou_span_a_buffer[1])
         && (low_array[1]>senkou_span_a_buffer[1])
         && (high_array[1]>senkou_span_b_buffer[1])
         && (low_array[1]>senkou_span_b_buffer[1])
         && (high_array[1]>tenkan_sen_buffer[1])
         && (low_array[1]>tenkan_sen_buffer[1])
         && (high_array[1]>kijun_sen_buffer[1])
         && (low_array[1]>kijun_sen_buffer[1])
         )
        {
         // CS>SSA et CS>SSB etc...
         result=true;
        }

     }

   IndicatorRelease(handle);
//if(result==false) { printf("result = false"); }

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkPeriodDown(ENUM_TIMEFRAMES period)
  {
   bool result=false;

   double open_array[];
   ArraySetAsSeries(open_array,true);
   int numO=CopyOpen(Symbol(),period,0,5,open_array);

   double high_array[];
   ArraySetAsSeries(high_array,true);
   int numH=CopyHigh(Symbol(),period,0,5,high_array);

   double low_array[];
   ArraySetAsSeries(low_array,true);
   int numL=CopyLow(Symbol(),period,0,5,low_array);

   double close_array[];
   ArraySetAsSeries(close_array,true);
   int numC=CopyClose(Symbol(),period,0,5,close_array);

   int tenkan_sen = 9;              // period of Tenkan-sen
   int kijun_sen = 26;              // period of Kijun-sen
   int senkou_span_b = 52;          // period of Senkou Span B

//--- indicator buffer
   double tenkan_sen_buffer[];
   double kijun_sen_buffer[];
   double senkou_span_a_buffer[];
   double senkou_span_b_buffer[];
   double chikou_span_buffer[];

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   int handle;

   handle=iIchimoku(Symbol(),period,tenkan_sen,kijun_sen,senkou_span_b);
   if((handle!=INVALID_HANDLE))
     {
      int max=maxhisto;

      int nbt = CopyBuffer(handle, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
      int nbk = CopyBuffer(handle, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
      int nbssa = CopyBuffer(handle, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
      int nbssb = CopyBuffer(handle, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
      int nbc=CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

      MqlTick lasttick;
      SymbolInfoTick(Symbol(),lasttick);
      double price= lasttick.ask;
      double sell = lasttick.bid;
      double buy=lasttick.ask;
      double spread=buy-sell;
      ulong vol=lasttick.volume;

      //printf("buy p="+buy+ " ; ssb="+senkou_span_b_buffer[0]);

      MqlDateTime mqd;
      TimeCurrent(mqd);
      string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0')+"."+GetTickCount();
      double chikou=0;

      if(
         //(tenkan_sen_buffer[0]>kijun_sen_buffer[0])
         (chikou_span_buffer[26]<senkou_span_a_buffer[26])
         && (chikou_span_buffer[26]<senkou_span_b_buffer[26])
         && (chikou_span_buffer[26]<tenkan_sen_buffer[26])
         && (chikou_span_buffer[26]<kijun_sen_buffer[26])
         && (high_array[1]<senkou_span_a_buffer[1])
         && (low_array[1]<senkou_span_a_buffer[1])
         && (high_array[1]<senkou_span_b_buffer[1])
         && (low_array[1]<senkou_span_b_buffer[1])
         && (high_array[1]<tenkan_sen_buffer[1])
         && (low_array[1]<tenkan_sen_buffer[1])
         && (high_array[1]<kijun_sen_buffer[1])
         && (low_array[1]<kijun_sen_buffer[1])
         )
        {
         // CS<SSA et CS<SSB etc...
         result=true;
        }

     }

   IndicatorRelease(handle);
//if(result==false) { printf("CheckPeriodDown result = false"); }

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   CTrade trade;
   int i=PositionsTotal()-1;
   while(i>=0)
     {
      if(trade.PositionClose(PositionGetSymbol(i))) i--;
     }
  }

static int BARS;
//+------------------------------------------------------------------+
//| NewBar function                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   if(BARS!=Bars(_Symbol,_Period))
     {
      BARS=Bars(_Symbol,_Period);
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//printf("ontrade");
//---
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//---
//printf("ontradetransaction");
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
  {
//---

  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
  {
//---

  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
//---

  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
//---

  }
//+------------------------------------------------------------------+

void uploadSSBAlert(string timestamp,string period,string name,string type,double price,double ssb)
  {
// "https://ichimoku-ea.000webhostapp.com/?notification=test"
   string cookie=NULL,headers;
   char post[],result[];

   string ssbalert=timestamp+";"+period+";"+name+";"+type+";"+DoubleToString(price)+";"+DoubleToString(ssb);

   string google_url="https://ichimoku-ea.000webhostapp.com/?upload_ssb_alert="+ssbalert;
   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   int res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
   if(res==-1)
     {
      Print("Error in WebRequest. Error code  =",GetLastError());
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      //MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     }
   else
     {
      printf(CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      printf("SSB Alert sent successfully");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resetAllRemoteData()
  {
// "https://ichimoku-ea.000webhostapp.com/?notification=test"
   string cookie=NULL,headers;
   char post[],result[];
   string google_url="https://ichimoku-ea.000webhostapp.com/?reset_all=true";
   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   int res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
   if(res==-1)
     {
      Print("Error in WebRequest. Error code  =",GetLastError());
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      //MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     }
   else
     {
      printf(CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      printf("Reset command sent successfully");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resetSSBAlertsRemoteData()
  {
// "https://ichimoku-ea.000webhostapp.com/?notification=test"
   string cookie=NULL,headers;
   char post[],result[];
   string google_url="https://ichimoku-ea.000webhostapp.com/?reset_ssb_alerts=true";
   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   int res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
   if(res==-1)
     {
      Print("Error in WebRequest. Error code  =",GetLastError());
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      //MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     }
   else
     {
      printf(CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      printf("Reset command sent successfully");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BUY(string symbol,double price,double stoploss,double takeprofit)
  {
   MqlTick lasttick;
   SymbolInfoTick(symbol,lasttick);

//double price = lasttick.ask;
//double stoploss = price-stoplossdelta;
//double takeprofit = price+takeprofitdelta;

//--- declare and initialize the trade request and result of trade request
   MqlTradeRequest request={0};
   MqlTradeResult  result={0};
//--- parameters of request
   request.action=TRADE_ACTION_DEAL;                     // type of trade operation
   request.symbol=symbol;                              // symbol
   request.volume=1;                                   // volume of 0.1 lot
   request.type=ORDER_TYPE_BUY;                        // order type
   request.price=SymbolInfoDouble(symbol,SYMBOL_ASK); // price for opening
   request.sl = stoploss;
   request.tp = takeprofit;
   request.deviation=5;                                     // allowed deviation from the price
                                                            //request.magic    =EXPERT_MAGIC;                          // MagicNumber of the order
//--- send the request
   if(!OrderSend(request,result))
     {
      //PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
      return false;
     }
   else
     {
      //printf("order sent ok");
      return true;
     }

//printf("buy price=" + string(price) + " sl=" + string(stoploss) + " tp=" + string(takeprofit));

/*CTrade trade;
   if(trade.PositionOpen(
      symbol,
      ORDER_TYPE_BUY,
      0.1,
      price,
      stoploss,
      takeprofit,
      "Bought at "+string(price)+";sl="+string(stoploss)+";tp="+string(takeprofit)
      ))
     {
      printf("Buy ok at "+string(price)+" sl="+string(stoploss)+" tp="+string(takeprofit));
      SendNotification("Buy ok at "+string(price)+" sl="+string(stoploss)+" tp="+string(takeprofit));
      return true;
     }
   else
     {
      printf("Buy ERROR = "+string(GetLastError())+" ; ResultRetcode = "+string(trade.ResultRetcode()));
      SendNotification("Buy ERROR = "+string(GetLastError())+" ; ResultRetcode = "+string(trade.ResultRetcode()));
      return false;
     }*/
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SELL(string symbol,double price,double stoploss,double takeprofit)
  {
   MqlTick lasttick;
   SymbolInfoTick(symbol,lasttick);

//double price = lasttick.ask;
//double stoploss = price-stoplossdelta;
//double takeprofit = price+takeprofitdelta;

//--- declare and initialize the trade request and result of trade request
   MqlTradeRequest request={0};
   MqlTradeResult  result={0};
//--- parameters of request
   request.action=TRADE_ACTION_DEAL;                     // type of trade operation
   request.symbol=symbol;                              // symbol
   request.volume=1;                                   // volume of 0.1 lot
   request.type=ORDER_TYPE_SELL;                        // order type
   request.price=SymbolInfoDouble(symbol,SYMBOL_BID); // price for opening
   request.sl = stoploss;
   request.tp = takeprofit;
   request.deviation=5;                                     // allowed deviation from the price
                                                            //request.magic    =EXPERT_MAGIC;                          // MagicNumber of the order
//--- send the request
   if(!OrderSend(request,result))
     {
      //PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
      return false;
     }
   else
     {
      //printf("order sent ok");
      return true;
     }

//printf("buy price=" + string(price) + " sl=" + string(stoploss) + " tp=" + string(takeprofit));

/*CTrade trade;
   if(trade.PositionOpen(
      symbol,
      ORDER_TYPE_BUY,
      0.1,
      price,
      stoploss,
      takeprofit,
      "Bought at "+string(price)+";sl="+string(stoploss)+";tp="+string(takeprofit)
      ))
     {
      printf("Buy ok at "+string(price)+" sl="+string(stoploss)+" tp="+string(takeprofit));
      SendNotification("Buy ok at "+string(price)+" sl="+string(stoploss)+" tp="+string(takeprofit));
      return true;
     }
   else
     {
      printf("Buy ERROR = "+string(GetLastError())+" ; ResultRetcode = "+string(trade.ResultRetcode()));
      SendNotification("Buy ERROR = "+string(GetLastError())+" ; ResultRetcode = "+string(trade.ResultRetcode()));
      return false;
     }*/
  }
//+------------------------------------------------------------------+
