//+------------------------------------------------------------------+
//|                                           GreenRedEA.mq5 |
//|                          Copyright 2023, Invest Data Systems FR. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Invest Data Systems France."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

double bid, ask;
double previous_ask, previous_bid;
double highest_26 = 0;
double lowest_26 = 0;
datetime highest_26_datetime;
datetime lowest_26_datetime;
double previous_highest_26 = 0;
double previous_lowest_26 = 0;

int nbTicks = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   printf(TerminalInfoString(TERMINAL_PATH));
   bid = 0;
   ask = 0;
   previous_ask = 0;
   previous_bid = 0;

//EventSetMillisecondTimer(1000);

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
//| Expert tick function                                             |
//+------------------------------------------------------------------+

bool trade_done = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrade trade;
MqlRates mql_rates[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//printf("ontick");
//nbTicks++;
   if(trade_done == false)
     {
      //int Interval = 1;
      //datetime d1=TimeCurrent();
      //datetime d2=TimeCurrent()-Interval*60;

      ENUM_TIMEFRAMES periods[21]= { PERIOD_M1,  PERIOD_M2,
                                     PERIOD_M3,  PERIOD_M4,  PERIOD_M5,
                                     PERIOD_M6,  PERIOD_M10, PERIOD_M12,
                                     PERIOD_M15, PERIOD_M20, PERIOD_M30,
                                     PERIOD_H1,  PERIOD_H2,  PERIOD_H3,
                                     PERIOD_H4,  PERIOD_H6,  PERIOD_H8,
                                     PERIOD_H12, PERIOD_D1,  PERIOD_W1,
                                     PERIOD_MN1
                                   };

      bool green[21];
      bool red[21];

      int maxPeriod = 5;

      for(int i=0; i<maxPeriod; i++)
        {
         //Print("Analysed ",EnumToString(periods[i]));
         ArraySetAsSeries(mql_rates,true);
         if(CopyRates(Symbol(), periods[i], 0, 32, mql_rates)>0)
           {
            if(mql_rates[0].close > mql_rates[0].open)
              {
               //printf("Green in " + EnumToString(periods[i]));
               green[i] = true;
              }
            else
               if(mql_rates[0].close < mql_rates[0].open)
                 {
                  red[i] = true;
                 }
           }
         else
            Print("CopyRates(Symbol(), PERIOD_CURRENT, 1, 10, mql_rates). Error ", GetLastError());

        }

      bool allGreen = true;
      for(int i=0; i<maxPeriod; i++)
        {
         if(green[i] == false)
           {
            allGreen = false;
            break;
           }
        }

      if(allGreen == true)
        {
         printf("All is green");
         if(trade_done == false)
           {
            Trade_buy_2();
            trade_done = true;
           }
        }
        
      bool allRed = true;
      for(int i=0; i<maxPeriod; i++)
        {
         if(red[i] == false)
           {
            allRed = false;
            break;
           }
        }

      if(allRed == true)
        {
         printf("All is red");
         if(trade_done == false)
           {
            Trade_sell_2();
            trade_done = true;
           }
        }
      

      //done = true;

      bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);


      if(isNewBar())
        {
        }

      //ArrayFree(mql_rates);

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

double tp = 5; // take profit in %
double sl = 10; // stop loss in %
double lots = 0.1; // number of lots for each trade
MqlTick tick;
double StopLossLevel;
double TakeProfitLevel;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trade_buy_2()
  {
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
      Print("Buy() method executed successfully. Return code=", m_trade.ResultRetcode(),
            " (", m_trade.ResultRetcodeDescription(), ")");
      return;
     }

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trade_sell_2()
  {

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


//+------------------------------------------------------------------+
