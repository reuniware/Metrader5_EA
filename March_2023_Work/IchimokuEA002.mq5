//+------------------------------------------------------------------+
//|                                                IchimokuEA002.mq5 |
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
//printf(TerminalInfoString(TERMINAL_PATH));
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
void OnTick()
  {

   if(isNewBar() == false)
      return;

   if(CopyRates(Symbol(), PERIOD_CURRENT, 0, 32, mql_rates)>0)
     {
     }
   else
      Print("CopyRates(Symbol(), PERIOD_CURRENT,1, 10, mql_rates). Error ", GetLastError());

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

         if(mql_rates[1].open < senkou_span_b_buffer[1] && mql_rates[1].close > senkou_span_b_buffer[1])
           {
            printf("getting above the cloud");
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
               double tenkan = senkou_span_b_buffer[1];
               double kijun = kijun_sen_buffer[1];

               if(close > ssa && close > ssb && close > tenkan && close > kijun)
                 {
                  printf("le prix est validé sur la bougie de " + string(mql_rates[1].time));

                  // Ici entrée en position (todo: checker les lignes sur UTs supérieures)
                  Trade_buy_2();

                 }

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
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);

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
      //--- memorize the time and return true
      last_time=lastbar_time;
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
  }

//+------------------------------------------------------------------+


CTrade         m_trade;                      // object of CTrade class

double tp = 0.5; // take profit in %
double sl = 0.5; // stop loss in %
double lots = 0.1; // number of lots for each trade
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

//if(trade_done == true)
//return;

   if(!SymbolInfoTick(Symbol(),tick))
     {
      Alert(__FUNCTION__,", ERROR SymbolInfoTick");
      return;
     }

   StopLossLevel = tick.bid - (tick.bid/100*sl);
   TakeProfitLevel = tick.ask + (tick.ask/100*tp);

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

   if(!SymbolInfoTick(Symbol(),tick))
     {
      Alert(__FUNCTION__,", ERROR SymbolInfoTick");
      return;
     }

   StopLossLevel = tick.ask + (tick.ask/100*sl);
   TakeProfitLevel = tick.bid - (tick.bid/100*tp);

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


