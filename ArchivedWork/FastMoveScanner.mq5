//+------------------------------------------------------------------+
//|                                              FastMoveScanner.mq5 |
//|                                 Copyright 2018, InvestDataSystems|
//|                 https://tradingbot.wixsite.com/robots-de-trading |
//+------------------------------------------------------------------+

#property copyright "Copyright 2018, InvestDataSystems"
#property link      "https://tradingbot.wixsite.com/robots-de-trading"
#property version   "1.00"


#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

double tenkan_sen_buffer[];
double kijun_sen_buffer[];
double senkou_span_a_buffer[];
double senkou_span_b_buffer[];
double chikou_span_buffer[];

double open_array[];
double high_array[];
double low_array[];
double close_array[];

MqlDateTime start_time;
//#include <Controls\Dialog.mqh>
//CAppDialog cAppDialog;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  TimeCurrent(start_time);
   /*cAppDialog = new CAppDialog();
   cAppDialog.Create(0, "test", 0, 40, 40,380,344);
   cAppDialog.Activate();
   cAppDialog.Show();*/
  
   printf("Started : FastMoveScanner v1.1 /// Timer="+IntegerToString(timerSeconds)+"s /// Min %% of move to show="+NormalizeDouble(minPercentOfMoveToShow,3)+"%% " + (excludeInstrumentsThatContains!=""?"/// Excluding : " + excludeInstrumentsThatContains:""));
   EventSetTimer(timerSeconds);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }

static int BARS;
static datetime LastBarTime=-1;

double previousAsk[];
double currentAsk=0;
double currentBid=0;
double pourcentMoyenne[];
bool initDone=false;
input int timerSeconds=1;
input double minPercentOfMoveToShow=0.0100;
input string excludeInstrumentsThatContains="MXN;TRY;XNG;XPD;XPT;UK100;SPX;J225;AUS200;XTI;STOXX50E;SPA35;XAG;XAU;FCHI40;GDAXI;NDX;WS30;NOK;SEK";
//input string excludeInstrumentsThatContains="";
//input string excludeInstrumentsThatContains="";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//printf("start time =" + GetTickCount());

   int stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)

   if(!initDone)
     {
      ArrayResize(previousAsk,stotal,stotal);
      ArrayResize(pourcentMoyenne,stotal,stotal);
      for(int sindex=0; sindex<stotal; sindex++)
        {
         previousAsk[sindex]=0;
         pourcentMoyenne[sindex]=0;
        }
      initDone=true;
     }

   for(int sindex=0; sindex<stotal; sindex++)
     {
      string sname=SymbolName(sindex,onlySymbolsInMarketwatch);
      currentAsk=SymbolInfoDouble(sname,SYMBOL_ASK);
      currentBid=SymbolInfoDouble(sname,SYMBOL_BID);

      if(previousAsk[sindex]>0)
        {
         double diff=currentAsk-previousAsk[sindex];
         if(MathAbs(diff)>0)
           {
            double pourcent=100*(currentAsk-previousAsk[sindex])/previousAsk[sindex];
            if(pourcentMoyenne[sindex] == 0)
               pourcentMoyenne[sindex] = pourcent;
            else
               pourcentMoyenne[sindex]=(pourcentMoyenne[sindex]+pourcent)/2;

            if(MathAbs(pourcent)>minPercentOfMoveToShow)
              {
               bool show = true;
               if (excludeInstrumentsThatContains != "")
               {
                  string result[];
                  StringSplit(excludeInstrumentsThatContains, ';', result);
                  if (ArraySize(result)>0)
                  {
                     for (int i=0;i<ArraySize(result);i++)
                     {
                        //printf(result[i]);
                        if (StringFind(sname, result[i]) != -1)
                        {
                           show = false;
                           break;
                        }
                     }
                  }
               }
              
               if(show == true)
                 {
                  double rsi_m1 = iRSI(sname,PERIOD_M1,14,PRICE_CLOSE); // surachat:rsi>70<=>il faut vendre ; survente:rsi<30<=>il faut acheter
                  double rsi_m5 = iRSI(sname,PERIOD_M5,14,PRICE_CLOSE); // surachat:rsi>70<=>il faut vendre ; survente:rsi<30<=>il faut acheter
                  double rsi_m15 = iRSI(sname,PERIOD_M15,14,PRICE_CLOSE); // surachat:rsi>70<=>il faut vendre ; survente:rsi<30<=>il faut acheter
                  string msg = TimeToString(TimeLocal())+" : "+sname+" : diff = "+NormalizeDouble(diff,5)+" : "+NormalizeDouble(pourcent,3)+"%%"+" : Average (since " + IntegerToString(start_time.day, 2, '0') + "/" + IntegerToString(start_time.mon,2,'0') + "/" + IntegerToString(start_time.year,2,'0') + " " + IntegerToString(start_time.hour,2,'0') + ":" + IntegerToString(start_time.min,2,'0')  + ") = "+NormalizeDouble(pourcentMoyenne[sindex],3)+"%%" +  " /// Rsi14(M1;M5;M15)=[" + rsi_m1 + "];[" + rsi_m5 + "];[" + rsi_m15 + "]";
                  msg += " /// Ask(Buy)=" + DoubleToString(currentAsk) + " Bid(Sell)=" + DoubleToString(currentBid);                  
                  printf(msg);
                  SendNotification(msg);
                 }
              }
           }
        }

      previousAsk[sindex]=currentAsk;
     }

