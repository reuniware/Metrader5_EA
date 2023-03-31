//+------------------------------------------------------------------+
//|                                     IchimokuSignal4TF.mq5 |
//|                                   Copyright 2016, RHL Capital Risk|
//|                                   https://www.rff-financials.com |
//+------------------------------------------------------------------+

//notif:android mt5,mt4=DB4F3016,EEF637E9
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

string appVersion="0.6-3TF";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   printf("Ichimoku Trader Framework Signal Provider "+appVersion+" investdatasystems@yahoo.com");

   ObjectsDeleteAll(0,"",-1,-1);
//CloseAllPositions();
//--- create timer
   EventSetTimer(120); // 30 secondes pour tout (pas seulement marketwatch)

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

int maxhisto=128;

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

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   if(!initdone)
     {
      stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)

      //if(enablem1) ArrayResize(m1_over,stotal,stotal);
      if(enablem15) ArrayResize(m15_over,stotal,stotal);
      if(enableh1) ArrayResize(h1_over,stotal,stotal);
      if(enableh4) ArrayResize(h4_over,stotal,stotal);
      ArrayResize(previous_over,stotal,stotal);

      //if(enablem1) ArrayResize(m1_under,stotal,stotal);
      if(enablem15) ArrayResize(m15_under,stotal,stotal);
      if(enableh1) ArrayResize(h1_under,stotal,stotal);
      if(enableh4) ArrayResize(h4_under,stotal,stotal);
      ArrayResize(previous_under,stotal,stotal);

      ArrayResize(first_run_done,stotal,stotal);

      initdone=true;
     }

   for(int sindex=0;sindex<stotal;sindex++)
     {

      string sname=SymbolName(sindex,onlySymbolsInMarketwatch);

      printf("Current symbol = "+sname+" "+sindex+"/"+stotal);

      MqlTick lasttick;
      double price;
      double sell;
      double buy;
      ulong vol;
      double spread;

      // Début Traitements M1

      int handle;

      /*if(enablem1)
        {
         handle=iIchimoku(sname,PERIOD_M1,tenkan_sen,kijun_sen,senkou_span_b);
         if(handle!=INVALID_HANDLE)
           {
            int max=maxhisto;

            int nbt = CopyBuffer(handle,TENKANSEN_LINE,0,max,tenkan_sen_buffer);
            int nbk = CopyBuffer(handle,KIJUNSEN_LINE,0,max,kijun_sen_buffer);
            int nbssa = CopyBuffer(handle,SENKOUSPANA_LINE,0,max,senkou_span_a_buffer);
            int nbssb = CopyBuffer(handle,SENKOUSPANB_LINE,0,max,senkou_span_b_buffer);
            int nbc=CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

            SymbolInfoTick(sname,lasttick);
            price=lasttick.ask;
            sell=lasttick.bid;
            buy=lasttick.ask;
            spread=buy-sell;
            vol=lasttick.volume;

            if(
               (priceIsOverKumo(sell,senkou_span_a_buffer,senkou_span_b_buffer))
               && (priceIsOverTenkan(sell,tenkan_sen_buffer))
               && (priceIsOverKijun(sell,kijun_sen_buffer))
               && (chikouIsOverKumo(chikou_span_buffer,senkou_span_a_buffer,senkou_span_b_buffer))
               && (chikouIsOverTenkan(chikou_span_buffer,tenkan_sen_buffer))
               && (chikouIsOverKijun(chikou_span_buffer,kijun_sen_buffer))
               )
              {
               //printf("M1 : price & chikou over kumo+tenkan+kijun");
               m1_over[sindex]=true;//M1_Over=true;
              }

            if(
               (priceIsUnderKumo(sell,senkou_span_a_buffer,senkou_span_b_buffer))
               && (priceIsUnderTenkan(sell,tenkan_sen_buffer))
               && (priceIsUnderKijun(sell,kijun_sen_buffer))
               && (chikouIsUnderKumo(chikou_span_buffer,senkou_span_a_buffer,senkou_span_b_buffer))
               && (chikouIsUnderTenkan(chikou_span_buffer,tenkan_sen_buffer))
               && (chikouIsUnderKijun(chikou_span_buffer,kijun_sen_buffer))
               )
              {
               //printf("M1 : price & chikou over kumo+tenkan+kijun");
               m1_under[sindex]=true;// M1_Under=true;
              }
              printf(sname + " : M1 : OK");
           }
         else
           {
            //err handle
              printf(sname + " : M1 : ERROR : " + GetLastError());
           }

         IndicatorRelease(handle);
        }*/
      // Fin Traitements M1

      // Début Traitements M15

      if(enablem15)
        {
         handle=iIchimoku(sname,PERIOD_M15,tenkan_sen,kijun_sen,senkou_span_b);
         if(handle!=INVALID_HANDLE)
           {
            int max=maxhisto;

            int nbt = CopyBuffer(handle,TENKANSEN_LINE,0,max,tenkan_sen_buffer);
            int nbk = CopyBuffer(handle,KIJUNSEN_LINE,0,max,kijun_sen_buffer);
            int nbssa = CopyBuffer(handle,SENKOUSPANA_LINE,0,max,senkou_span_a_buffer);
            int nbssb = CopyBuffer(handle,SENKOUSPANB_LINE,0,max,senkou_span_b_buffer);
            int nbc=CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

            MqlTick lasttick;
            SymbolInfoTick(sname,lasttick);
            double price=lasttick.ask;
            double sell=lasttick.bid,buy=lasttick.ask,spread=buy-sell; ulong vol=lasttick.volume;

            if(
               (priceIsOverKumo(sell,senkou_span_a_buffer,senkou_span_b_buffer))
               && (priceIsOverTenkan(sell,tenkan_sen_buffer))
               && (priceIsOverKijun(sell,kijun_sen_buffer))
               && (chikouIsOverKumo(chikou_span_buffer,senkou_span_a_buffer,senkou_span_b_buffer))
               && (chikouIsOverTenkan(chikou_span_buffer,tenkan_sen_buffer))
               && (chikouIsOverKijun(chikou_span_buffer,kijun_sen_buffer))
               )
              {
               //printf("M15 : price & chikou over kumo+tenkan+kijun");
               m15_over[sindex]=true;//M15_Over=true;
              }

            if(
               (priceIsUnderKumo(sell,senkou_span_a_buffer,senkou_span_b_buffer))
               && (priceIsUnderTenkan(sell,tenkan_sen_buffer))
               && (priceIsUnderKijun(sell,kijun_sen_buffer))
               && (chikouIsUnderKumo(chikou_span_buffer,senkou_span_a_buffer,senkou_span_b_buffer))
               && (chikouIsUnderTenkan(chikou_span_buffer,tenkan_sen_buffer))
               && (chikouIsUnderKijun(chikou_span_buffer,kijun_sen_buffer))
               )
              {
               //printf("M15 : price & chikou over kumo+tenkan+kijun");
               m15_under[sindex]=true;//M15_Under=true;
              }
            
            printf(sname + " : M15 : OK");
           }
         else
           {
            //erreur handle
            printf(sname + " : M15 : ERROR : " + GetLastError());
           }

         IndicatorRelease(handle);
        }
      // Fin Traitements M15

      // Début Traitements H1

      if(enableh1)
        {
         handle=iIchimoku(sname,PERIOD_H1,tenkan_sen,kijun_sen,senkou_span_b);
         if(handle!=INVALID_HANDLE)
           {
            int max=maxhisto;

            int nbt = CopyBuffer(handle,TENKANSEN_LINE,0,max,tenkan_sen_buffer);
            int nbk = CopyBuffer(handle,KIJUNSEN_LINE,0,max,kijun_sen_buffer);
            int nbssa = CopyBuffer(handle,SENKOUSPANA_LINE,0,max,senkou_span_a_buffer);
            int nbssb = CopyBuffer(handle,SENKOUSPANB_LINE,0,max,senkou_span_b_buffer);
            int nbc=CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

            MqlTick lasttick;
            SymbolInfoTick(sname,lasttick);
            double price=lasttick.ask;
            double sell=lasttick.bid,buy=lasttick.ask,spread=buy-sell; ulong vol=lasttick.volume;

            if(
               (priceIsOverKumo(sell,senkou_span_a_buffer,senkou_span_b_buffer))
               && (priceIsOverTenkan(sell,tenkan_sen_buffer))
               && (priceIsOverKijun(sell,kijun_sen_buffer))
               && (chikouIsOverKumo(chikou_span_buffer,senkou_span_a_buffer,senkou_span_b_buffer))
               && (chikouIsOverTenkan(chikou_span_buffer,tenkan_sen_buffer))
               && (chikouIsOverKijun(chikou_span_buffer,kijun_sen_buffer))
               )
              {
               //printf("H1 : price & chikou over kumo+tenkan+kijun");
               h1_over[sindex]=true;//H1_Over=true;
              }

            if(
               (priceIsUnderKumo(sell,senkou_span_a_buffer,senkou_span_b_buffer))
               && (priceIsUnderTenkan(sell,tenkan_sen_buffer))
               && (priceIsUnderKijun(sell,kijun_sen_buffer))
               && (chikouIsUnderKumo(chikou_span_buffer,senkou_span_a_buffer,senkou_span_b_buffer))
               && (chikouIsUnderTenkan(chikou_span_buffer,tenkan_sen_buffer))
               && (chikouIsUnderKijun(chikou_span_buffer,kijun_sen_buffer))
               )
              {
               //printf("H1 : price & chikou over kumo+tenkan+kijun");
               h1_under[sindex]=true;//H1_Under=true;
              }

            printf(sname + " : H1: OK");

           }
         else
           {
            // err handle
            printf(sname + " : H1 : ERROR : " + GetLastError());
           }

         IndicatorRelease(handle);
        }

      // Fin Traitements H1

      // Début Traitements H4

      if(enableh4)
        {
         handle=iIchimoku(sname,PERIOD_H4,tenkan_sen,kijun_sen,senkou_span_b);
         if(handle!=INVALID_HANDLE)
           {
            int max=maxhisto;

            int nbt = CopyBuffer(handle,TENKANSEN_LINE,0,max,tenkan_sen_buffer);
            int nbk = CopyBuffer(handle,KIJUNSEN_LINE,0,max,kijun_sen_buffer);
            int nbssa = CopyBuffer(handle,SENKOUSPANA_LINE,0,max,senkou_span_a_buffer);
            int nbssb = CopyBuffer(handle,SENKOUSPANB_LINE,0,max,senkou_span_b_buffer);
            int nbc=CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

            MqlTick lasttick;
            SymbolInfoTick(sname,lasttick);
            double price=lasttick.ask;
            double sell=lasttick.bid,buy=lasttick.ask,spread=buy-sell; ulong vol=lasttick.volume;

            if(
               (priceIsOverKumo(sell,senkou_span_a_buffer,senkou_span_b_buffer))
               && (priceIsOverTenkan(sell,tenkan_sen_buffer))
               && (priceIsOverKijun(sell,kijun_sen_buffer))
               && (chikouIsOverKumo(chikou_span_buffer,senkou_span_a_buffer,senkou_span_b_buffer))
               && (chikouIsOverTenkan(chikou_span_buffer,tenkan_sen_buffer))
               && (chikouIsOverKijun(chikou_span_buffer,kijun_sen_buffer))
               )
              {
               //printf("H4 : price & chikou over kumo+tenkan+kijun");
               h4_over[sindex]=true;
              }

            if(
               (priceIsUnderKumo(sell,senkou_span_a_buffer,senkou_span_b_buffer))
               && (priceIsUnderTenkan(sell,tenkan_sen_buffer))
               && (priceIsUnderKijun(sell,kijun_sen_buffer))
               && (chikouIsUnderKumo(chikou_span_buffer,senkou_span_a_buffer,senkou_span_b_buffer))
               && (chikouIsUnderTenkan(chikou_span_buffer,tenkan_sen_buffer))
               && (chikouIsUnderKijun(chikou_span_buffer,kijun_sen_buffer))
               )
              {
               //printf("H4 : price & chikou over kumo+tenkan+kijun");
               h4_under[sindex]=true;
              }

            printf(sname + " : H4: OK");

           }
         else
           {
            // err handle
            printf(sname + " : H4 : ERROR : " + GetLastError());
           }

         IndicatorRelease(handle);
        }
        
      // Fin Traitements H4

      if(/*(m1_over[sindex]==true)
         &&*/(m15_over[sindex]==true)
         && (h1_over[sindex]==true)
         && (h4_over[sindex]==true)
         )
        {
         if(previous_over[sindex]==true)
           {
            // Actuel est au-dessus et précédent est au-dessus
           }
         else if(previous_over[sindex]==false)
           {
            // Actuel est au-dessus et précédent n'est pas au-dessus
            if(first_run_done[sindex]==false)
              {
               printf(sname+" : M15+H1+H4 : Price and Chikou are OVER Kumo/Tenkan/Kijun : "+TimeCurrent());
               SendNotification(sname+" : M15+H1+H4 : Price and Chikou are OVER Kumo/Tenkan/Kijun : "+TimeCurrent());
               first_run_done[sindex]=true;
              }
            else
              {
               printf(sname+" : M15+H1+H4 : Price and Chikou become OVER Kumo/Tenkan/Kijun : "+TimeCurrent());
               SendNotification(sname+" : M15+H1+H4 : Price and Chikou become OVER Kumo/Tenkan/Kijun : "+TimeCurrent());
              }
           }

         previous_over[sindex]=true;
         previous_under[sindex]=false;

         //if (enablem1) m1_over[sindex]=false;
         if (enablem15) m15_over[sindex]=false;
         if (enableh1) h1_over[sindex]=false;
         if (enableh4) h4_over[sindex]=false;
        }
      else
        {
         // Actuel n'est pas au-dessus
         if(previous_over[sindex]==true)
           {
            // Actuel n'est pas au-dessus et précédent est au-dessus
           }
         else if(previous_over[sindex]==false)
           {
            // Actuel n'est pas au-dessus et précédent n'est pas au-dessus
           }
        }

      if(/*(m1_under[sindex]==true)
         &&*/(m15_under[sindex]==true)
         && (h1_under[sindex]==true)
         && (h4_under[sindex]==true)
         )
        {
         if(previous_under[sindex]==true)
           {
            // Actuel est dessous et précédent est dessous
           }
         else if(previous_under[sindex]==false)
           {
            // Actuel est dessous et précédent n'est pas dessous
            if(first_run_done[sindex]==false)
              {
               printf(sname+" : M15+H1+H4 : Price and Chikou are UNDER Kumo/Tenkan/Kijun : "+TimeCurrent());
               SendNotification(sname+" : M15+H1+H4 : Price and Chikou are UNDER Kumo/Tenkan/Kijun : "+TimeCurrent());
               first_run_done[sindex]=true;
              }
            else
              {
               printf(sname+" : M15+H1+H4 : Price and Chikou become UNDER Kumo/Tenkan/Kijun : "+TimeCurrent());
               SendNotification(sname+" : M15+H1+H4 : Price and Chikou become UNDER Kumo/Tenkan/Kijun : "+TimeCurrent());
              }
           }

         previous_under[sindex]=true;
         previous_over[sindex]=false;

         //if (enablem1) m1_under[sindex]=false;
         if (enablem15) m15_under[sindex]=false;
         if (enableh1) h1_under[sindex]=false;
         if (enableh4) h4_under[sindex]=false;
        }
      else
        {
         // Actuel n'est pas dessous
         if(previous_under[sindex]==true)
           {
            // Actuel n'est pas dessous et précédent est dessous
           }
         else if(previous_under[sindex]==false)
           {
            // Actuel n'est pas dessous et précédent n'est pas dessous
           }
        }

      if(exportPrices)
        {
         if(file_handle>0)
           {
            for(int i=0;i<maxhisto;i++)
              {
               double t=tenkan_sen_buffer[i],k=kijun_sen_buffer[i];
               double ssa=senkou_span_a_buffer[i],ssb=senkou_span_b_buffer[i];
               double c=chikou_span_buffer[i];

               if(t==EMPTY_VALUE) t=0;
               if(k==EMPTY_VALUE) k=0;
               if(ssa==EMPTY_VALUE) ssa=0;
               if(ssb==EMPTY_VALUE) ssb=0;
               if(c==EMPTY_VALUE) c=0;

               FileWrite(file_handle,
                         string(i)
                         +";"+string(t)
                         +";"+string(k)
                         +";"+string(ssa)
                         +";"+string(ssb)
                         +";"+string(c)
                         );
              }
           }
         else
            Print("Error creating file: "+IntegerToString(GetLastError())+"");
        }
        
        //Sleep(25);
        
     } // fin boucle sur sindex (symbol index)
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