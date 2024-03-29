//+------------------------------------------------------------------+
//|                                     IchimokuSignal4TF.mq5 |
//|                                   Copyright 2016, RHL Capital Risk|
//|                                   https://www.rff-financials.com |
//+------------------------------------------------------------------+

//notif:android mt5,mt4=DB4F3016,EEF637E9
//997CD24C,E0358708,96ABD519,B22E3F84
//contient aussi le code pour dumper les données ichimoku vers csv

#property copyright "Copyright 2016, RHL Capital Risk"
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

bool exportPrices=false;
int file_handle=INVALID_HANDLE; // File handle     

string appVersion="0.7-SSBKS-M15";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   printf("Ichimoku Trader Framework Signal Provider "+appVersion+" investdatasystems@yahoo.com");

   ObjectsDeleteAll(0,"",-1,-1);
//CloseAllPositions();
//--- create timer
   EventSetTimer(60); // 30 secondes pour tout (pas seulement marketwatch)

   initialEquity=accountInfo.Equity();
//ReadLinearRegressionChannelData();

   if(exportPrices)
     {
      //--- Create file to write data in the common folder of the terminal
      //C:\Users\Idjed\AppData\Roaming\MetaQuotes\Terminal\Common\Files
      MqlDateTime mqd;
      TimeCurrent(mqd);
      string timestamp=string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');

      file_handle=FileOpen(timestamp+"backup.csv",FILE_CSV|FILE_WRITE|FILE_ANSI|FILE_COMMON);
      if(file_handle>0)
        {
         FileWrite(file_handle,"index;t;k;ssa;ssb;cs");
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

//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
MqlParam params[];

bool forceCloseOnMinProfit=true;
double minProfit=1; // ce minprofit peut etre prioritaire ou non prioritaire selon le takeprofit !
bool forceCloseOnMaxLoss=true; // si on met à oui, le trailing stop loss n'est plus nécessaire... à voir
double maxLoss=0.25; // ce maxloss peut etre prioritaire ou non prioritaire selon le stoploss !
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//Ichimoku();

   return;

   currentEquity=accountInfo.Equity();

   if(forceCloseOnMinProfit)
     {
      if(PositionsTotal()>0)
        {
         CPositionInfo cpi;
         cpi.SelectByIndex(0);
         double profit=cpi.Profit();
         if(profit>=minProfit)
           {
            printf("Close all positions because cpi.profit >= "+string(minProfit));
            SendNotification("Close all positions because cpi.profit >= "+string(minProfit));
            CloseAllPositions();
           }
        }
     }

   if(forceCloseOnMaxLoss)
     {
      if(PositionsTotal()>0)
        {
         CPositionInfo cpi;
         cpi.SelectByIndex(0);
         double profit=cpi.Profit();
         if(profit<=(-maxLoss))
           {
            printf("Close all positions because cpi.profit <= "+string(-maxLoss));
            SendNotification("Close all positions because cpi.profit <= "+string(-maxLoss));
            CloseAllPositions();
           }
        }
     }

   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);

   double sell=lasttick.bid,buy=lasttick.ask,spread=buy-sell; ulong vol=lasttick.volume;
//printf("sell="+string(sell)+" ; buy="+string(buy)+ " ; spread="+string(spread) + " ; vol="+string(vol));
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
datetime allowed_until=D'2050.01.15 00:00';
bool expiration_notified=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(TimeCurrent()>allowed_until)
     {
      if(expiration_notified==false)
        {
         printf("Ichimoku Trader Framework Signal Provider "+appVersion+" : EXPIRED. Please contact investdatasystems@yahoo.com ");
         SendNotification("Ichimoku Trader Framework Signal Provider "+appVersion+" : EXPIRED. Please contact investdatasystems@yahoo.com ");
         expiration_notified=true;
        }
      return;
     }

   Ichimoku();

//currentEquity = accountInfo.Equity();
//double deltaEquity = currentEquity-initialEquity;
//printf("currentEquity-initialEquity=" + string(deltaEquity));
//SendNotification("currentEquity-initialEquity=" + deltaEquity);
  }

bool done=false;

bool M1_Over=false;
bool M15_Over= false;
bool H1_Over = false;
bool previousIsOver=false;