//printf("end time =" + GetTickCount());
  }

bool onlySymbolsInMarketwatch=true;
bool done=false;
ENUM_TIMEFRAMES workingPeriod=PERIOD_H4;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ichimoku()
  {
   if(done == true) return;

   int stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)

   for(int sindex=0; sindex<stotal; sindex++)
     {
      string sname=SymbolName(sindex,onlySymbolsInMarketwatch);

      if(PriceCrossedKijunUp(sname,workingPeriod))
        {
         printf(sname+" crossed kijun while up in "+EnumToString(workingPeriod)+" ; TimeLocal() = "+TimeToString(TimeLocal()));
         if(ChikouSpanIsFree(sname,workingPeriod))
           {
            printf(sname+" : and Chikou Span Line is free");
           }
        }

     }

   done=true;
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BUY()
  {
   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);
   double spread=lasttick.ask-lasttick.bid; // spread = prix de vente - prix d'achat
   double price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);

   MqlTradeRequest tradeRequest={0};
   MqlTradeResult  tradeResult={0};
   tradeRequest.action=TRADE_ACTION_DEAL;
   tradeRequest.symbol=Symbol();
   tradeRequest.volume=0.5;
   tradeRequest.type=ORDER_TYPE_BUY;
   tradeRequest.price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);

   double stoploss=0,takeprofit=lasttick.bid+0.00100;
   tradeRequest.sl = stoploss;
   tradeRequest.tp = takeprofit;

   if(!OrderSend(tradeRequest,tradeResult))
     {
      PrintFormat(Symbol()+" : OrderSend error %d",GetLastError());
      return false;
     }
   else
     {
      printf(Symbol()+" : OrderSend ok");
      return true;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SELL()
  {
   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);
   double spread=lasttick.ask-lasttick.bid; // spread = prix de vente - prix d'achat
   double price = SymbolInfoDouble(Symbol(),SYMBOL_BID);

   MqlTradeRequest tradeRequest={0};
   MqlTradeResult  tradeResult={0};
   tradeRequest.action=TRADE_ACTION_DEAL;
   tradeRequest.symbol=Symbol();
   tradeRequest.volume=0.5;
   tradeRequest.type=ORDER_TYPE_SELL;
   tradeRequest.price=SymbolInfoDouble(Symbol(),SYMBOL_BID);

   double stoploss=0,takeprofit=lasttick.ask-0.00100;
   tradeRequest.sl = stoploss;
   tradeRequest.tp = takeprofit;

   if(!OrderSend(tradeRequest,tradeResult))
     {
      PrintFormat(Symbol()+" : OrderSend error %d",GetLastError());
      return false;
     }
   else
     {
      printf(Symbol()+" : OrderSend ok");
      return true;
     }
  }

