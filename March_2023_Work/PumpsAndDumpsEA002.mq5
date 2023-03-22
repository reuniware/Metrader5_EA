//+------------------------------------------------------------------+
//|                                           PumpsAndDumpsEA002.mq5 |
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
//---
//---
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
double previous_ask = 0;
double evol = 0;
bool show_value_after = true;
double greatest_dump = 0;
double greatest_pump = 0;
double pump_dump_trigger = 15; // 15 usd between 2 ticks is a strong move on BTCUSD on 21 03 2023 in the evening around 10pm UTC+2
bool show_pump_and_dump = true;
void OnTick()
  {
//---
   if(done == false)
     {
      double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      
      if (previous_ask>0 && ask!=previous_ask) {
         //evol = (ask - previous_ask)/previous_ask*100;
         evol = ask - previous_ask;
         if (show_value_after == true) {
            if (show_pump_and_dump) printf("THEN = " + evol + " (" + string(ask) + ")");
            show_value_after = false;
         }
         if (evol >= pump_dump_trigger || evol < -pump_dump_trigger) {
            if (evol > 0) {
               PlaySound("alert.wav");
               if (show_pump_and_dump) printf("PUMP = " + evol + " (" + string(ask) + ")");
               if (evol > greatest_pump) {
                  greatest_pump = evol;
                  printf("New Greatest Pump = " + greatest_pump + " (" + string(ask) + ")");
                  //PlaySound("alert.wav");
               }
            } else if (evol < 0) {
               PlaySound("alert.wav");
               if (show_pump_and_dump) printf("DUMP = " + evol + " (" + string(ask) + ")");
               if (evol < greatest_dump) {
                  greatest_dump = evol;
                  printf("New Greatest Dump = " + greatest_dump + " (" + string(ask) + ")");
               }
            }
            show_value_after = true;
         } else {
            show_value_after = false;
         }
      }
      
      if (isNewBar()) {
         /*printf("New japanese candlestick");
         greatest_dump = 0;
         greatest_pump = 0;*/
      }
      
      previous_ask = ask;
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


/*
2023.03.21 22:09:20.059	PumpsAndDumpsEA (BTCUSDT.cr,M15)  New Greatest Pump = 16.270000000000437 (28053.58)
2023.03.21 22:34:38.422	PumpsAndDumpsEA (BTCUSDT.cr,M5)	  New Greatest Pump = 16.400000000001455 (28016.15)
2023.03.21 22:37:58.219	PumpsAndDumpsEA (BTCUSDT.cr,M15)  New Greatest Pump = 20.029999999998836 (27921.36)
*/
