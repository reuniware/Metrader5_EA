//+------------------------------------------------------------------+
//|                                                IchimokuEA008.mq5 |
//|                          Copyright 2023, Invest Data Systems FR. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, Invest Data Systems France."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

double bid, ask;

input bool enableTrading = true;

CTrade trade;
MqlRates mql_rates[];
double tenkan_sen_buffer[];
double kijun_sen_buffer[];
double senkou_span_a_buffer[];
double senkou_span_b_buffer[];
double chikou_span_buffer[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   printf(TerminalInfoString(TERMINAL_PATH));
   ArraySetAsSeries(mql_rates, true);
   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

datetime dtRef;

bool done = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPositionInfo cpositioninfo;
void OnTick()
  {
//printf("ontick");

   /*
   // Fermeture des positions pour le cas où on ne définit pas le SL et TP dans l'ouverture du trade.
   // Le comportement n'est pas le même qu'avec les mêmes valeurs définies dans l'ouverture du trade (.008 et 0.002)...
   bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   for(int j = PositionsTotal() - 1; j >= 0; j--) // loop all Open Positions
      if(m_position.SelectByIndex(j))  // select a position
        {
        //printf("position ticket = " + string(m_position.Ticket()));
         if(bid/m_position.PriceOpen()>=0.008)
           {
            m_trade_2.PositionClose(m_position.Ticket()); // then delete it --period
           }
         if(bid/m_position.PriceOpen()<=0.002)
           {
            m_trade_2.PositionClose(m_position.Ticket()); // then delete it --period
           }
        }*/

   if(isNewBar() == false)
      return;

   if(CopyRates(Symbol(), PERIOD_CURRENT, 0, 32, mql_rates)>0)
     {
     }
   else
      Print("CopyRates(Symbol(), PERIOD_CURRENT,1, 10, mql_rates). Error ", GetLastError());

   double Highest26 = 0;
   for(int i=1; i<27; i++)
     {
      if(mql_rates[i].high > Highest26)
         Highest26 = mql_rates[i].high;
     }
   double Lowest26 = 0x6FFFFFFF;
   for(int i=1; i<27; i++)
     {
      if(mql_rates[i].low < Lowest26)
         Lowest26 = mql_rates[i].low;
     }

//done = true;

   bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

   int tenkan_sen = 9;              // period of Tenkan-sen
   int kijun_sen = 26;              // period of Kijun-sen
   int senkou_span_b = 52;          // period of Senkou Span B

   int max = 64;
   int handle;
   handle = iIchimoku(Symbol(), PERIOD_CURRENT, tenkan_sen, kijun_sen, senkou_span_b);
   if(handle != INVALID_HANDLE)
     {
      int nbt = -1, nbk = -1, nbssa = -1, nbssb = -1, nbc = -1;
      nbt = CopyBuffer(handle, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
      nbk = CopyBuffer(handle, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
      nbssa = CopyBuffer(handle, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
      nbssb = CopyBuffer(handle, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
      nbc = CopyBuffer(handle, CHIKOUSPAN_LINE, 0, max, chikou_span_buffer);

      if(nbk > 0)
        {
         //ArrayPrint(kijun_sen_buffer);
         //ArrayPrint(mql_rates);
         //printf("KS = " + kijun_sen_buffer[0]);

         // Condition codée dans IchimokuEA003 : Il faut que la bougie n-3 ne soit pas au-dessus de tous ses niveaux
         // Condition codée par erreur dans IchimokuEA004 :
         //    Erreur dans 1ère condition suivante, j'aurai dû mettre un "!" mais apparemment ça fonctionne mieux comme ça (!!)
         //    Donc => Si bougies n-3 et n-2 au-dessus de tous leurs niveaux ET leurs Chikou Span idem
         if(/*(mql_rates[0].close > Highest26) &&*/
            ((mql_rates[2].close > senkou_span_b_buffer[2] && mql_rates[2].close > senkou_span_a_buffer[2]))
            &&(mql_rates[1].close > senkou_span_b_buffer[1] && mql_rates[1].close > senkou_span_a_buffer[1]))
           {
            printf("Is above the cloud SSB and SSA");
            printf("chikou span =" + string(chikou_span_buffer[26]) + " at " + string(mql_rates[27].time));
            printf("senkou span b cs=" + string(senkou_span_b_buffer[26]));
            printf("senkou span a cs=" + string(senkou_span_a_buffer[27]));
            printf("tenkan cs=" + string(tenkan_sen_buffer[27]));
            printf("kijun cs=" + string(kijun_sen_buffer[26]));

            double cs = chikou_span_buffer[26];
            double ssb_cs = senkou_span_b_buffer[26];
            double ssa_cs = senkou_span_a_buffer[27];
            double tenkan_cs = tenkan_sen_buffer[27];
            double kijun_cs = kijun_sen_buffer[26];

            if(cs > ssb_cs && cs > ssa_cs && cs > tenkan_cs && cs > kijun_cs)
              {
               printf("chikou span est validée sur la bougie de " + string(mql_rates[27].time));

               printf("ssb bougie précédente de [" + string(mql_rates[1].time) + "] = " + string(senkou_span_b_buffer[1]));
               printf("ssa bougie précédente de [" + string(mql_rates[1].time) + "] = " + string(senkou_span_a_buffer[1]));
               printf("tenkan bougie précédente de [" + string(mql_rates[1].time) + "] = " + string(tenkan_sen_buffer[1]));
               printf("kijun bougie précédente de [" + string(mql_rates[1].time) + "] = " + string(kijun_sen_buffer[1]));

               double close = mql_rates[1].close;
               double ssa = senkou_span_a_buffer[1];
               double ssb = senkou_span_b_buffer[1];
               double tenkan = tenkan_sen_buffer[1];
               double kijun = kijun_sen_buffer[1];

               /*// Calcul de la distance avec la tenkan sen
               double diff = mql_rates[0].close - tenkan_sen_buffer[0];
               printf("Diff Close0-Tenkan0 = " + string(diff));
               double diffpercent = (mql_rates[0].close - tenkan_sen_buffer[0])/tenkan_sen_buffer[0] * 100;
               printf("Diff in % = " + string(diffpercent));*/

               //if(diffpercent > 0 && diffpercent < 0.02)
               //{

               if(close > ssa && close > ssb /*&& close > tenkan*/ && close > kijun)
                 {
                  printf("le prix est validé sur la bougie de " + string(mql_rates[1].time));

                  // Ici entrée en position (todo: checker les lignes sur UTs supérieures)
                  Trade_buy_2();
                  PlaySound("alert.wav");

                 }

               //}

              }
           }

         // Nouveau condition ajoutée dans IchimokuEA005
         if(/*(mql_rates[0].close < Lowest26) &&*/
            ((mql_rates[2].close < senkou_span_b_buffer[2] && mql_rates[2].close < senkou_span_a_buffer[2]))
            &&(mql_rates[1].close < senkou_span_b_buffer[1] && mql_rates[1].close < senkou_span_a_buffer[1]))
           {
            printf("Is below the cloud SSB and SSA");
            printf("chikou span =" + string(chikou_span_buffer[26]) + " at " + string(mql_rates[27].time));
            printf("senkou span b cs=" + string(senkou_span_b_buffer[26]));
            printf("senkou span a cs=" + string(senkou_span_a_buffer[27]));
            printf("tenkan cs=" + string(tenkan_sen_buffer[27]));
            printf("kijun cs=" + string(kijun_sen_buffer[26]));

            double cs = chikou_span_buffer[26];
            double ssb_cs = senkou_span_b_buffer[26];
            double ssa_cs = senkou_span_a_buffer[27];
            double tenkan_cs = tenkan_sen_buffer[27];
            double kijun_cs = kijun_sen_buffer[26];

            if(cs < ssb_cs && cs < ssa_cs && cs < tenkan_cs && cs < kijun_cs)
              {
               printf("chikou span est validée sur la bougie de " + string(mql_rates[27].time));

               printf("ssb bougie précédente de [" + string(mql_rates[1].time) + "] = " + string(senkou_span_b_buffer[1]));
               printf("ssa bougie précédente de [" + string(mql_rates[1].time) + "] = " + string(senkou_span_a_buffer[1]));
               printf("tenkan bougie précédente de [" + string(mql_rates[1].time) + "] = " + string(tenkan_sen_buffer[1]));
               printf("kijun bougie précédente de [" + string(mql_rates[1].time) + "] = " + string(kijun_sen_buffer[1]));

               double close = mql_rates[1].close;
               double ssa = senkou_span_a_buffer[1];
               double ssb = senkou_span_b_buffer[1];
               double tenkan = tenkan_sen_buffer[1];
               double kijun = kijun_sen_buffer[1];

               /*// Calcul de la distance avec la tenkan sen
               double diff = mql_rates[0].close - tenkan_sen_buffer[0];
               printf("Diff Close0-Tenkan0 = " + string(diff));
               double diffpercent = (mql_rates[0].close - tenkan_sen_buffer[0])/tenkan_sen_buffer[0] * 100;
               printf("Diff in % = " + string(diffpercent));*/

               //if(diffpercent < 0 && diffpercent > -0.02)
               //{
               if(close < ssa && close < ssb && close < tenkan && close < kijun)
                 {
                  printf("le prix est validé sur la bougie de " + string(mql_rates[1].time));

                  // Ici entrée en position (todo: checker les lignes sur UTs supérieures)
                  Trade_sell_2();
                  PlaySound("alert.wav");

                 }
               //}

              }
           }



         /*if(chikou_span_buffer[25] > mql_rates[27].high)
           {
            printf("chikou span is greater than high price at " + string(mql_rates[27].time));
            printf("cs=" + string(chikou_span_buffer[26]) + " high=" + string(mql_rates[27].high));
            printf("current candlestick time=" + string(mql_rates[0].time));
           }*/


        }

      ArrayFree(senkou_span_b_buffer);
      ArrayFree(senkou_span_a_buffer);
      ArrayFree(tenkan_sen_buffer);
      ArrayFree(kijun_sen_buffer);
      ArrayFree(chikou_span_buffer);
      ArrayFree(mql_rates);


     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Returns true if a new bar has appeared for a symbol/period pair  |
//+------------------------------------------------------------------+
bool isNewBar()
  {
//printf("isnewbar function");
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);

//printf(string(last_time));

//printf(string(last_time));

//--- if it is the first call of the function
   if(last_time==0)
     {
      //--- set the time and exit
      last_time=lastbar_time;
      return(false);
     }

//--- if the time differs
   if(last_time!=lastbar_time)
     {
      //printf("is a new bar");
      //--- memorize the time and return true
      last_time=lastbar_time;
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
  }

//+------------------------------------------------------------------+


CTrade         m_trade;                      // object of CTrade class

//Darwinex-Demo GDAXI 0.05 Lots (capital 500€)
input double lots = 0.05; // number of lots for each trade
input double SL_POINTS = 0;//56;
input double TP_POINTS = 0;//1391;

MqlTick tick;
double StopLossLevel;
double TakeProfitLevel;

//bool trade_done = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trade_buy_2()
  {
   if(enableTrading == false)
      return;

   if(PositionsTotal()>0)
      return;

//if(trade_done == true)
//return;

   if(!SymbolInfoTick(Symbol(),tick))
     {
      Alert(__FUNCTION__,", ERROR SymbolInfoTick");
      return;
     }

   double Price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double SLPoint = SL_POINTS * point;
   double TPPoint = TP_POINTS * point;
   double Stop_Loss = 0;
   if(SLPoint > 0)
     {
      Stop_Loss = Price - SLPoint;
     }
   double Take_Profit = 0;
   if(TPPoint > 0)
     {
      Take_Profit = Price + TPPoint;
     }

   StopLossLevel = Stop_Loss;
   TakeProfitLevel = Take_Profit;

   if(!m_trade.Buy(lots, Symbol(), tick.ask, StopLossLevel, TakeProfitLevel))
     {
      //--- failure message
      Print("Buy() method failed. Return code=", m_trade.ResultRetcode(),
            ". Code description: ", m_trade.ResultRetcodeDescription());
      return;
     }
   else
     {
      Print("Buy() method executed successfully. Return code=", m_trade.ResultRetcode()," (", m_trade.ResultRetcodeDescription(), ")");
      //trade_done = true;
      return;
     }

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trade_sell_2()
  {
   if(enableTrading == false)
      return;

   if(PositionsTotal()>0)
      return;

   if(!SymbolInfoTick(Symbol(),tick))
     {
      Alert(__FUNCTION__,", ERROR SymbolInfoTick");
      return;
     }

   double Price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double SLPoint = SL_POINTS * point;
   double TPPoint = TP_POINTS * point;
   double Stop_Loss = 0;
   if(Stop_Loss > 0)
     {
      double Stop_Loss = Price + SLPoint;
     }
   double Take_Profit = 0;
   if(Take_Profit > 0)
     {
      Take_Profit = Price - TPPoint;
     }

   StopLossLevel = Stop_Loss;
   TakeProfitLevel = Take_Profit;

   if(!m_trade.Sell(lots, Symbol(), tick.ask, StopLossLevel, TakeProfitLevel))
     {
      //--- failure message
      Print("Sell() method failed. Return code=", m_trade.ResultRetcode(),
            ". Code description: ", m_trade.ResultRetcodeDescription());
      return;
     }
   else
     {
      Print("Sell() method executed successfully. Return code=", m_trade.ResultRetcode(),
            " (", m_trade.ResultRetcodeDescription(), ")");
      return;
     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrade         m_trade_2;                      // object of CTrade class
CPositionInfo  m_position; // Library for all position features and information

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int j = PositionsTotal() - 1; j >= 0; j--) // loop all Open Positions
      if(m_position.SelectByIndex(j))  // select a position
        {
         m_trade_2.PositionClose(m_position.Ticket()); // then delete it --period
         Sleep(100); // Relax for 100 ms
         //ChartWrite("Positions", "Positions " + (string)PositionsTotal(), 100, 80, 20, PositionsColor); //Re write number of positions on the chart
        }
  }


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