int tenkan_sen_param = 9;              // period of Tenkan-sen
int kijun_sen_param = 26;              // period of Kijun-sen
int senkou_span_b_param = 52;          // period of Senkou Span B
int handleIchimoku=INVALID_HANDLE;
int max;
int nbt=-1,nbk=-1,nbssa=-1,nbssb=-1,nbc=-1;
int numO=-1,numH=-1,numL=-1,numC=-1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceIsOverKumo(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

// Obtenir les données Ichimoku

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

   if(open_array[1]>senkou_span_a_buffer[1]
      && open_array[1]>senkou_span_b_buffer[1]
      && close_array[1]>senkou_span_a_buffer[1]
      && close_array[1]>senkou_span_b_buffer[1]
      )
      Result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

bool PriceIsUnderKumo(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

// Obtenir les données Ichimoku

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

   if(open_array[1]<senkou_span_a_buffer[1]
      && open_array[1]<senkou_span_b_buffer[1]
      && close_array[1]<senkou_span_a_buffer[1]
      && close_array[1]<senkou_span_b_buffer[1]
      )
      Result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChikouSpanIsFree(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=32;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

//(chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])

   if(chikou_span_buffer[26]>senkou_span_a_buffer[26]
      && chikou_span_buffer[26]>senkou_span_b_buffer[26]
      && chikou_span_buffer[26]>tenkan_sen_buffer[26]
      && chikou_span_buffer[26]>kijun_sen_buffer[26]
      && chikou_span_buffer[26]>open_array[26]
      && chikou_span_buffer[26]>close_array[26]
      )
      Result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

bool PriceCrossedKumoSsbUp(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

//(chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])

   if(
      (open_array[1]<senkou_span_b_buffer[1] && close_array[1]>senkou_span_b_buffer[1])
      || (open_array[2]<senkou_span_b_buffer[2] && close_array[2]<senkou_span_b_buffer[2] && open_array[1]>senkou_span_b_buffer[1] && close_array[1]>senkou_span_b_buffer[1])
      || (open_array[2]<senkou_span_b_buffer[2] && close_array[2]<senkou_span_b_buffer[2] && open_array[1]<senkou_span_b_buffer[1] && close_array[1]>senkou_span_b_buffer[1])
      || (open_array[2]<senkou_span_b_buffer[2] && close_array[2]>senkou_span_b_buffer[2] && open_array[1]>senkou_span_b_buffer[1] && close_array[1]>senkou_span_b_buffer[1])
      )
      Result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return Result;
  }

bool Result;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceCrossedKijunUp(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

//(chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])

/*if(
      (open_array[1]<kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[2]<kijun_sen_buffer[2] && close_array[2]<kijun_sen_buffer[2] && open_array[1]>kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[2]<kijun_sen_buffer[2] && close_array[2]<kijun_sen_buffer[2] && open_array[1]<kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[2]<kijun_sen_buffer[2] && close_array[2]>kijun_sen_buffer[2] && open_array[1]>kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      )
      Result=true;*/

   if(
      (open_array[1]<kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[0]<kijun_sen_buffer[0] && close_array[0]>kijun_sen_buffer[0])
      )
      Result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceCrossedKijunDown(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

//(chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])

   if(
      (open_array[1]>kijun_sen_buffer[1] && close_array[1]<kijun_sen_buffer[1])
      || (open_array[2]>kijun_sen_buffer[2] && close_array[2]>kijun_sen_buffer[2] && open_array[1]<kijun_sen_buffer[1] && close_array[1]<kijun_sen_buffer[1])
      || (open_array[2]>kijun_sen_buffer[2] && close_array[2]>kijun_sen_buffer[2] && open_array[1]>kijun_sen_buffer[1] && close_array[1]<kijun_sen_buffer[1])
      || (open_array[2]>kijun_sen_buffer[2] && close_array[2]<kijun_sen_buffer[2] && open_array[1]<kijun_sen_buffer[1] && close_array[1]<kijun_sen_buffer[1])
      )
      Result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceIsOverKijun(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

//(chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])

   if(open_array[1]>kijun_sen_buffer[1]
      && open_array[1]>kijun_sen_buffer[1]
      && close_array[1]>kijun_sen_buffer[1]
      && close_array[1]>kijun_sen_buffer[1]
      )
      Result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return Result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int handleRsi=INVALID_HANDLE;
double iRSIBuffer[];
int ResultRsi;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getRSI(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   handleRsi=iRSI(Symbol,TimeFrame,14,PRICE_CLOSE);

   ArraySetAsSeries(iRSIBuffer,true);
   CopyBuffer(handleRsi,0,0,3,iRSIBuffer);

   ResultRsi=(int) iRSIBuffer[0];

   ArrayFree(iRSIBuffer);
   IndicatorRelease(handleRsi);

   return "["+IntegerToString(ResultRsi)+"]";
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ScanForHorizontalLines(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=64;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,32,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,32,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,32,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,32,close_array);

// Traitements ici

   for(int i=0;i<max-3;i++)
     {
      if(kijun_sen_buffer[i]==kijun_sen_buffer[i+1] && kijun_sen_buffer[i+1]==kijun_sen_buffer[i+2])
        {
         printf("Horizontal Kijun Sen level detected in "+StringSubstr(EnumToString(TimeFrame),7)+" = "+DoubleToString(kijun_sen_buffer[i]));
        }
     }

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

  }
//+------------------------------------------------------------------+

MqlDateTime mqd;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getTimeStamp()
  {
   TimeCurrent(mqd);
   return string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');
  }
//+------------------------------------------------------------------+

/*void OnTimer()
  {
   datetime ThisBarTime=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   if(ThisBarTime==LastBarTime)
     {
      //printf("Same bar time ("+Symbol()+")");
     }
   else
     {
      if(LastBarTime==-1)
        {
         //printf("First bar ("+Symbol()+")");
         LastBarTime=ThisBarTime;
        }
      else
        {
         //printf("New bar time ("+Symbol()+")");
         LastBarTime=ThisBarTime;

         Ichimoku();
        }
     }
  }*/
//+------------------------------------------------------------------+
