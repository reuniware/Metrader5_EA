//+------------------------------------------------------------------+
//|                                     IchimokuExperimental002-2JCS.mq5 |
//|                                   Copyright 2017, investdatasystems@yahoo.com|
//|                                   https://ichimoku-expert.blogspot.com |
//+------------------------------------------------------------------+

//IchimokuExperimental003-2JCS.mq5

//Objectif : Détecter tendance sur M1 puis si ok alors vérifier sur unités supérieures


//notif:android mt5:327C822F

#property copyright "Copyright 2017, Investdata Systems"
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
input int scanPeriod=15;
input bool onlySymbolsInMarketwatch=true;
input string symbolToIgnore="EURCZK";
input bool disableUploadHistory = true;

// TODO : Gérer plusieurs symboles séparés par des virgules

string appVersion="2JCSxSSAorSSB-CTF";
string versionInfo="Scans 2 last candlesticks with SSA/SSB on current timeframe ("+EnumToString(Period())+")";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0');

   string output="";
   output = timestamp + " Starting " + StringSubstr(__FILE__,0,StringLen(__FILE__)-4) + " " + appVersion + " Investdata Systems";
   output = output + " Version info : " + versionInfo;
   output = output + " https://ichimoku-ea.000webhostapp.com/";
   printf(output);
   //SendNotification(output);

   if(exportPrices)
     {
      printf("exportDir = "+TerminalInfoString(TERMINAL_COMMONDATA_PATH));
     }

   ObjectsDeleteAll(0,"",-1,-1);

   EventSetTimer(scanPeriod); // 30 secondes pour tout (pas seulement marketwatch)

   initialEquity=accountInfo.Equity();

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

   if(exportPrices)
     {
      //--- Close the file
      FileClose(file_handle);
     }

   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //Ichimoku(); 
   
   stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)
   for(int sindex=0; sindex<stotal; sindex++)
   {
      MqlDateTime mqd;
      TimeCurrent(mqd);

      string timestamp=string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');
      timestamp+=IntegerToString(GetTickCount());
      string sname=SymbolName(sindex,onlySymbolsInMarketwatch);
   
      MqlTick lasttick;
      SymbolInfoTick(sname,lasttick);
      double price= lasttick.ask;
      double sell = lasttick.bid; double buy = lasttick.ask; double spread = buy-sell;
      ulong vol=lasttick.volume;

      uploadHistory(timestamp, sname, buy, sell);      
   }
   
   return;
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
datetime allowed_until=D'2018.12.15 00:00';
bool expiration_notified=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   /*if(TimeCurrent()>allowed_until)
     {
      if(expiration_notified==false)
        {
         string output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" "+appVersion+" : EXPIRED. Please contact Investdata Systems ";
         printf(output);
         SendNotification(output);
         expiration_notified=true;
        }
      return;
     }*/

   Ichimoku();

//currentEquity = accountInfo.Equity();
//double deltaEquity = currentEquity-initialEquity;
//printf("currentEquity-initialEquity=" + string(deltaEquity));
//SendNotification("currentEquity-initialEquity=" + deltaEquity);
  }

bool first_run_done[];

