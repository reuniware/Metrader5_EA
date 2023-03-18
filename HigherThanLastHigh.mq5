//+------------------------------------------------------------------+
//|                                           HigherThanLastHigh.mq5 |
//|                          Copyright 2023, Invest Data Systems FR. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Invest Data Systems France."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//printf(TerminalInfoString(TERMINAL_PATH));
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
bool done = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//double previous_ask = 0;
double evol = 0;
bool show_value_after = false;
double greatest_dump = 0;
double greatest_pump = 0;
double pump_dump_trigger = 0.001;
bool show_pump_and_dump = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int numO, numH, numL, numC;
double bid, ask;
double open_array[];
double high_array[];
double low_array[];
double close_array[];
double previous_ask, previous_bid;
double highest_26 = 0;
double lowest_26 = 0;
void OnTick()
  {
   if(done == false)
     {
      // CopyOpen copies bid prices
      ArraySetAsSeries(open_array, true);
      numO=CopyOpen(Symbol(), PERIOD_CURRENT, 0, 32, open_array);
      ArraySetAsSeries(high_array, true);
      numH=CopyOpen(Symbol(), PERIOD_CURRENT, 0, 32, high_array);
      ArraySetAsSeries(low_array, true);
      numL=CopyOpen(Symbol(), PERIOD_CURRENT, 0, 32, low_array);
      ArraySetAsSeries(close_array, true);
      numC=CopyOpen(Symbol(), PERIOD_CURRENT, 0, 32, close_array);

      /*printf("open 0 = " + open_array[0]);
      printf("open 1 = " + open_array[1]);
      printf("open 2 = " + open_array[2]);*/

      bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

      highest_26 = 0;
      lowest_26 = 0x6FFFFFFF;
      for(int i=0; i<26; i++)
        {
         if(high_array[i] > highest_26)
           {
            highest_26 = high_array[i];
           }
         if(low_array[i] < lowest_26)
           {
            lowest_26 = low_array[i];
           }
        }

      if(previous_bid < highest_26 && bid > highest_26)
        {
         printf("bid has got above highest on 26 candlesticks. current bid = " + bid);
         PlaySound("alert.wav");
        }

      if(previous_bid > lowest_26 && bid < lowest_26)
        {
         printf("bid has got below lowest on 26 candlesticks. current bid= " + bid);
         PlaySound("alert.wav");
        }

      previous_ask = ask;
      previous_bid = bid;

      //done = true;
      ArrayFree(open_array);
      ArrayFree(high_array);
      ArrayFree(low_array);
      ArrayFree(close_array);
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