bool m1_over[];
bool m15_over[];
bool h1_over[];
bool h4_over[];
bool previous_over[];

bool M1_Under=false;
bool M15_Under= false;
bool H1_Under = false;
bool previousIsUnder=false;

bool m1_under[];
bool m15_under[];
bool h1_under[];
bool h4_under[];
bool previous_under[];

bool first_run_done[];

//chantier 2016 suite remarques KP
bool m1_price_over_ks[];
bool m1_price_under_ks[];
bool m1_price_over_ssb[];
bool m1_price_under_ssb[];
bool previous_m1_price_over_ks[];
bool previous_m1_price_under_ks[];
bool previous_m1_price_over_ssb[];
bool previous_m1_price_under_ssb[];
bool first_m1_run_done[];
//----

int maxhisto=256;

bool enablem1=true;
bool enablem15=true;
bool enableh1=true;
bool enableh4=true;

bool initdone=false;
int stotal=0;
bool onlySymbolsInMarketwatch=true;
//datetime allowed_until = D'2016.01.15 00:00';
//bool expiration_notified = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ichimoku()
  {
   int tenkan_sen=9;              // period of Tenkan-sen
   int kijun_sen=26;              // period of Kijun-sen
   int senkou_span_b=52;          // period of Senkou Span B

//--- indicator buffer
   double tenkan_sen_buffer[];
   double kijun_sen_buffer[];
   double senkou_span_a_buffer[];
   double senkou_span_b_buffer[];
   double chikou_span_buffer[];
   double senkou_span_a_buffer_H1[];
   double senkou_span_b_buffer_H1[];
   double senkou_span_a_buffer_H4[];
   double senkou_span_b_buffer_H4[];

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer_H1,true);
   ArraySetAsSeries(senkou_span_b_buffer_H1,true);
   ArraySetAsSeries(senkou_span_a_buffer_H4,true);
   ArraySetAsSeries(senkou_span_b_buffer_H4,true);

   if(!initdone)
     {
      stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)

                                                     //if(enablem1) ArrayResize(m1_over,stotal,stotal);
      if(enablem15) ArrayResize(m15_over,stotal,stotal);
      if(enableh1) ArrayResize(h1_over,stotal,stotal);
      if(enableh4) ArrayResize(h4_over,stotal,stotal);
      ArrayResize(previous_over,stotal,stotal);

      //nouveaux traitements ssb ks
      ArrayResize(previous_m1_price_over_ssb,stotal,stotal);
      ArrayResize(previous_m1_price_under_ssb,stotal,stotal);
      ArrayResize(m1_price_over_ssb,stotal,stotal);
      ArrayResize(m1_price_under_ssb,stotal,stotal);
      ArrayResize(first_m1_run_done,stotal,stotal);
      //----

      //if(enablem1) ArrayResize(m1_under,stotal,stotal);
      if(enablem15) ArrayResize(m15_under,stotal,stotal);
      if(enableh1) ArrayResize(h1_under,stotal,stotal);
      if(enableh4) ArrayResize(h4_under,stotal,stotal);
      ArrayResize(previous_under,stotal,stotal);

      ArrayResize(first_run_done,stotal,stotal);

      //initialisation de tout le tableau à false car sinon la première valeur vaut true par défaut (bug?).
      for(int sindex=0;sindex<stotal;sindex++){
         first_m1_run_done[sindex] = false;
      }

      initdone=true;
     }

   for(int sindex=0;sindex<stotal;sindex++)
     {

      string sname=SymbolName(sindex,onlySymbolsInMarketwatch);

      printf("Current symbol = "+sname+" "+(sindex+1)+"/"+stotal);

      MqlTick lasttick;
      double price;
      double sell;
      double buy;
      ulong vol;
      double spread;

      // Début Traitements M1

      int handle;
      int handleH1;
      int handleH4;

      // Début Traitements M15

      price=0;
      sell=0;
      buy=0;
      spread=0;
      vol=0;

      if(enablem1)
        {
         handle=iIchimoku(sname,PERIOD_M15,tenkan_sen,kijun_sen,senkou_span_b);
         handleH1=iIchimoku(sname,PERIOD_H1,tenkan_sen,kijun_sen,senkou_span_b);
         handleH4=iIchimoku(sname,PERIOD_H4,tenkan_sen,kijun_sen,senkou_span_b);
         if( (handle!=INVALID_HANDLE) && (handleH1!=INVALID_HANDLE) && (handleH4!=INVALID_HANDLE) )
           {
            int max=maxhisto;

            int nbt = CopyBuffer(handle,TENKANSEN_LINE,0,max,tenkan_sen_buffer);
            int nbk = CopyBuffer(handle,KIJUNSEN_LINE,0,max,kijun_sen_buffer);
            int nbssa = CopyBuffer(handle,SENKOUSPANA_LINE,0,max,senkou_span_a_buffer);
            int nbssb = CopyBuffer(handle,SENKOUSPANB_LINE,0,max,senkou_span_b_buffer);
            int nbc=CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);
            
            int nbssaH1 = CopyBuffer(handleH1,SENKOUSPANA_LINE,0,max,senkou_span_a_buffer_H1);
            int nbssbH1 = CopyBuffer(handleH1,SENKOUSPANB_LINE,0,max,senkou_span_b_buffer_H1);
            int nbssaH4 = CopyBuffer(handleH4,SENKOUSPANA_LINE,0,max,senkou_span_a_buffer_H4);
            int nbssbH4 = CopyBuffer(handleH4,SENKOUSPANB_LINE,0,max,senkou_span_b_buffer_H4);

            MqlTick lasttick;
            SymbolInfoTick(sname,lasttick);
/*double*/ price=lasttick.ask;
/*double*/ sell=lasttick.bid;buy=lasttick.ask;spread=buy-sell; ulong vol=lasttick.volume;

            //printf("buy p="+buy+ " ; ssb="+senkou_span_b_buffer[0]);

            //NOUVEAUX TRAITEMENTS SSB/KS

            if(first_m1_run_done[sindex]==false)
              {
               //test si prix est au dessus de ssb
               if(priceIsOverSsb(buy,senkou_span_b_buffer))
                 {
                  printf(sname+" : m15 : first scan : price is OVER SSB ; p="+buy+" ; ssb=" + senkou_span_b_buffer[0] + " ; " + TimeCurrent());
                  ///SendNotification(sname+" : m15 : first scan : price is OVER SSB ; p="+buy+" ; ssb=" + senkou_span_b_buffer[0] + " ; " + TimeCurrent());

                  //is it over kumo in H1 and H4?
                  if (priceIsOverKumo(buy,senkou_span_a_buffer_H1,senkou_span_b_buffer_H1)
                     && priceIsOverKumo(buy,senkou_span_a_buffer_H4,senkou_span_b_buffer_H4)
                  ){
                     SendNotification("****" + sname+" : m15/h1/h4 : first scan : price is OVER SSB/KUMO/KUMO ; " + TimeCurrent());
                  }

                  previous_m1_price_over_ssb[sindex] = true;
                  previous_m1_price_under_ssb[sindex] = false;
                 }

               //test si prix est sous ssb
               if(priceIsUnderSsb(buy,senkou_span_b_buffer))
                 {
                  printf(sname+" : m15 : first scan : price is UNDER SSB ; p="+buy+" ; ssb=" + senkou_span_b_buffer[0] + " ; " + TimeCurrent());
                  ///SendNotification(sname+" : m15 : first scan : price is UNDER SSB ; p="+buy+" ; ssb=" + senkou_span_b_buffer[0] + " ; " + TimeCurrent());

                  //is it under kumo in H1 and H4?
                  if (priceIsUnderKumo(buy,senkou_span_a_buffer_H1,senkou_span_b_buffer_H1)
                     && priceIsUnderKumo(buy,senkou_span_a_buffer_H4,senkou_span_b_buffer_H4)
                  ){
                     SendNotification("****" + sname+" : m15/h1/h4 : first scan : price is UNDER SSB/KUMO/KUMO ; " + TimeCurrent());
                  }

                  previous_m1_price_over_ssb[sindex] = false;
                  previous_m1_price_under_ssb[sindex] = true;
                 }
                 
               if(priceEqualsSsb(buy,senkou_span_b_buffer)){
                  printf(sname+" : m15 : first scan : price EQUALS SSB ; p="+buy+" ; ssb=" + senkou_span_b_buffer[0] + " ; " + TimeCurrent());
                  ///SendNotification(sname+" : m15 : first scan : price EQUALS SSB ; p="+buy+" ; ssb=" + senkou_span_b_buffer[0] + " ; " + TimeCurrent());
                  previous_m1_price_over_ssb[sindex] = false;
                  previous_m1_price_under_ssb[sindex] = false;
               }
                                  
               first_m1_run_done[sindex]=true;
              }
              else {
               //printf("first run already done");
               
               //if (sindex == "EURPLN"){
               
               if (priceIsOverSsb(buy,senkou_span_b_buffer)){
                  if (previous_m1_price_over_ssb[sindex] == true){
                     //printf("current price is over ssb and previous is over");
                  }
                  else if (previous_m1_price_under_ssb[sindex] == true){
                     //printf("current price is over ssb and previous is under");
                     ///SendNotification("ALERT : " + sname+" : m15 : Price is now OVER ; p=" + buy + " ; ssb=" + senkou_span_b_buffer[0] + " ; "  + TimeCurrent());
                  }
                  
                  //is it over kumo in H1 and H4?
                  if (priceIsOverKumo(buy,senkou_span_a_buffer_H1,senkou_span_b_buffer_H1)
                     && priceIsOverKumo(buy,senkou_span_a_buffer_H4,senkou_span_b_buffer_H4)
                  ){
                     SendNotification("****" + sname+" : m15/h1/h4 : price is now OVER SSB/KUMO/KUMO ; " + TimeCurrent());
                  }
                  
                  previous_m1_price_over_ssb[sindex] = true;
                  previous_m1_price_under_ssb[sindex] = false;
               }
               if (priceIsUnderSsb(buy,senkou_span_b_buffer)){
                  if (previous_m1_price_over_ssb[sindex] == true){
                     //printf("current price is under ssb and previous is over");
                     ///SendNotification("ALERT : " + sname+" : m15 : Price is now UNDER SSB ; p=" + buy + " ; ssb=" + senkou_span_b_buffer[0] + " ; "  + TimeCurrent());
                  }
                  else if (previous_m1_price_under_ssb[sindex] == true){
                     //printf("current price is under ssb and previous is under");
                  }
                  
                  //is it under kumo in H1 and H4?
                  if (priceIsUnderKumo(buy,senkou_span_a_buffer_H1,senkou_span_b_buffer_H1)
                     && priceIsUnderKumo(buy,senkou_span_a_buffer_H4,senkou_span_b_buffer_H4)
                  ){
                     SendNotification("****" + sname+" : m15/h1/h4 : price is now UNDER SSB/KUMO/KUMO ; " + TimeCurrent());
                  }
                  
                  previous_m1_price_over_ssb[sindex] = false;
                  previous_m1_price_under_ssb[sindex] = true;
               }
               if (priceEqualsSsb(buy,senkou_span_b_buffer)){
                  if (previous_m1_price_over_ssb[sindex] == true){
                     //printf("current price equals ssb and previous is over");
                  }
                  else if (previous_m1_price_under_ssb[sindex] == true){
                     //printf("current price equals ssb and previous is under");
                  }
                  previous_m1_price_over_ssb[sindex] = false;
                  previous_m1_price_under_ssb[sindex] = false;
               }
               
               //}
               
              }

            //printf(sname + " : M15 : OK");

           }
         else
           {
            //erreur handle
            //printf(sname + " : m1 : ERROR : " + GetLastError());
           }

         IndicatorRelease(handle);
        }
      // Fin Traitements M15

     } // fin boucle sur sindex (symbol index)
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool priceIsOverSsb(double price,double &ssb_buf[])
  {
   if(price==EMPTY_VALUE){
      //printf("price is empty");
      return false;
   }

   if(ArraySize(ssb_buf)>0)
     {
      //printf("ssb_buf[0]="+ssb_buf[0]);
   
      if(price>ssb_buf[0]){
         //printf("price is over ssb");
         return true;
      }
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssb n'est pas supérieure à 0 !");
      return false;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool priceIsUnderSsb(double price,double &ssb_buf[])
  {
   if(price==EMPTY_VALUE)
      return false;

   if(ArraySize(ssb_buf)>0)
     {
      if(price<ssb_buf[0])
         return true;
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssb n'est pas supérieure à 0 !");
      return false;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool priceEqualsSsb(double price,double &ssb_buf[])
  {
   if(price==EMPTY_VALUE)
      return false;

   if(ArraySize(ssb_buf)>0)
     {
      if(price==ssb_buf[0])
         return true;
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssb n'est pas supérieure à 0 !");
      return false;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool priceIsOverKumo(double price,double &ssa_buf[],double &ssb_buf[])
  {
   if(price==EMPTY_VALUE)
      return false;

   if(ArraySize(ssa_buf)>0)
     {
      if(ssa_buf[0]>ssb_buf[0])
        {
         if(price>ssa_buf[0])
            return true;
        }
      else if(ssa_buf[0]<ssb_buf[0])
        {
         if(price>ssb_buf[0])
            return true;
        }
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa n'est pas supérieure à 0 !");
      return false;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool priceIsUnderKumo(double price,double &ssa_buf[],double &ssb_buf[])
  {
   if(price==EMPTY_VALUE)
      return false;

   if(ArraySize(ssa_buf)>0)
     {
      if(ssa_buf[0]>ssb_buf[0])
        {
         if(price<ssb_buf[0])
            return true;
        }
      else if(ssa_buf[0]<ssb_buf[0])
        {
         if(price<ssa_buf[0])
            return true;
        }
      else
        {
         return false;
        }
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool priceIsOverTenkan(double price,double &tenkan_buf[])
  {
   if(price==EMPTY_VALUE)
      return false;

   if(tenkan_buf[0]==EMPTY_VALUE)
      return false;

   if(ArraySize(tenkan_buf)>0)
     {
      if(price>tenkan_buf[0])
         return true;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa n'est pas supérieure à 0 !");
      return false;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool priceIsUnderTenkan(double price,double &tenkan_buf[])
  {
   if(price==EMPTY_VALUE)
      return false;

   if(tenkan_buf[0]==EMPTY_VALUE)
      return false;

   if(ArraySize(tenkan_buf)>0)
     {
      if(price<tenkan_buf[0])
         return true;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa n'est pas supérieure à 0 !");
      return false;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool priceIsOverKijun(double price,double &kijun_buf[])
  {
   if(price==EMPTY_VALUE)
      return false;

   if(kijun_buf[0]==EMPTY_VALUE)
      return false;

   if(ArraySize(kijun_buf)>0)
     {
      if(price>kijun_buf[0])
         return true;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa n'est pas supérieure à 0 !");
      return false;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool priceIsUnderKijun(double price,double &kijun_buf[])
  {
   if(price==EMPTY_VALUE)
      return false;

   if(kijun_buf[0]==EMPTY_VALUE)
      return false;

   if(ArraySize(kijun_buf)>0)
     {
      if(price<kijun_buf[0])
         return true;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa n'est pas supérieure à 0 !");
      return false;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chikouIsOverTenkan(double &chikou_buf[],double &tenkan_buf[])
  {
   if((ArraySize(chikou_buf)>26) && (ArraySize(tenkan_buf)>26))
     {
      if(chikou_buf[26]==EMPTY_VALUE)
         return false;

      if(tenkan_buf[26]==EMPTY_VALUE)
         return false;

      if(chikou_buf[26]>tenkan_buf[26])
        {
         return true;
        }
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chikouIsUnderTenkan(double &chikou_buf[],double &tenkan_buf[])
  {
   if((ArraySize(chikou_buf)>26) && (ArraySize(tenkan_buf)>26))
     {
      if(chikou_buf[26]==EMPTY_VALUE)
         return false;

      if(tenkan_buf[26]==EMPTY_VALUE)
         return false;

      if(chikou_buf[26]<tenkan_buf[26])
        {
         return true;
        }
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chikouIsOverKijun(double &chikou_buf[],double &kijun_buf[])
  {
   if((ArraySize(chikou_buf)>26) && (ArraySize(kijun_buf)>26))
     {
      if(chikou_buf[26]==EMPTY_VALUE)
         return false;

      if(kijun_buf[26]==EMPTY_VALUE)
         return false;

      if(chikou_buf[26]>kijun_buf[26])
        {
         return true;
        }
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chikouIsUnderKijun(double &chikou_buf[],double &kijun_buf[])
  {
   if((ArraySize(chikou_buf)>26) && (ArraySize(kijun_buf)>26))
     {
      if(chikou_buf[26]==EMPTY_VALUE)
         return false;

      if(kijun_buf[26]==EMPTY_VALUE)
         return false;

      if(chikou_buf[26]<kijun_buf[26])
        {
         return true;
        }
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chikouIsOverPrice(double &chikou_buf[],double &kijun_buf[])
  {
// A FAIRE !!!!
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chikouIsUnderPrice(double &chikou_buf[],double &kijun_buf[])
  {
// A FAIRE !!!!
   return false;
  }
//-- debut anciennes fonctions

bool tenkanPassedOverKijun(double &tenkan_buf[],double &kijun_buf[])
  {
   int size=ArraySize(tenkan_buf);
   if(size>1)
     {
      if((tenkan_buf[0]>kijun_buf[0]) && (tenkan_buf[1]<kijun_buf[1]))
         return true;
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer tenkan n'est pas supérieure à 1 !");
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool tenkanPassedUnderKijun(double &tenkan_buf[],double &kijun_buf[])
  {
   int size=ArraySize(tenkan_buf);
   if(size>1)
     {
      if((tenkan_buf[0]<kijun_buf[0]) && (tenkan_buf[1]>kijun_buf[1]))
         return true;
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer tenkan n'est pas supérieure à 1 !");
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool tenkanIsUnderKijun(double &tenkan_buf[],double &kijun_buf[])
  {
   int size=ArraySize(tenkan_buf);
   if(size>0)
     {
      if(tenkan_buf[0]<kijun_buf[0])
         return true;
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer tenkan n'est pas supérieure à 0 !");
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool tenkanIsOverKijun(double &tenkan_buf[],double &kijun_buf[])
  {
   int size=ArraySize(tenkan_buf);
   if(size>0)
     {
      if(tenkan_buf[0]>kijun_buf[0])
         return true;
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer tenkan n'est pas supérieure à 0 !");
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool tenkanIsUnderKumo(double &tenkan_buf[],double &ssa_buf[],double &ssb_buf[])
  {
   if((ArraySize(ssa_buf)>0) && (ArraySize(tenkan_buf)>0))
     {
      if(ssa_buf[0]>ssb_buf[0])
        {
         if(tenkan_buf[0]<ssb_buf[0])
            return true;
        }
      else if(ssa_buf[0]<ssb_buf[0])
        {
         if(tenkan_buf[0]<ssa_buf[0])
            return true;
        }
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool tenkanIsOverKumo(double &tenkan_buf[],double &ssa_buf[],double &ssb_buf[])
  {
   if((ArraySize(ssa_buf)>0) && (ArraySize(tenkan_buf)>0))
     {
      if(ssa_buf[0]>ssb_buf[0])
        {
         if(tenkan_buf[0]>ssa_buf[0])
            return true;
        }
      else if(ssa_buf[0]<ssb_buf[0])
        {
         if(tenkan_buf[0]>ssb_buf[0])
            return true;
        }
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool kijunIsUnderKumo(double &kijun_buf[],double &ssa_buf[],double &ssb_buf[])
  {
   if((ArraySize(ssa_buf)>0) && (ArraySize(kijun_buf)>0))
     {
      if(ssa_buf[0]>ssb_buf[0])
        {
         if(kijun_buf[0]<ssb_buf[0])
            return true;
        }
      else if(ssa_buf[0]<ssb_buf[0])
        {
         if(kijun_buf[0]<ssa_buf[0])
            return true;
        }
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool kijunIsOverKumo(double &kijun_buf[],double &ssa_buf[],double &ssb_buf[])
  {
   if((ArraySize(ssa_buf)>0) && (ArraySize(kijun_buf)>0))
     {
      if(ssa_buf[0]>ssb_buf[0])
        {
         if(kijun_buf[0]>ssa_buf[0])
            return true;
        }
      else if(ssa_buf[0]<ssb_buf[0])
        {
         if(kijun_buf[0]>ssb_buf[0])
            return true;
        }
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chikouIsUnderKumo(double &chikou_buf[],double &ssa_buf[],double &ssb_buf[])
  {
   if((ArraySize(ssa_buf)>0) && (ArraySize(chikou_buf)>0))
     {
      if(ssa_buf[26]>ssb_buf[26])
        {
         if(chikou_buf[26]<ssb_buf[26])
            return true;
        }
      else if(ssa_buf[26]<ssb_buf[26])
        {
         if(chikou_buf[26]<ssa_buf[26])
            return true;
        }
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chikouIsOverKumo(double &chikou_buf[],double &ssa_buf[],double &ssb_buf[])
  {
   if((ArraySize(ssa_buf)>0) && (ArraySize(chikou_buf)>0))
     {
      if(ssa_buf[26]>ssb_buf[26])
        {
         //printf("ssachikou=" + ssa_buf[26]);
         if(chikou_buf[26]>ssa_buf[26])
            return true;
        }
      else if(ssa_buf[26]<ssb_buf[26])
        {
         if(chikou_buf[26]>ssb_buf[26])
            return true;
        }
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer ssa ou tenkan n'est pas supérieure à 0 !");
      return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chikouIsUnderPrice(double price,double &chikou_buf[])
  {
   if(ArraySize(chikou_buf)>26)
     {
      if(chikou_buf[26]<price)
         return true;
      else
         return false;
     }
   else
     {
      printf("ERREUR : Taille du buffer chikou n'est pas supérieure à 0 !");
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void adjustTrailingStop()
  {
   int posTotal=PositionsTotal();
   if(posTotal>0)
     {
      PositionSelect(Symbol());
      double positionvolume=PositionGetDouble(POSITION_VOLUME);
      double priceopen=PositionGetDouble(POSITION_PRICE_OPEN);
      double positionsl=PositionGetDouble(POSITION_SL);
      double positiontp=PositionGetDouble(POSITION_TP);
      double pricecurrent=PositionGetDouble(POSITION_PRICE_CURRENT);
      double positionswap=PositionGetDouble(POSITION_SWAP);
      double positionprofit=PositionGetDouble(POSITION_PROFIT);

/*printf("volume=" + string(positionvolume));
      printf("price open=" + string(priceopen));
      printf("position sl=" + string(positionsl));
      printf("position tp=" + string(positiontp));
      printf("position price current=" + string(pricecurrent));
      printf("position swap=" + string(positionswap));
      printf("position profit=" + string(positionprofit));*/

      // ajustement du trailing stop
      printf("*** adjusting trailing stop ***");
      //printf("posTotal=" + string(PositionsTotal()));

      long positiontype=PositionGetInteger(POSITION_TYPE);
/*if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
      {
         printf("positiontype=BUY");
      }
      else if (positiontype==POSITION_TYPE_SELL)
      {
         printf("positiontype=SELL");
      }*/

      for(int i=0;i<posTotal;i++)
        {
         MqlTradeRequest request={0};
         MqlTradeResult result={0};

         request.action = TRADE_ACTION_SLTP;
         request.symbol = Symbol();
         if(positiontype==POSITION_TYPE_BUY)
           {
            request.sl=pricecurrent-stoplossdelta;
            //request.tp = pricecurrent+takeprofitdelta; //trailing take profit :)
            request.tp=positiontp;
           }
         else if(positiontype==POSITION_TYPE_SELL)
           {
            request.sl=pricecurrent+stoplossdelta;
            //request.tp = pricecurrent-takeprofitdelta; //trailing take profit :)
            request.tp=positiontp;
           }

         if(!OrderSend(request,result))
           {
            printf("OrderSend failed ; GetLastError() = "+string(GetLastError())+" ; result.retcode = "+string(result.retcode));
           }

        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getTicks()
  {
//--- the array that receives ticks
   MqlTick tick_array[];
   int ticks=10;
   int copied=CopyTicks(_Symbol,tick_array,COPY_TICKS_ALL,0,ticks);
   if(copied>0)
     {
      for(int i=0;i<copied;i++)
        {
         MqlTick tick=tick_array[i];
         string tick_string=StringFormat("%d: %s  %G  %G",
                                         i,
                                         TimeToString(tick.time,TIME_MINUTES|TIME_SECONDS),
                                         tick.bid,
                                         tick.ask);
         printf(tick_string);
        }
     }
   else
     {
      printf("Ticks could not be loaded. GetLastError()=",GetLastError());
     }
  }
// period peut être Period() pour le timeframe courant
void getHistoryData(ENUM_TIMEFRAMES period)
  {
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied=CopyRates(Symbol(),period,0,100,rates);
   if(copied>0)
     {
/*Print("Bars copied: "+copied);
      string format="open = %G, high = %G, low = %G, close = %G, volume = %d";
      string out;
      int size=fmin(copied,10);
      for(int i=0;i<size;i++)
      {
         out=i+":"+TimeToString(rates[i].time);
         out=out+" "+StringFormat(format, rates[i].open, rates[i].high, rates[i].low, rates[i].close, rates[i].tick_volume);
         Print(out);
      }*/
     }
   else
     {
      Print("Failed to get history data for the symbol ",Symbol());
     }
  }

//ci-dessous ces trois variables pour BUY() et SELL() sans paramètres d'entrée
double stoplossdelta=0.0040;//;0.00800; //ex de valeur:1.17121
double takeprofitdelta=0.00010; //haute volatilité 0.01500 ; faible 0.00750 ?
double volume=0.01;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BUY()
  {

   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);

   double price=lasttick.ask;
   double stoploss=price-stoplossdelta;
   double takeprofit=price+takeprofitdelta;

//printf("buy price=" + string(price) + " sl=" + string(stoploss) + " tp=" + string(takeprofit));

   CTrade trade;
   if(trade.PositionOpen(
      Symbol(),
      ORDER_TYPE_BUY,
      volume,
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
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SELL()
  {
   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);

   double price=lasttick.bid;
   double stoploss=price+stoplossdelta;
   double takeprofit=price-takeprofitdelta;

//printf("sell price=" + string(price) + " sl=" + string(stoploss) + " tp=" + string(takeprofit));

   CTrade trade;
   if(trade.PositionOpen(
      Symbol(),
      ORDER_TYPE_SELL,
      volume,
      price,
      stoploss,
      takeprofit,
      "Sold at "+string(price)+";sl="+string(stoploss)+";tp="+string(takeprofit)
      ))
     {
      printf("Sell ok at "+string(price)+" sl="+string(stoploss)+" tp="+string(takeprofit));
      SendNotification("Sell ok at "+string(price)+" sl="+string(stoploss)+" tp="+string(takeprofit));
      return true;
     }
   else
     {
      printf("Sell ERROR = "+string(GetLastError())+" ; ResultRetcode = "+string(trade.ResultRetcode()));
      SendNotification("Sell ERROR = "+string(GetLastError())+" ; ResultRetcode = "+string(trade.ResultRetcode()));
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BUY(double price,double stoploss,double takeprofit)
  {
   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);

//double price = lasttick.ask;
//double stoploss = price-stoplossdelta;
//double takeprofit = price+takeprofitdelta;

//printf("buy price=" + string(price) + " sl=" + string(stoploss) + " tp=" + string(takeprofit));

   CTrade trade;
   if(trade.PositionOpen(
      Symbol(),
      ORDER_TYPE_BUY,
      volume,
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
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SELL(double price,double stoploss,double takeprofit)
  {
   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);

//double price = lasttick.bid;
//double stoploss = price+stoplossdelta;
//double takeprofit = price-takeprofitdelta;

//printf("sell price=" + string(price) + " sl=" + string(stoploss) + " tp=" + string(takeprofit));

   CTrade trade;
   if(trade.PositionOpen(
      Symbol(),
      ORDER_TYPE_SELL,
      volume,
      price,
      stoploss,
      takeprofit,
      "Sold at "+string(price)+";sl="+string(stoploss)+";tp="+string(takeprofit)
      ))
     {
      printf("Sell ok at "+string(price)+" sl="+string(stoploss)+" tp="+string(takeprofit));
      SendNotification("Sell ok at "+string(price)+" sl="+string(stoploss)+" tp="+string(takeprofit));
      return true;
     }
   else
     {
      printf("Sell ERROR = "+string(GetLastError())+" ; ResultRetcode = "+string(trade.ResultRetcode()));
      SendNotification("Sell ERROR = "+string(GetLastError())+" ; ResultRetcode = "+string(trade.ResultRetcode()));
      return false;
     }
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