static int BARS[];

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
      stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)

      ArrayResize(first_run_done,stotal,stotal);
      ArrayResize(BARS,stotal,stotal);

      //initialisation de tout le tableau à false car sinon la première valeur vaut true par défaut (bug?).
      for(int sindex=0; sindex<stotal; sindex++)
        {
         first_run_done[sindex]=false;
         BARS[sindex]=-1;
        }

      initdone=true;
     }

   int processingStart=GetTickCount();
   string output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" ("+EnumToString(Period())+")";
   output+=" Processing start = "+IntegerToString(processingStart);
   printf(output);

   for(int sindex=0; sindex<stotal; sindex++)
     {

      string sname=SymbolName(sindex,onlySymbolsInMarketwatch);

      if(sname==symbolToIgnore)
        {
         //printf(StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+"("+EnumToString(Period())+") : Ignoring = "+sname+" "+(sindex+1)+"/"+stotal);
         continue;
        }

      printf(StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+"("+EnumToString(Period())+") : Processing = "+sname+" "+(sindex+1)+"/"+stotal);

      MqlTick lasttick;
      double price;
      double sell;
      double buy;
      ulong vol;
      double spread;

      int handle;

      price= 0;
      sell = 0;
      buy=0;
      spread=0;
      vol=0;

      handle = iIchimoku(sname, PERIOD_M15, tenkan_sen, kijun_sen, senkou_span_b);
      if((handle!=INVALID_HANDLE) /*&& (handleH1!=INVALID_HANDLE) && (handleH4!=INVALID_HANDLE)*/)
        {
         int max=maxhisto;

         int nbt = CopyBuffer(handle, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
         int nbk = CopyBuffer(handle, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
         int nbssa = CopyBuffer(handle, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
         int nbssb = CopyBuffer(handle, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
         int nbc = CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

         MqlTick lasttick;
         SymbolInfoTick(sname,lasttick);
         price = lasttick.ask;
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
               FileWrite(file_handle,timestamp+";"+sname+";"+EnumToString(Period())+";"+DoubleToString(buy)+";"+DoubleToString(sell)+";"+DoubleToString(tenkan_sen_buffer[0])+";"+DoubleToString(kijun_sen_buffer[0])+";"+DoubleToString(chikou)+";"+DoubleToString(senkou_span_a_buffer[0])+";"+DoubleToString(senkou_span_b_buffer[0]));
               //sell affiché par défaut dans MT5
              }
           }

         // traitement détection bougies ici
         //printf("BARS="+Bars(sname,Period()));
         //printf("BARS[sindex]="+BARS[sindex]);
         if(
            BARS[sindex]!=Bars(sname,PERIOD_M15)
            //&& checkPeriod(PERIOD_M5)
            //&& checkPeriod(PERIOD_M1)
            )
           {
            if(BARS[sindex]==-1)
              {
               // premier test
               BARS[sindex]=Bars(sname,PERIOD_M15);
              }
            else
              {
               BARS[sindex]=Bars(sname,PERIOD_M15);

               // Ici est sur une nouvelle bougie !
               //printf("new candle for "+sname);
               //SendNotification("new candle for "+sname);

               if((chikou_span_buffer[26]>senkou_span_a_buffer[26])
                  && (chikou_span_buffer[26]>senkou_span_b_buffer[26])
                  && (chikou_span_buffer[26]>tenkan_sen_buffer[26])
                  && (chikou_span_buffer[26]>kijun_sen_buffer[26])
                  )
                 {

                  double open_array[];
                  ArraySetAsSeries(open_array,true);
                  int numO=CopyOpen(sname,PERIOD_M15,0,10,open_array);

                  double high_array[];
                  ArraySetAsSeries(high_array,true);
                  int numH=CopyHigh(sname,PERIOD_M15,0,10,high_array);

                  double low_array[];
                  ArraySetAsSeries(low_array,true);
                  int numL=CopyLow(sname,PERIOD_M15,0,10,low_array);

                  double close_array[];
                  ArraySetAsSeries(close_array,true);
                  int numC=CopyClose(sname,PERIOD_M15,0,10,close_array);

                  //Détection bougies qui passent au-dessus de SSA (avec SSA>SSB)
                  if(senkou_span_a_buffer[0]>senkou_span_b_buffer[0])
                    {

                     MqlDateTime mqd;
                     TimeCurrent(mqd);
                     string timestamp=string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');

                     if(
                        ((high_array[2]>senkou_span_a_buffer[2]) && (low_array[2]<senkou_span_a_buffer[2]))
                        && ((high_array[1]>senkou_span_a_buffer[1]) && (low_array[1]>senkou_span_a_buffer[1]))
                        )
                       {
                        string output=timestamp+"-"+sname+" ("+EnumToString(PERIOD_M15)+")"+" : ";
                        output+="n-2 crossed up SSA and n-1 over SSA";
                        output+=" ; buy="+ DoubleToString(buy) + " sell="+ DoubleToString(sell);
                        printf(output);
                        SendNotification(output);
                                                
                       }

                     if(
                        ((high_array[2]<senkou_span_a_buffer[2]) && (low_array[2]<senkou_span_a_buffer[2]))
                        && ((high_array[1]>senkou_span_a_buffer[1]) && (low_array[1]>senkou_span_a_buffer[1]))
                        )
                       {
                        string output=timestamp+"-"+sname+" ("+EnumToString(PERIOD_M15)+")"+" : ";
                        output+="n-2 under SSA and n-1 over SSA";
                        output+=" ; buy="+ DoubleToString(buy) + " sell="+ DoubleToString(sell);
                        printf(output);
                        SendNotification(output);          
                                     
                       }

                    }

                  //Détection bougies qui passent au-dessus de SSB (avec SSB>SSA)
                  if(senkou_span_b_buffer[0]>senkou_span_a_buffer[0])
                    {

                     MqlDateTime mqd;
                     TimeCurrent(mqd);
                     string timestamp=string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');

                     if(
                        ((high_array[2]>senkou_span_b_buffer[2]) && (low_array[2]<senkou_span_b_buffer[2]))
                        && ((high_array[1]>senkou_span_b_buffer[1]) && (low_array[1]>senkou_span_b_buffer[1]))
                        )
                       {
                        string output=timestamp+"-"+sname+" ("+EnumToString(PERIOD_M15)+")"+" : ";
                        output+="n-2 crossed up SSB and n-1 over SSB";
                        output+=" ; buy="+ DoubleToString(buy) + " sell="+ DoubleToString(sell);
                        printf(output);
                        SendNotification(output);    
                                                                  
                       }

                     if(
                        ((high_array[2]<senkou_span_b_buffer[2]) && (low_array[2]<senkou_span_b_buffer[2]))
                        && ((high_array[1]>senkou_span_b_buffer[1]) && (low_array[1]>senkou_span_b_buffer[1]))
                        )
                       {
                        string output=timestamp+"-"+sname+" ("+EnumToString(PERIOD_M15)+")"+" : ";
                        output+="n-2 under SSB and n-1 over SSB";
                        output+=" ; buy="+ DoubleToString(buy) + " sell="+ DoubleToString(sell);
                        printf(output);
                        SendNotification(output);

                       }

                    }

                  ArrayFree(open_array);
                  ArrayFree(close_array);
                  ArrayFree(high_array);
                  ArrayFree(low_array);

                 }
              }
           }

         //NOUVEAUX TRAITEMENTS SSB/KS
         if(first_run_done[sindex]==false)
           {
            first_run_done[sindex]=true;
           }
         else
           {
            //printf("first run already done");
           }

         //printf(sname + " : OK");

         ArrayFree(tenkan_sen_buffer);
         ArrayFree(kijun_sen_buffer);
         ArrayFree(senkou_span_a_buffer);
         ArrayFree(senkou_span_b_buffer);
         ArrayFree(chikou_span_buffer);

         IndicatorRelease(handle);
        }
      else
        {
         //printf(sname + " : ERROR : " + GetLastError());
        }

     } // fin boucle sur sindex (symbol index)

   int processingEnd=GetTickCount();
//printf("Processing end = " + IntegerToString(processingEnd));
   int processingDelta=processingEnd-processingStart;
   int seconds=processingDelta/1000;
   output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" ("+EnumToString(Period())+") : Total processing time = "+IntegerToString(processingDelta)+"ms = "+IntegerToString(seconds)+"s";
   output+= " Memory used = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE));
   output+= " Memory total = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_TOTAL));
   printf(output);
//SendNotification(output);

   // Si le déclenchement de cette fonction est fait depuis un OnTick, il est mieux d'avoir une temporisation ici
   // Si le déclenchement est fait depuis un OnTimer, pas nécessaire
   //Sleep(250);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkPeriod(ENUM_TIMEFRAMES period)
  {
   bool result=false;

   double open_array[];
   ArraySetAsSeries(open_array,true);
   int numO=CopyOpen(Symbol(),period,0,10,open_array);
//printf(sname + " : " + numO + " Open elements in array");
//printf(sname + " : Open element 1 = " + DoubleToString(open_array[1]));

   double high_array[];
   ArraySetAsSeries(high_array,true);
   int numH=CopyHigh(Symbol(),period,0,10,high_array);
//printf(sname + " : " + numH + " High elements in array");
//printf(sname + " : High element 1 = " + DoubleToString(high_array[1]));

   double low_array[];
   ArraySetAsSeries(low_array,true);
   int numL=CopyLow(Symbol(),period,0,10,low_array);
//printf(sname + " : " + numL + " Low elements in array");
//printf(sname + " : Low element 1 = " + DoubleToString(low_array[1]));

   double close_array[];
   ArraySetAsSeries(close_array,true);
   int numC=CopyClose(Symbol(),period,0,10,close_array);
//printf(sname + " : " + numC + " Close elements in array");
//printf(sname + " : Close element 1 = " + DoubleToString(close_array[1]));

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
   if((handle!=INVALID_HANDLE) /*&& (handleH1!=INVALID_HANDLE) && (handleH4!=INVALID_HANDLE)*/)
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
/*if(ArraySize(chikou_span_buffer)>26)
        {
         chikou=chikou_span_buffer[26];
        }*/

      if(
         //(tenkan_sen_buffer[0]>kijun_sen_buffer[0])
         (chikou_span_buffer[26]>senkou_span_a_buffer[26])
         && (chikou_span_buffer[26]>senkou_span_b_buffer[26])
         && (chikou_span_buffer[26]>tenkan_sen_buffer[26])
         && (chikou_span_buffer[26]>kijun_sen_buffer[26])
         //&& (high_array[1]>senkou_span_a_buffer[1])
         //&& (low_array[1]>senkou_span_a_buffer[1])
         //&& (high_array[1]>senkou_span_b_buffer[1])
         //&& (low_array[1]>senkou_span_b_buffer[1])
         && (high_array[1]>tenkan_sen_buffer[1])
         && (low_array[1]>tenkan_sen_buffer[1])
         && (high_array[1]>kijun_sen_buffer[1])
         && (low_array[1]>kijun_sen_buffer[1])
         )
        {
         // CS>SSA>SSB
         result=true;
        }

     }

//if(result==false) { printf("result H1 = false"); }

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
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
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

  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   double ret=0.0;
   return(ret);
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
  {
  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
  {
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//bool disableUploadHistory = false
void uploadHistory(string timestamp,string name,double buy,double sell)
  {
   if (disableUploadHistory == true) return;

// "https://ichimoku-ea.000webhostapp.com/ichimoku-ea-v2/?upload_history="
   string cookie=NULL,headers;
   char post[],result[];

   string history = timestamp + ";" + name + ";" + DoubleToString(buy) + ";" + DoubleToString(sell);

   string google_url="https://ichimoku-ea.000webhostapp.com/ichimoku-ea-v2/?upload_history="+history;
   int timeout=2500; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   int res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
   if(res==-1)
     {
      Print("WebRequest error code=",GetLastError() + " - " + name + " - " + timestamp);
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      //MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
      Sleep(250);
     }
   else
     {
      //printf("WebRequest ok =" + CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      //printf("History sent successfully");
     }     
  //disableUploadHistory = true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void upload2JCSAlert(string timestamp,string period,string symbol,double buy,double sell,string h1_ls_validated,string m1_ls_validated)
  {
// "https://ichimoku-ea.000webhostapp.com/ichimoku-ea-v2/?upload_2jcs_alert=test"
   string cookie=NULL,headers;
   char post[],result[];

   string jcsalert=timestamp+";"+period+";"+symbol+";"+DoubleToString(buy)+";"+DoubleToString(sell)+";"+h1_ls_validated+";"+m1_ls_validated;

   string google_url="https://ichimoku-ea.000webhostapp.com/ichimoku-ea-v2/?upload_2jcs_alert="+jcsalert;
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
      //printf(CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      printf("2JCS Alert sent successfully");
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
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
      //printf(CharArrayToString(result));
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
