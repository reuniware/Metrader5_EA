//+-----------------------------------------------------------------+
//|                                IchimokuUltimateTraderEA_2023.mq5|
//|                      Copyright 2023, InvestDataSystems@Yahoo.Com|
//|                            https://ichimoku-expert.blogspot.com |
//+-----------------------------------------------------------------+

//IchimokuUltimateTraderEA_2023.mq5
#property copyright "Copyright 2023, Investdata Systems France"
#property link      "https://ichimoku-expert.blogspot.com"
#property version   "1.02"

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

CAccountInfo accountInfo;
double initialEquity = 0;
double currentEquity = 0;

//input bool exportPrices=false;
int file_handle=INVALID_HANDLE; // File handle
input int scanPeriod=30;
input bool onlySymbolsInMarketwatch=true;
input string symbolToIgnoreIfContains="";
input bool runOnlyOnce=false;
input bool showProcessedSymbol=false;
input bool currentCurrencyOnly=false;

string appVersion="5.1";
string versionInfo="Scans in current timeframe ("+EnumToString(Period())+")";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0');

   string output="";
   output = timestamp + " Starting " + StringSubstr(__FILE__,0,StringLen(__FILE__)-4) + " " + appVersion + " Investdata Systems";
   output = output + " Version info : " + versionInfo;
   output = output + " https://ichimoku-expert.blogspot.com/";
   printf(output);
//SendNotification(output);

   ObjectsDeleteAll(0,"",-1,-1);

   if(runOnlyOnce)
     {
      EventSetTimer(1);
        } else {
      EventSetTimer(scanPeriod); // 30 secondes pour tout (pas seulement marketwatch)
     }

   initialEquity=accountInfo.Equity();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   EventKillTimer();

  }

ENUM_TIMEFRAMES workingPeriod=Period();
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//Ichimoku();
   return;
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
datetime allowed_until=D'2050.09.15 00:00';
bool expiration_notified=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool done=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {

   if(TimeCurrent()>allowed_until)
     {
      if(expiration_notified==false)
        {
         string output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" "+appVersion+" : EXPIRED. Please contact Investdata Systems (+33)787817434";
         printf(output);
         SendNotification(output);
         expiration_notified=true;
        }
      return;
     }

   if(runOnlyOnce)
     {
      printf("Running only once.");
      //if (done == false){
      Ichimoku();
      //done = true;
      EventKillTimer();
      //}
     }
   else
     {
      Ichimoku();
     }
  }

static int BARS;

bool first_run_done[];

static datetime LastBarTime[];//=-1;

int maxhisto=64;

bool initdone=false;
int stotal=0;
bool debug=false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double tenkan_sen_bufferD1[];
double kijun_sen_bufferD1[];
double senkou_span_a_bufferD1[];
double senkou_span_b_bufferD1[];
double chikou_span_bufferD1[];

double tenkan_sen_bufferH4[];
double kijun_sen_bufferH4[];
double senkou_span_a_bufferH4[];
double senkou_span_b_bufferH4[];
double chikou_span_bufferH4[];

double tenkan_sen_bufferH1[];
double kijun_sen_bufferH1[];
double senkou_span_a_bufferH1[];
double senkou_span_b_bufferH1[];
double chikou_span_bufferH1[];

double tenkan_sen_bufferM15[];
double kijun_sen_bufferM15[];
double senkou_span_a_bufferM15[];
double senkou_span_b_bufferM15[];
double chikou_span_bufferM15[];

double tenkan_sen_bufferM5[];
double kijun_sen_bufferM5[];
double senkou_span_a_bufferM5[];
double senkou_span_b_bufferM5[];
double chikou_span_bufferM5[];

double tenkan_sen_bufferM1[];
double kijun_sen_bufferM1[];
double senkou_span_a_bufferM1[];
double senkou_span_b_bufferM1[];
double chikou_span_bufferM1[];

double open_arrayD1[];
double high_arrayD1[];
double low_arrayD1[];
double close_arrayD1[];

double open_arrayH4[];
double high_arrayH4[];
double low_arrayH4[];
double close_arrayH4[];

double open_arrayH1[];
double high_arrayH1[];
double low_arrayH1[];
double close_arrayH1[];

double open_arrayM15[];
double high_arrayM15[];
double low_arrayM15[];
double close_arrayM15[];

double open_arrayM5[];
double high_arrayM5[];
double low_arrayM5[];
double close_arrayM5[];

double open_arrayM1[];
double high_arrayM1[];
double low_arrayM1[];
double close_arrayM1[];

