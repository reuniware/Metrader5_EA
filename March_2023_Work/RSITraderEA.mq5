//+------------------------------------------------------------------+
//|                                                  RSITraderEA.mq5 |
//|                          Copyright 2023, Invest Data Systems FR. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
// GBPUSD 5m 01 03 2023 - 23 03 2023 Capital 500 Profit total net 171 tp = 0.00100 sl = 0.00100
// GBPUSD 5m 01 01 2023 - 23 03 2023 Capital 500 Profit total net 177 tp = 0.00100 sl = 0.00100
// USDCHF h4 01 01 2023 - 23 03 2023 Capital 500 Profit total net 416 tp = 0.01000 sl = 0.01000
// EURUSD h4 01 01 2023 - 23 03 2023 Capital 500 Profit total net 127 tp = 0.01000 sl = 0.01000
// EURUSD h4 01 01 2023 - 23 03 2023 Capital 500 Profit total net 177 tp = 0.00500 sl = 0.00500
// EURUSD h4 01 01 2023 - 23 03 2023 Capital 500 Profit total net 62  tp = 0.00250 sl = 0.00250


#property copyright "Copyright 2023, Invest Data Systems France."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

double bid, ask;
double previous_ask, previous_bid;

int nbTicks = 0;

input bool trading_enabled = false;

string status = "none";
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
      //done = true;

      bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

      ArrayFree(mql_rates);

      double RSIArray[];
      int RSIDef = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
      ArraySetAsSeries(RSIArray,true);
      CopyBuffer(RSIDef,0,0,1,RSIArray);
      double RSIValue = NormalizeDouble(RSIArray[0],2);
      Comment("RSI Value is ",RSIValue);

      if(isNewBar())
        {
         if(RSIValue<=30)
           {
            CloseAllPositions();
            Trade_buy_2();
           }
         if(RSIValue>=70)
           {
            CloseAllPositions();
            Trade_sell_2();
           }
        }


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
double lots = 0.1;// number of lots for each trade
MqlTick tick;
double StopLossLevel;
double TakeProfitLevel;
input double sl_points = 0.00100;
input double tp_points = 0.00100;

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

   StopLossLevel = tick.bid - sl_points;//  0.00100;//(tick.bid/100*sl);
   TakeProfitLevel = tick.ask + tp_points;//0.00010;//(tick.ask/100*tp);

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

   StopLossLevel = tick.ask + sl_points;// 0.00100;//(tick.ask/100*sl);
   TakeProfitLevel = tick.bid - tp_points;// 0.00010;//(tick.bid/100*tp);

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