double lowestLowForSymbol[]; // Plus basse perte durant une prise de position
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ichimoku()
  {
//upload2JCSAlert("a","a","a",0.0,0.0,"a","a");

   MqlDateTime dt_struct;
   TimeCurrent(dt_struct);

   int tenkan_sen = 9;              // period of Tenkan-sen
   int kijun_sen = 26;              // period of Kijun-sen
   int senkou_span_b = 52;          // period of Senkou Span B

//--- indicator buffer
   ArraySetAsSeries(tenkan_sen_bufferD1,true);
   ArraySetAsSeries(kijun_sen_bufferD1,true);
   ArraySetAsSeries(senkou_span_a_bufferD1,true);
   ArraySetAsSeries(senkou_span_b_bufferD1,true);
   ArraySetAsSeries(chikou_span_bufferD1,true);

   ArraySetAsSeries(tenkan_sen_bufferH4,true);
   ArraySetAsSeries(kijun_sen_bufferH4,true);
   ArraySetAsSeries(senkou_span_a_bufferH4,true);
   ArraySetAsSeries(senkou_span_b_bufferH4,true);
   ArraySetAsSeries(chikou_span_bufferH4,true);

   ArraySetAsSeries(tenkan_sen_bufferH1,true);
   ArraySetAsSeries(kijun_sen_bufferH1,true);
   ArraySetAsSeries(senkou_span_a_bufferH1,true);
   ArraySetAsSeries(senkou_span_b_bufferH1,true);
   ArraySetAsSeries(chikou_span_bufferH1,true);

   ArraySetAsSeries(tenkan_sen_bufferM15,true);
   ArraySetAsSeries(kijun_sen_bufferM15,true);
   ArraySetAsSeries(senkou_span_a_bufferM15,true);
   ArraySetAsSeries(senkou_span_b_bufferM15,true);
   ArraySetAsSeries(chikou_span_bufferM15,true);

   ArraySetAsSeries(tenkan_sen_bufferM5,true);
   ArraySetAsSeries(kijun_sen_bufferM5,true);
   ArraySetAsSeries(senkou_span_a_bufferM5,true);
   ArraySetAsSeries(senkou_span_b_bufferM5,true);
   ArraySetAsSeries(chikou_span_bufferM5,true);

   ArraySetAsSeries(tenkan_sen_bufferM1,true);
   ArraySetAsSeries(kijun_sen_bufferM1,true);
   ArraySetAsSeries(senkou_span_a_bufferM1,true);
   ArraySetAsSeries(senkou_span_b_bufferM1,true);
   ArraySetAsSeries(chikou_span_bufferM1,true);

   if(!initdone)
     {
      stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)
      if(currentCurrencyOnly)
        {
         stotal=1;
        }

      ArrayResize(first_run_done,stotal,stotal);
      ArrayResize(LastBarTime,stotal,stotal);

      //initialisation de tout le tableau à false car sinon la première valeur vaut true par défaut (bug?).
      for(int sindex=0; sindex<stotal; sindex++)
        {
         first_run_done[sindex]=false;
         LastBarTime[sindex]=-1;
        }

      //initialisation de tous les plus bas à 0
      ArrayResize(lowestLowForSymbol,stotal,stotal);
      for(int sindex=0; sindex<stotal; sindex++)
        {
         lowestLowForSymbol[sindex]=0;
        }

      initdone=true;
     }

   int processingStart=GetTickCount();
   string output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" ("+EnumToString(Period())+")";
   output+=" Processing start = "+IntegerToString(processingStart);
   //printf(output);

   for(int sindex=0; sindex<stotal; sindex++)
     {
      bool ok=false;

      string sname=SymbolName(sindex,onlySymbolsInMarketwatch);
      if(currentCurrencyOnly)
        {
         sname=Symbol();
        }

      if(symbolToIgnoreIfContains!="")
        {
         if(StringFind(sname,symbolToIgnoreIfContains)!=-1)
           {
            printf("Ignoring : "+sname);
            continue;
           }
        }

      datetime ThisBarTime=(datetime)SeriesInfoInteger(sname,workingPeriod,SERIES_LASTBAR_DATE);
      if(ThisBarTime==LastBarTime[sindex])
        {
         //printf("Same bar time (" + sname + ")");
        }
      else
        {
         if(LastBarTime[sindex]==-1)
           {
            //printf("First bar (" + sname + ")");
            LastBarTime[sindex]=ThisBarTime;
           }
         else
           {
            //printf("New bar time (" + sname + ")");
            LastBarTime[sindex]=ThisBarTime;
            ok=true;
           }
        }

      if(ok!=true)
        {
         continue;
        }

      //printf("Processing " + sname);

      // Ici est sur une nouvelle bougie !
      int handleD1;
      //handleD1=iIchimoku(sname,PERIOD_D1,tenkan_sen,kijun_sen,senkou_span_b);
      int handleH4;
      handleH4=iIchimoku(sname,PERIOD_H4,tenkan_sen,kijun_sen,senkou_span_b);
      int handleH1;
      handleH1=iIchimoku(sname,PERIOD_H1,tenkan_sen,kijun_sen,senkou_span_b);
      int handleM15;
      handleM15=iIchimoku(sname,PERIOD_M15,tenkan_sen,kijun_sen,senkou_span_b);
      int handleM5;
      handleM5=iIchimoku(sname,PERIOD_M5,tenkan_sen,kijun_sen,senkou_span_b);
      int handleM1;
      handleM1=iIchimoku(sname,PERIOD_M1,tenkan_sen,kijun_sen,senkou_span_b);
      if(handleH4!=INVALID_HANDLE && handleH1!=INVALID_HANDLE && handleM15!=INVALID_HANDLE && handleM5!=INVALID_HANDLE && handleM1!=INVALID_HANDLE)
        {
         int max=maxhisto;

         int nbt=-1,nbk=-1,nbssa=-1,nbssb=-1,nbc=-1;

/*nbt = CopyBuffer(handleD1, TENKANSEN_LINE, 0, max, tenkan_sen_bufferD1);
         nbk = CopyBuffer(handleD1, KIJUNSEN_LINE, 0, max, kijun_sen_bufferD1);
         nbssa = CopyBuffer(handleD1, SENKOUSPANA_LINE, 0, max, senkou_span_a_bufferD1);
         nbssb = CopyBuffer(handleD1, SENKOUSPANB_LINE, 0, max, senkou_span_b_bufferD1);
         nbc=CopyBuffer(handleD1,CHIKOUSPAN_LINE,0,max,chikou_span_bufferD1);*/

         nbt = CopyBuffer(handleH4, TENKANSEN_LINE, 0, max, tenkan_sen_bufferH4);
         nbk = CopyBuffer(handleH4, KIJUNSEN_LINE, 0, max, kijun_sen_bufferH4);
         nbssa = CopyBuffer(handleH4, SENKOUSPANA_LINE, 0, max, senkou_span_a_bufferH4);
         nbssb = CopyBuffer(handleH4, SENKOUSPANB_LINE, 0, max, senkou_span_b_bufferH4);
         nbc=CopyBuffer(handleH4,CHIKOUSPAN_LINE,0,max,chikou_span_bufferH4);

         nbt = CopyBuffer(handleH1, TENKANSEN_LINE, 0, max, tenkan_sen_bufferH1);
         nbk = CopyBuffer(handleH1, KIJUNSEN_LINE, 0, max, kijun_sen_bufferH1);
         nbssa = CopyBuffer(handleH1, SENKOUSPANA_LINE, 0, max, senkou_span_a_bufferH1);
         nbssb = CopyBuffer(handleH1, SENKOUSPANB_LINE, 0, max, senkou_span_b_bufferH1);
         nbc=CopyBuffer(handleH1,CHIKOUSPAN_LINE,0,max,chikou_span_bufferH1);

         nbt = CopyBuffer(handleM15, TENKANSEN_LINE, 0, max, tenkan_sen_bufferM15);
         nbk = CopyBuffer(handleM15, KIJUNSEN_LINE, 0, max, kijun_sen_bufferM15);
         nbssa = CopyBuffer(handleM15, SENKOUSPANA_LINE, 0, max, senkou_span_a_bufferM15);
         nbssb = CopyBuffer(handleM15, SENKOUSPANB_LINE, 0, max, senkou_span_b_bufferM15);
         nbc=CopyBuffer(handleM15,CHIKOUSPAN_LINE,0,max,chikou_span_bufferM15);

         nbt = CopyBuffer(handleM5, TENKANSEN_LINE, 0, max, tenkan_sen_bufferM5);
         nbk = CopyBuffer(handleM5, KIJUNSEN_LINE, 0, max, kijun_sen_bufferM5);
         nbssa = CopyBuffer(handleM5, SENKOUSPANA_LINE, 0, max, senkou_span_a_bufferM5);
         nbssb = CopyBuffer(handleM5, SENKOUSPANB_LINE, 0, max, senkou_span_b_bufferM5);
         nbc=CopyBuffer(handleM5,CHIKOUSPAN_LINE,0,max,chikou_span_bufferM5);

         nbt = CopyBuffer(handleM1, TENKANSEN_LINE, 0, max, tenkan_sen_bufferM1);
         nbk = CopyBuffer(handleM1, KIJUNSEN_LINE, 0, max, kijun_sen_bufferM1);
         nbssa = CopyBuffer(handleM1, SENKOUSPANA_LINE, 0, max, senkou_span_a_bufferM1);
         nbssb = CopyBuffer(handleM1, SENKOUSPANB_LINE, 0, max, senkou_span_b_bufferM1);
         nbc=CopyBuffer(handleM1,CHIKOUSPAN_LINE,0,max,chikou_span_bufferM1);

         //string timestamp=getTimeStamp();

         int numO=-1,numH=-1,numL=-1,numC=-1;

         //ArraySetAsSeries(open_arrayD1,true);
         //numO=CopyOpen(sname,PERIOD_D1,0,32,open_arrayD1);

         //ArraySetAsSeries(high_arrayD1,true);
         //numH=CopyHigh(sname,PERIOD_D1,0,32,high_arrayD1);

         //ArraySetAsSeries(low_arrayD1,true);
         //numL=CopyLow(sname,PERIOD_D1,0,32,low_arrayD1);

         //ArraySetAsSeries(close_arrayD1,true);
         //numC=CopyClose(sname,PERIOD_D1,0,32,close_arrayD1);

         ArraySetAsSeries(open_arrayH4,true);
         numO=CopyOpen(sname,PERIOD_H4,0,32,open_arrayH4);

         ArraySetAsSeries(high_arrayH4,true);
         numH=CopyHigh(sname,PERIOD_H4,0,32,high_arrayH4);

         ArraySetAsSeries(low_arrayH4,true);
         numL=CopyLow(sname,PERIOD_H4,0,32,low_arrayH4);

         ArraySetAsSeries(close_arrayH4,true);
         numC=CopyClose(sname,PERIOD_H4,0,32,close_arrayH4);

         ArraySetAsSeries(open_arrayH1,true);
         numO=CopyOpen(sname,PERIOD_H1,0,32,open_arrayH1);

         ArraySetAsSeries(high_arrayH1,true);
         numH=CopyHigh(sname,PERIOD_H1,0,32,high_arrayH1);

         ArraySetAsSeries(low_arrayH1,true);
         numL=CopyLow(sname,PERIOD_H1,0,32,low_arrayH1);

         ArraySetAsSeries(close_arrayH1,true);
         numC=CopyClose(sname,PERIOD_H1,0,32,close_arrayH1);

         ArraySetAsSeries(open_arrayM15,true);
         numO=CopyOpen(sname,PERIOD_M15,0,32,open_arrayM15);

         ArraySetAsSeries(high_arrayM15,true);
         numH=CopyHigh(sname,PERIOD_M15,0,32,high_arrayM15);

         ArraySetAsSeries(low_arrayM15,true);
         numL=CopyLow(sname,PERIOD_M15,0,32,low_arrayM15);

         ArraySetAsSeries(close_arrayM15,true);
         numC=CopyClose(sname,PERIOD_M15,0,32,close_arrayM15);

         ArraySetAsSeries(open_arrayM5,true);
         numO=CopyOpen(sname,PERIOD_M5,0,32,open_arrayM5);

         ArraySetAsSeries(high_arrayM5,true);
         numH=CopyHigh(sname,PERIOD_M5,0,32,high_arrayM5);

         ArraySetAsSeries(low_arrayM5,true);
         numL=CopyLow(sname,PERIOD_M5,0,32,low_arrayM5);

         ArraySetAsSeries(close_arrayM5,true);
         numC=CopyClose(sname,PERIOD_M5,0,32,close_arrayM5);

         ArraySetAsSeries(open_arrayM1,true);
         numO=CopyOpen(sname,PERIOD_M1,0,32,open_arrayM1);

         ArraySetAsSeries(high_arrayM1,true);
         numH=CopyHigh(sname,PERIOD_M1,0,32,high_arrayM1);

         ArraySetAsSeries(low_arrayM1,true);
         numL=CopyLow(sname,PERIOD_M1,0,32,low_arrayM1);

         ArraySetAsSeries(close_arrayM1,true);
         numC=CopyClose(sname,PERIOD_M1,0,32,close_arrayM1);

         if(showProcessedSymbol) printf(sname+" : processing");

         detectPreviousCandlestickHasCrossedOverKumoUpM15(sname);
         detectPreviousCandlestickIsOverKumoM15(sname);

         //detectPreviousCandlestickHasCrossedOverKumoUpM1(sname);

         //}
         //}

         ArrayFree(open_arrayD1);
         ArrayFree(close_arrayD1);
         ArrayFree(high_arrayD1);
         ArrayFree(low_arrayD1);

         ArrayFree(open_arrayH4);
         ArrayFree(close_arrayH4);
         ArrayFree(high_arrayH4);
         ArrayFree(low_arrayH4);

         ArrayFree(open_arrayH1);
         ArrayFree(close_arrayH1);
         ArrayFree(high_arrayH1);
         ArrayFree(low_arrayH1);

         ArrayFree(open_arrayM15);
         ArrayFree(close_arrayM15);
         ArrayFree(high_arrayM15);
         ArrayFree(low_arrayM15);

         ArrayFree(open_arrayM5);
         ArrayFree(close_arrayM5);
         ArrayFree(high_arrayM5);
         ArrayFree(low_arrayM5);

         ArrayFree(open_arrayM1);
         ArrayFree(close_arrayM1);
         ArrayFree(high_arrayM1);
         ArrayFree(low_arrayM1);

         //}
         //}

         //printf(sname + " : OK");

         ArrayFree(tenkan_sen_bufferD1);
         ArrayFree(kijun_sen_bufferD1);
         ArrayFree(senkou_span_a_bufferD1);
         ArrayFree(senkou_span_b_bufferD1);
         ArrayFree(chikou_span_bufferD1);

         ArrayFree(tenkan_sen_bufferH4);
         ArrayFree(kijun_sen_bufferH4);
         ArrayFree(senkou_span_a_bufferH4);
         ArrayFree(senkou_span_b_bufferH4);
         ArrayFree(chikou_span_bufferH4);

         ArrayFree(tenkan_sen_bufferH1);
         ArrayFree(kijun_sen_bufferH1);
         ArrayFree(senkou_span_a_bufferH1);
         ArrayFree(senkou_span_b_bufferH1);
         ArrayFree(chikou_span_bufferH1);

         ArrayFree(tenkan_sen_bufferM15);
         ArrayFree(kijun_sen_bufferM15);
         ArrayFree(senkou_span_a_bufferM15);
         ArrayFree(senkou_span_b_bufferM15);
         ArrayFree(chikou_span_bufferM15);

         ArrayFree(tenkan_sen_bufferM5);
         ArrayFree(kijun_sen_bufferM5);
         ArrayFree(senkou_span_a_bufferM5);
         ArrayFree(senkou_span_b_bufferM5);
         ArrayFree(chikou_span_bufferM5);

         ArrayFree(tenkan_sen_bufferM1);
         ArrayFree(kijun_sen_bufferM1);
         ArrayFree(senkou_span_a_bufferM1);
         ArrayFree(senkou_span_b_bufferM1);
         ArrayFree(chikou_span_bufferM1);

         IndicatorRelease(handleD1);
         IndicatorRelease(handleH4);
         IndicatorRelease(handleH1);
         IndicatorRelease(handleM15);
         IndicatorRelease(handleM5);
         IndicatorRelease(handleM1);

        }
      else
        {
         printf(sname + " : ERROR : " + GetLastError());

        }
     }//fin boucle sur sindex

   int processingEnd=GetTickCount();
   //printf("Processing end = "+IntegerToString(processingEnd));
   int processingDelta=processingEnd-processingStart;
   if(processingDelta>0)
     {
      int seconds=processingDelta/1000;
      output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" ("+EnumToString(Period())+") : Total processing time = "+IntegerToString(processingDelta)+"ms = "+IntegerToString(seconds)+"s";
      output+= " Memory used = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE));
      output+= " Memory total = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_TOTAL));
      //printf(output);
      //SendNotification(output);
     }

// Si le déclenchement de cette fonction est fait depuis un OnTick, il est mieux d'avoir une temporisation ici
// Si le déclenchement est fait depuis un OnTimer, pas nécessaire
//Sleep(15000);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void detectPreviousCandlestickHasCrossedOverKumoUpM15(string sname)
  {
   bool h4andh1overkumo=previousCandlestickIsOverKumoH1() && previousCandlestickIsOverKumoH4();
   bool h1overkumo=previousCandlestickIsOverKumoH1();

   int m15validation=0;

   if(previousCandlestickHasCrossedOverKumoUpM15())
     {
      string msg= "";
      string tf = "";
      if(h4andh1overkumo){ tf="H4+H1+M15"; msg="*** JCS(H4(-1)) > KUMO(H4(-1)) and JCS(H1(-1)) > KUMO(H1(-1)) and JCS(M15(-1)) has crossed KUMO(M15(-1)) while up ***"; }
      else if(h1overkumo) { tf="H1+M15"; msg="** JCS(H1(-1)) > KUMO(H1(-1)) and JCS(M15(-1)) has crossed KUMO(M15(-1)) while up **"; }
      else { tf="M15"; msg="* JCS(M15(-1)) has crossed KUMO(M15(-1)) while up *"; }
      //printf(sname+":"+msg);
      //SendNotification(sname+":"+msg);
      upload2JCSAlert(getTimestamp(),tf,sname,getAskPriceForSymbol(sname),getBidPriceForSymbol(sname),msg,"");

      if(senkou_span_a_bufferM15[1]>senkou_span_b_bufferM15[1])
        {
         string msg="(1/8) OK : SSA(M15(-1)) > SSB(M15(-1))";
         m15validation++;
        }
      else
        {
         string msg="(1/8) KO : SSA(M15(-1)) > SSB(M15(-1))";
        }

      if((open_arrayM15[0]>senkou_span_a_bufferM15[0]) && (open_arrayM15[0]>senkou_span_b_bufferM15[0]))
        {
         string msg="(2/8) OK : JCS(M15(OPEN(0)) > KUMO(M15(0))";
         m15validation++;
        }
      else
        {
         string msg="(2/8) KO : JCS(M15(OPEN(0)) > KUMO(M15(0))";
        }

      if(open_arrayM15[0]>kijun_sen_bufferM15[0])
        {
         string msg="(3/8) OK : JCS(M15(OPEN(0)) > KIJUN(M15(0))";
         m15validation++;
        }
      else
        {
         string msg="(3/8) KO : JCS(M15(OPEN(0)) > KIJUN(M15(0))";
        }

      if(open_arrayM15[0]>tenkan_sen_bufferM15[0])
        {
         string msg="(4/8) OK : JCS(M15(OPEN(0)) > TENKAN(M15(0))";
         m15validation++;
        }
      else
        {
         string msg="(4/8) KO : JCS(M15(OPEN(0)) > TENKAN(M15(0))";
        }

      if((chikou_span_bufferM15[26]>senkou_span_a_bufferM15[26]) && (chikou_span_bufferM15[26]>senkou_span_b_bufferM15[26]))
        {
         string msg="(5/8) OK : CHIKOU(M15(-26)) > KUMO(M15(-26))";
         m15validation++;
        }
      else
        {
         string msg="(5/8) KO : CHIKOU(M15(-26)) > KUMO(M15(-26))";
        }

      if(chikou_span_bufferM15[26]>kijun_sen_bufferM15[26])
        {
         string msg="(6/8) OK : CHIKOU(M15(-26)) > KIJUN(M15(-26))";
         m15validation++;
        }
      else
        {
         string msg="(6/8) KO : CHIKOU(M15(-26)) > KIJUN(M15(-26))";
        }

      if(chikou_span_bufferM15[26]>tenkan_sen_bufferM15[26])
        {
         string msg="(7/8) OK : CHIKOU(M15(-26)) > TENKAN(M15(-26))";
         m15validation++;
        }
      else
        {
         string msg="(7/8) KO : CHIKOU(M15(-26)) > TENKAN(M15(-26))";
        }

      if(chikou_span_bufferM15[26]>high_arrayM15[26])
        {
         string msg="(8/8) OK : CHIKOU(M15(-26)) > HIGH(M15(-26))";
         m15validation++;
        }
      else
        {
         string msg="(8/8) KO : CHIKOU(M15(-26)) > HIGH(M15(-26))";
        }

      msg="Validation (max=8) = "+m15validation;

      if(m15validation==8)
        {
         msg="All 8 validations are ok, with JCS(M15(-1)) crossing Kumo while up";
         printf(sname+":"+msg);
         SendNotification(sname+":"+msg);
         upload2JCSAlert(getTimestamp(),tf,sname,getAskPriceForSymbol(sname),getBidPriceForSymbol(sname),msg,"");

         if (  open_arrayM5[1]>senkou_span_a_bufferM5[1] && open_arrayM5[1]>senkou_span_b_bufferM5[1]
               && close_arrayM5[1]>senkou_span_a_bufferM5[1] && close_arrayM5[1]>senkou_span_b_bufferM5[1]
               && open_arrayM5[1]>kijun_sen_bufferM5[1] && close_arrayM5[1]>kijun_sen_bufferM5[1]
               && close_arrayM5[1]>senkou_span_a_bufferM5[1] && close_arrayM5[1]>senkou_span_b_bufferM5[1]               
               && chikou_span_bufferM5[26]>senkou_span_a_bufferM5[26] && chikou_span_bufferM5[26]>senkou_span_b_bufferM5[26]
               && chikou_span_bufferM5[26]>kijun_sen_bufferM5[26] && chikou_span_bufferM5[26]>kijun_sen_bufferM5[26]         
            ){
               msg="And JCS(M5(-1))>KUMO(M5(-1)) And CS(M5(-26))>KUMO(M5(-26)) And CS(M5(-26))>KS(M5(-26))";
               printf(sname+":"+msg);
               SendNotification(sname+":"+msg);
               upload2JCSAlert(getTimestamp(),tf,sname,getAskPriceForSymbol(sname),getBidPriceForSymbol(sname),msg,"");
            }
         
         if (  open_arrayM1[1]>senkou_span_a_bufferM1[1] && open_arrayM1[1]>senkou_span_b_bufferM1[1]
               && close_arrayM1[1]>senkou_span_a_bufferM1[1] && close_arrayM1[1]>senkou_span_b_bufferM1[1]
               && open_arrayM1[1]>kijun_sen_bufferM1[1] && close_arrayM1[1]>kijun_sen_bufferM1[1]
               && close_arrayM1[1]>senkou_span_a_bufferM1[1] && close_arrayM1[1]>senkou_span_b_bufferM1[1]               
               && chikou_span_bufferM1[26]>senkou_span_a_bufferM1[26] && chikou_span_bufferM1[26]>senkou_span_b_bufferM1[26]
               && chikou_span_bufferM1[26]>kijun_sen_bufferM1[26] && chikou_span_bufferM1[26]>kijun_sen_bufferM1[26]         
            ){
               msg="And JCS(M1(-1))>KUMO(M1(-1)) And CS(M1(-26))>KUMO(M1(-26)) And CS(M1(-26))>KS(M1(-26))";
               printf(sname+":"+msg);
               SendNotification(sname+":"+msg);
               upload2JCSAlert(getTimestamp(),tf,sname,getAskPriceForSymbol(sname),getBidPriceForSymbol(sname),msg,"");            
            }
        }

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void detectPreviousCandlestickHasCrossedOverKumoUpM1(string sname)
  {
   int m1validation=0;

   if(previousCandlestickHasCrossedOverKumoUpM1())
     {
      string msg= "";
      string tf = "";

      if(senkou_span_a_bufferM1[1]>senkou_span_b_bufferM1[1])
        {
         string msg="(1/8) OK : SSA(M1(-1)) > SSB(M1(-1))";
         m1validation++;
        }
      else
        {
         string msg="(1/8) KO : SSA(M1(-1)) > SSB(M1(-1))";
        }

      if((open_arrayM1[0]>senkou_span_a_bufferM1[0]) && (open_arrayM1[0]>senkou_span_b_bufferM1[0]))
        {
         string msg="(2/8) OK : JCS(M1(OPEN(0)) > KUMO(M1(0))";
         m1validation++;
        }
      else
        {
         string msg="(2/8) KO : JCS(M15(OPEN(0)) > KUMO(M15(0))";
        }

      if(open_arrayM1[0]>kijun_sen_bufferM1[0])
        {
         string msg="(3/8) OK : JCS(M1(OPEN(0)) > KIJUN(M1(0))";
         m1validation++;
        }
      else
        {
         string msg="(3/8) KO : JCS(M1(OPEN(0)) > KIJUN(M1(0))";
        }

      if(open_arrayM1[0]>tenkan_sen_bufferM1[0])
        {
         string msg="(4/8) OK : JCS(M1(OPEN(0)) > TENKAN(M1(0))";
         m1validation++;
        }
      else
        {
         string msg="(4/8) KO : JCS(M1(OPEN(0)) > TENKAN(M1(0))";
        }

      if((chikou_span_bufferM1[26]>senkou_span_a_bufferM1[26]) && (chikou_span_bufferM1[26]>senkou_span_b_bufferM1[26]))
        {
         string msg="(5/8) OK : CHIKOU(M1(-26)) > KUMO(M1(-26))";
         m1validation++;
        }
      else
        {
         string msg="(5/8) KO : CHIKOU(M1(-26)) > KUMO(M1(-26))";
        }

      if(chikou_span_bufferM1[26]>kijun_sen_bufferM1[26])
        {
         string msg="(6/8) OK : CHIKOU(M1(-26)) > KIJUN(M1(-26))";
         m1validation++;
        }
      else
        {
         string msg="(6/8) KO : CHIKOU(M1(-26)) > KIJUN(M1(-26))";
        }

      if(chikou_span_bufferM1[26]>tenkan_sen_bufferM1[26])
        {
         string msg="(7/8) OK : CHIKOU(M1(-26)) > TENKAN(M1(-26))";
         m1validation++;
        }
      else
        {
         string msg="(7/8) KO : CHIKOU(M1(-26)) > TENKAN(M1(-26))";
        }

      if(chikou_span_bufferM1[26]>high_arrayM1[26])
        {
         string msg="(8/8) OK : CHIKOU(M1(-26)) > HIGH(M1(-26))";
         m1validation++;
        }
      else
        {
         string msg="(8/8) KO : CHIKOU(M1(-26)) > HIGH(M1(-26))";
        }

      msg="Validation (max=8) = "+m1validation;

      if(m1validation==8)
        {
         msg="All 8 validations are ok, with JCS(M1(-1)) crossing Kumo while up";
         //printf(sname+":"+msg);
         //SendNotification(sname+":"+msg);
         tf = "M1";
         //upload2JCSAlert(getTimestamp(),tf,sname,getAskPriceForSymbol(sname),getBidPriceForSymbol(sname),msg,"EXPERIMENTAL");
        }

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void detectPreviousCandlestickIsOverKumoM15(string sname)
  {
   bool h4andh1overkumo=previousCandlestickIsOverKumoH1() && previousCandlestickIsOverKumoH4();
   bool h1overkumo=previousCandlestickIsOverKumoH1();

   int m15validation=0;

   if(previousCandlestickIsOverKumoM15())
     {
      string msg= "";
      string tf = "";
      if(h4andh1overkumo){ tf="H4+H1+M15"; msg="*** JCS(H4(-1)) > KUMO(H4(-1)) and JCS(H1(-1)) > KUMO(H1(-1)) and JCS(M15(-1)) > KUMO(M15(-1)) ***"; }
      else if(h1overkumo) { tf="H1+M15"; msg="** JCS(H1(-1)) > KUMO(H1(-1)) and JCS(M15(-1)) > KUMO(M15(-1)) **"; }
      else { tf="M15"; msg="* JCS(M15(-1)) > KUMO(M15(-1)) *"; }
      //printf(sname+":"+msg);
      //SendNotification(sname+":"+msg);
      upload2JCSAlert(getTimestamp(),tf,sname,getAskPriceForSymbol(sname),getBidPriceForSymbol(sname),msg,"");

      if(senkou_span_a_bufferM15[1]>senkou_span_b_bufferM15[1])
        {
         string msg="(1/8) OK : SSA(M15(-1)) > SSB(M15(-1))";
         m15validation++;
        }
      else
        {
         string msg="(1/8) KO : SSA(M15(-1)) > SSB(M15(-1))";
        }

      if((open_arrayM15[0]>senkou_span_a_bufferM15[0]) && (open_arrayM15[0]>senkou_span_b_bufferM15[0]))
        {
         string msg="(2/8) OK : JCS(M15(OPEN(0)) > KUMO(M15(0))";
         m15validation++;
        }
      else
        {
         string msg="(2/8) KO : JCS(M15(OPEN(0)) > KUMO(M15(0))";
        }

      if(open_arrayM15[0]>kijun_sen_bufferM15[0])
        {
         string msg="(3/8) OK : JCS(M15(OPEN(0)) > KIJUN(M15(0))";
         m15validation++;
        }
      else
        {
         string msg="(3/8) KO : JCS(M15(OPEN(0)) > KIJUN(M15(0))";
        }

      if(open_arrayM15[0]>tenkan_sen_bufferM15[0])
        {
         string msg="(4/8) OK : JCS(M15(OPEN(0)) > TENKAN(M15(0))";
         m15validation++;
        }
      else
        {
         string msg="(4/8) KO : JCS(M15(OPEN(0)) > TENKAN(M15(0))";
        }

      if((chikou_span_bufferM15[26]>senkou_span_a_bufferM15[26]) && (chikou_span_bufferM15[26]>senkou_span_b_bufferM15[26]))
        {
         string msg="(5/8) OK : CHIKOU(M15(-26)) > KUMO(M15(-26))";
         m15validation++;
        }
      else
        {
         string msg="(5/8) KO : CHIKOU(M15(-26)) > KUMO(M15(-26))";
        }

      if(chikou_span_bufferM15[26]>kijun_sen_bufferM15[26])
        {
         string msg="(6/8) OK : CHIKOU(M15(-26)) > KIJUN(M15(-26))";
         m15validation++;
        }
      else
        {
         string msg="(6/8) KO : CHIKOU(M15(-26)) > KIJUN(M15(-26))";
        }

      if(chikou_span_bufferM15[26]>tenkan_sen_bufferM15[26])
        {
         string msg="(7/8) OK : CHIKOU(M15(-26)) > TENKAN(M15(-26))";
         m15validation++;
        }
      else
        {
         string msg="(7/8) KO : CHIKOU(M15(-26)) > TENKAN(M15(-26))";
        }

      if(chikou_span_bufferM15[26]>high_arrayM15[26])
        {
         string msg="(8/8) OK : CHIKOU(M15(-26)) > HIGH(M15(-26))";
         m15validation++;
        }
      else
        {
         string msg="(8/8) KO : CHIKOU(M15(-26)) > HIGH(M15(-26))";
        }

      msg="Validation (max=8) = "+m15validation;

      if(m15validation==8)
        {
         msg="All 8 validations are ok, with JCS(M15(-1)) > Kumo";
         //printf(sname+":"+msg);
         //SendNotification(sname+":"+msg);
         upload2JCSAlert(getTimestamp(),tf,sname,getAskPriceForSymbol(sname),getBidPriceForSymbol(sname),msg,"");
        }

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickHasCrossedOverKumoUpM15()
  {
   if(senkou_span_a_bufferM15[1]>senkou_span_b_bufferM15[1])
     {
      if(open_arrayM15[1]<senkou_span_a_bufferM15[1] && close_arrayM15[1]>senkou_span_a_bufferM15[1])
        {
         return true;
        }
     }

   if(senkou_span_b_bufferM15[1]>senkou_span_a_bufferM15[1])
     {
      if(open_arrayM15[1]<senkou_span_b_bufferM15[1] && close_arrayM15[1]>senkou_span_b_bufferM15[1])
        {
         return true;
        }
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickHasCrossedOverKumoUpM1()
  {
   if(senkou_span_a_bufferM1[1]>senkou_span_b_bufferM1[1])
     {
      if(open_arrayM1[1]<senkou_span_a_bufferM1[1] && close_arrayM1[1]>senkou_span_a_bufferM1[1])
        {
         return true;
        }
     }

   if(senkou_span_b_bufferM1[1]>senkou_span_a_bufferM1[1])
     {
      if(open_arrayM1[1]<senkou_span_b_bufferM1[1] && close_arrayM1[1]>senkou_span_b_bufferM1[1])
        {
         return true;
        }
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool currentCandlestickHasStartedOverKijunUpM5()
  {
   if(
      // ouverture bougie M5 actuelle > ks
      // et cours actuel (de fermeture donc, mais bougie non terminée) > ks
      // et cours actuel bougie > cours ouverture bougie
      open_arrayM5[0]>kijun_sen_bufferM5[0]
      && close_arrayM5[0]>kijun_sen_bufferM5[0]
      && close_arrayM5[0]>open_arrayM5[0]
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool currentCandlestickHasStartedOverKijunUpM15()
  {
   if(
      // ouverture bougie M15 actuelle > ks
      // et cours actuel (de fermeture donc, mais bougie non terminée) > ks
      // et cours actuel bougie > cours ouverture bougie
      open_arrayM15[0]>kijun_sen_bufferM15[0]
      && close_arrayM15[0]>kijun_sen_bufferM15[0]
      && close_arrayM15[0]>open_arrayM15[0]
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickHasCrossedOverKijunUpM5()
  {
   if(
      // bougie M5 n-1 > ks
      open_arrayM5[1]<kijun_sen_bufferM5[1]
      && close_arrayM5[1]>kijun_sen_bufferM5[1]
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickHasCrossedOverKijunUpM15()
  {
   if(
      // bougie M15 n-1 > ks
      open_arrayM15[1]<kijun_sen_bufferM15[1]
      && close_arrayM15[1]>kijun_sen_bufferM15[1]
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickIsFreeUpM15()
  {
   if(
      // bougie M15 n-1 > ks+ssa+ssb+ts
      open_arrayM15[1]>kijun_sen_bufferM15[1]
      && close_arrayM15[1]>kijun_sen_bufferM15[1]
      && open_arrayM15[1]>senkou_span_a_bufferM15[1]
      && close_arrayM15[1]>senkou_span_b_bufferM15[1]
      && open_arrayM15[1]>tenkan_sen_bufferM15[1]
      && close_arrayM15[1]>tenkan_sen_bufferM15[1]

      // bougie M15 en cours > ks+ts+ssa+ssb
      && open_arrayM15[0]>kijun_sen_bufferM15[0]
      && close_arrayM15[0]>kijun_sen_bufferM15[0]
      && open_arrayM15[0]>tenkan_sen_bufferM15[0]
      && close_arrayM15[0]>tenkan_sen_bufferM15[0]
      && open_arrayM15[0]>senkou_span_a_bufferM15[0]
      && close_arrayM15[0]>senkou_span_b_bufferM15[0]

      // bougie M5 n-1 > ks+ts+ssa+ssb
      && open_arrayM5[1]>kijun_sen_bufferM5[1]
      && close_arrayM5[1]>kijun_sen_bufferM5[1]
      && open_arrayM5[1]>tenkan_sen_bufferM5[1]
      && close_arrayM5[1]>tenkan_sen_bufferM5[1]
      && open_arrayM5[1]>senkou_span_a_bufferM5[1]
      && close_arrayM5[1]>senkou_span_b_bufferM5[1]

      // bougie M5 en cours > ks+ts+ssa+ssb
      && open_arrayM5[0]>kijun_sen_bufferM5[0]
      && close_arrayM5[0]>kijun_sen_bufferM5[0]
      && open_arrayM5[0]>tenkan_sen_bufferM5[0]
      && close_arrayM5[0]>tenkan_sen_bufferM5[0]
      && open_arrayM5[0]>senkou_span_a_bufferM5[0]
      && close_arrayM5[0]>senkou_span_b_bufferM5[0]

      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool laggingSpanIsFreeUpM15()
  {
   if(
      (chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])
      && (chikou_span_bufferM15[26]>senkou_span_b_bufferM5[26])
      && (chikou_span_bufferM15[26]>tenkan_sen_bufferM15[26])
      && (chikou_span_bufferM15[26]>kijun_sen_bufferM15[26])
      && (chikou_span_bufferM15[26]>close_arrayM15[26])
      && (chikou_span_bufferM15[26]>open_arrayM15[26])
      && (chikou_span_bufferM15[26]>close_arrayM15[26])
      && (chikou_span_bufferM15[26]>high_arrayM15[26])
      && (chikou_span_bufferM15[26]>low_arrayM15[26])
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickIsOverKumoM1()
  {
   if(
      (
      (senkou_span_a_bufferM1[1]>senkou_span_b_bufferM1[1])
      && (close_arrayM1[1]>senkou_span_a_bufferM1[1])
      && (open_arrayM1[1]>senkou_span_a_bufferM1[1])
      )
      || 
      (
      (senkou_span_b_bufferM1[1]>senkou_span_a_bufferM1[1])
      && (close_arrayM1[1]>senkou_span_b_bufferM1[1])
      && (open_arrayM1[1]>senkou_span_b_bufferM1[1])
      )
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickIsOverKumoM5()
  {
   if(
      (
      (senkou_span_a_bufferM5[1]>senkou_span_b_bufferM5[1])
      && (close_arrayM5[1]>senkou_span_a_bufferM5[1])
      && (open_arrayM5[1]>senkou_span_a_bufferM5[1])
      )
      || 
      (
      (senkou_span_b_bufferM5[1]>senkou_span_a_bufferM5[1])
      && (close_arrayM5[1]>senkou_span_b_bufferM5[1])
      && (open_arrayM5[1]>senkou_span_b_bufferM5[1])
      )
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickIsOverKumoM15()
  {
   if(
      (
      (senkou_span_a_bufferM15[1]>senkou_span_b_bufferM15[1])
      && (close_arrayM15[1]>senkou_span_a_bufferM15[1])
      && (open_arrayM15[1]>senkou_span_a_bufferM15[1])
      )
      || 
      (
      (senkou_span_b_bufferM15[1]>senkou_span_a_bufferM15[1])
      && (close_arrayM15[1]>senkou_span_b_bufferM15[1])
      && (open_arrayM15[1]>senkou_span_b_bufferM15[1])
      )
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickIsOverKumoH1()
  {
   if(
      (
      (senkou_span_a_bufferH1[1]>senkou_span_b_bufferH1[1])
      && (close_arrayH1[1]>senkou_span_a_bufferH1[1])
      && (open_arrayH1[1]>senkou_span_a_bufferH1[1])
      )
      || 
      (
      (senkou_span_b_bufferH1[1]>senkou_span_a_bufferH1[1])
      && (close_arrayH1[1]>senkou_span_b_bufferH1[1])
      && (open_arrayH1[1]>senkou_span_b_bufferH1[1])
      )
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickIsOverKumoH4()
  {
   if(
      (
      (senkou_span_a_bufferH4[1]>senkou_span_b_bufferH4[1])
      && (close_arrayH4[1]>senkou_span_a_bufferH4[1])
      && (open_arrayH4[1]>senkou_span_a_bufferH4[1])
      )
      || 
      (
      (senkou_span_b_bufferH4[1]>senkou_span_a_bufferH4[1])
      && (close_arrayH4[1]>senkou_span_b_bufferH4[1])
      && (open_arrayH4[1]>senkou_span_b_bufferH4[1])
      )
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool previousCandlestickIsOverKumoD1()
  {
   if(
      (
      (senkou_span_a_bufferD1[1]>senkou_span_b_bufferD1[1])
      && (close_arrayD1[1]>senkou_span_a_bufferD1[1])
      && (open_arrayD1[1]>senkou_span_a_bufferD1[1])
      )
      || 
      (
      (senkou_span_b_bufferD1[1]>senkou_span_a_bufferD1[1])
      && (close_arrayD1[1]>senkou_span_b_bufferD1[1])
      && (open_arrayD1[1]>senkou_span_b_bufferD1[1])
      )
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool secondPreviousCandlestickHasCrossedOverKumoM1()
  {
   if(
      (
      (senkou_span_a_bufferM1[1]>senkou_span_b_bufferM1[1])
      && (close_arrayM1[2]>senkou_span_a_bufferM1[2])
      && (open_arrayM1[2]<=senkou_span_a_bufferM1[2])
      )
      || 
      (
      (senkou_span_b_bufferM1[1]>senkou_span_a_bufferM1[1])
      && (close_arrayM1[2]>senkou_span_b_bufferM1[2])
      && (open_arrayM1[2]<=senkou_span_b_bufferM1[2])
      )
      )
     {
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool secondPreviousCandlestickHasCrossedOverKumoM5()
  {
   if(
      (
      (senkou_span_a_bufferM5[1]>senkou_span_b_bufferM5[1])
      && (close_arrayM5[2]>senkou_span_a_bufferM5[2])
      && (open_arrayM5[2]<=senkou_span_a_bufferM5[2])
      )
      || 
      (
      (senkou_span_b_bufferM5[1]>senkou_span_a_bufferM5[1])
      && (close_arrayM5[2]>senkou_span_b_bufferM5[2])
      && (open_arrayM5[2]<=senkou_span_b_bufferM5[2])
      )
      )
     {
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool secondPreviousCandlestickHasCrossedOverKumoM15()
  {
   if(
      (
      (senkou_span_a_bufferM15[1]>senkou_span_b_bufferM15[1])
      && (close_arrayM15[2]>senkou_span_a_bufferM15[2])
      && (open_arrayM15[2]<=senkou_span_a_bufferM15[2])
      )
      || 
      (
      (senkou_span_b_bufferM15[1]>senkou_span_a_bufferM15[1])
      && (close_arrayM15[2]>senkou_span_b_bufferM15[2])
      && (open_arrayM15[2]<=senkou_span_b_bufferM15[2])
      )
      )
     {
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getTimestamp()
  {
   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0')+"."+GetTickCount();
   return timestamp;
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClosePositionsForSymbol(string symbolName)
  {
   CTrade trade;
//int i=PositionsTotal()-1;
//while(i>=0)
//{
//if(trade.PositionClose(PositionGetSymbol(i))) i--;
//}
   bool closed=trade.PositionClose(symbolName);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPositionsProfitForSymbol(string symbolName)
  {
   PositionSelect(symbolName);
   double profit=PositionGetDouble(POSITION_PROFIT);
   return profit;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BUY(string symbol,double takeprofit_pips=0.00250,double stoploss_pips=0.01000)
  {
   MqlTick lasttick;
   SymbolInfoTick(symbol,lasttick);
   double spread=lasttick.ask-lasttick.bid; // spread = prix de vente - prix d'achat
   double price = SymbolInfoDouble(symbol,SYMBOL_ASK);

   MqlTradeRequest request={0};
   MqlTradeResult  result={0};
   request.action=TRADE_ACTION_DEAL;                     // type of trade operation
   request.symbol=symbol;                                // symbol
   request.volume=0.1;                                     // volume of 0.1 lot
   request.type=ORDER_TYPE_BUY;                          // order type
   request.price=SymbolInfoDouble(symbol,SYMBOL_ASK);    // price for opening

                                                         //request.sl = price-(price/100)*2;
//request.tp = lasttick.bid+(lasttick.bid/100)/2;

   double stoploss=0,takeprofit=0;
//if(Digits()==5)
//{
   stoploss=price-stoploss_pips;
   takeprofit=lasttick.bid+spread+takeprofit_pips;
//} else {
//string msg=symbol+" : No OrderSend because digits != 5";
//printf(msg);
//SendNotification(msg);
//return false;
//}

//if(lasttick.bid>2)
//{
//string msg=symbol+" : No OrderSend because lasttick.bid>2";
//printf(msg);
//SendNotification(msg);
//return false;
//}

   request.sl = stoploss;
   request.tp = takeprofit;
//request.deviation=5;                                     // allowed deviation from the price
//request.magic    =EXPERT_MAGIC;                          // MagicNumber of the order
   if(!OrderSend(request,result))
     {
      PrintFormat(symbol+" : OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
      return false;
     }
   else
     {
      printf(symbol+" : OrderSend ok");
      return true;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void adjustTrailingStop(string symbol)
  {
   int posTotal=PositionsTotal();
   if(posTotal>0)
     {
      if(PositionSelect(symbol)==false)
        {
         return;
        }

      MqlTick lasttick;
      SymbolInfoTick(symbol,lasttick);
      double spread=lasttick.ask-lasttick.bid; // spread = prix de vente - prix d'achat
      double price = SymbolInfoDouble(symbol,SYMBOL_ASK);

      double positionvolume=PositionGetDouble(POSITION_VOLUME);
      double priceopen=PositionGetDouble(POSITION_PRICE_OPEN);
      double positionsl=PositionGetDouble(POSITION_SL);
      double positiontp=PositionGetDouble(POSITION_TP);
      double pricecurrent=PositionGetDouble(POSITION_PRICE_CURRENT);
      double positionswap=PositionGetDouble(POSITION_SWAP);
      double positionprofit=PositionGetDouble(POSITION_PROFIT);

      printf("volume="+string(positionvolume));
      printf("price open="+string(priceopen));
      printf("position sl="+string(positionsl));
      printf("position tp="+string(positiontp));
      printf("position price current="+string(pricecurrent));
      printf("position swap="+string(positionswap));
      printf("position profit="+string(positionprofit));

      if(positionprofit>5)
        {
         printf("Will adjust trailing stop");
        }
      else
        {
         return;
        }

      long positiontype=PositionGetInteger(POSITION_TYPE);
      if(positiontype==POSITION_TYPE_BUY)
        {

         CTrade my_trade;
         double sl=NormalizeDouble(lasttick.bid-0.00005,Digits());
         my_trade.PositionModify(symbol,sl,positiontp);

        }

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

void upload2JCSAlert(string timestamp,string period,string symbol,double buy,double sell,string h1_ls_validated,string m1_ls_validated)
  {
  
   return;
// "https://ichimoku-ea.00investdata.0webhostapp.com/alerts/?upload_2jcs_alert=test"
   string cookie=NULL,headers;
   char post[],result[];

   string jcsalert=timestamp+";"+period+";"+symbol+";"+DoubleToString(buy)+";"+DoubleToString(sell)+";"+h1_ls_validated+";"+m1_ls_validated;

   string google_url="https://investdata.000webhostapp.com/alerts/ichimokuserver.php?upload_2jcs_alert="+jcsalert;
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
      //printf("2JCS Alert sent successfully");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getAskPriceForSymbol(string sname)
  {
   MqlTick lasttick;
   SymbolInfoTick(sname,lasttick);
   double spread=lasttick.ask-lasttick.bid; // spread = prix de vente - prix d'achat
   double ask = SymbolInfoDouble(sname, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sname, SYMBOL_BID);
   return ask;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getBidPriceForSymbol(string sname)
  {
   MqlTick lasttick;
   SymbolInfoTick(sname,lasttick);
   double spread=lasttick.ask-lasttick.bid; // spread = prix de vente - prix d'achat
   double ask = SymbolInfoDouble(sname, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sname, SYMBOL_BID);
   return bid;
  }
//+------------------------------------------------------------------+
