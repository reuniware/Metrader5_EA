//+------------------------------------------------------------------+
//|                                           PumpsAndDumpsEA003.mq5 |
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
double previous_bid = 0;
double evol = 0;
bool show_value_after = true;
double greatest_dump = 0;
double greatest_pump = 0;
double pump_dump_trigger = 14; // 15 usd between 2 ticks is a strong move on BTCUSD on 21 03 2023 in the evening around 10pm UTC+2
bool show_pump_and_dump = true;
MqlRates mql_rates[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(done == false)
     {
      double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

      if(previous_ask>0 && ask!=previous_ask)
        {
         //evol = (ask - previous_ask)/previous_ask*100;
         evol = ask - previous_ask;
         if(show_value_after == true)
           {
            if(show_pump_and_dump)
               printf("THEN = " + evol + " (" + string(ask) + ")");
            show_value_after = false;
           }
         if(evol >= pump_dump_trigger || evol < -pump_dump_trigger)
           {
            if(evol > 0)
              {
               PlaySound("alert.wav");
               if(show_pump_and_dump)
                  printf("PUMP = " + evol + " (" + string(ask) + ")");
               if(evol > greatest_pump)
                 {
                  greatest_pump = evol;
                  printf("New Greatest Pump = " + greatest_pump + " (" + string(ask) + ")");
                  //PlaySound("alert.wav");
                 }
              }
            else
               if(evol < 0)
                 {
                  PlaySound("alert.wav");
                  if(show_pump_and_dump)
                     printf("DUMP = " + evol + " (" + string(ask) + ")");
                  if(evol < greatest_dump)
                    {
                     greatest_dump = evol;
                     printf("New Greatest Dump = " + greatest_dump + " (" + string(ask) + ")");
                    }
                 }
            show_value_after = true;
           }
         else
           {
            show_value_after = false;
           }
           
         ArrayFree(mql_rates);
         ArraySetAsSeries(mql_rates,true);
         if(CopyRates(Symbol(), PERIOD_CURRENT, 0, 32, mql_rates)>0)
           {
            if(previous_bid >= mql_rates[1].low && bid <= mql_rates[1].low)
              {
               PlaySound("alert2.wav");
               printf("current price is getting below previous candlestick's low");
              }
            if(previous_bid <= mql_rates[1].high && bid >= mql_rates[1].high)
              {
               PlaySound("alert2.wav");
               printf("current price is gettig above previous candlestick's high");
              }
           }

        }

      if(isNewBar())
        {
         /*printf("New japanese candlestick");
         greatest_dump = 0;
         greatest_pump = 0;*/
        }

      previous_ask = ask;
      previous_bid = bid;
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
Samples for high volatility days

2023.03.21 22:09:20.059 PumpsAndDumpsEA (BTCUSDT.cr,M15) New Greatest Pump = 16.270000000000437 (28053.58)
2023.03.21 22:34:38.422 PumpsAndDumpsEA (BTCUSDT.cr,M5) New Greatest Pump = 16.400000000001455 (28016.15)
2023.03.21 22:37:58.219 PumpsAndDumpsEA (BTCUSDT.cr,M15) New Greatest Pump = 20.029999999998836 (27921.36)

2023.03.22 13:05:47.992	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Dump = -4.229999999999563 (28130.0)
2023.03.22 13:05:48.023	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Pump = 4.009999999998399 (28134.01)
2023.03.22 13:08:43.755	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Pump = 5.080000000001746 (28119.99)
2023.03.22 13:09:15.478	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Pump = 5.770000000000437 (28140.19)
2023.03.22 13:09:15.528	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Dump = -5.770000000000437 (28134.42)
2023.03.22 13:09:45.988	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Pump = 9.859999999996944 (28169.85)
2023.03.22 13:09:46.118	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Dump = -6.270000000000437 (28169.85)
2023.03.22 13:12:27.068	PumpsAndDumpsEA (BTCUSDT.cr,M15)	New Greatest Dump = -6.619999999998981 (28160.43)
2023.03.22 13:19:24.883	PumpsAndDumpsEA (BTCUSDT.cr,M15)	New Greatest Pump = 7.380000000001019 (28216.99)
2023.03.22 13:19:25.795	PumpsAndDumpsEA (BTCUSDT.cr,M15)	New Greatest Pump = 11.369999999998981 (28230.36)
2023.03.22 13:19:25.835	PumpsAndDumpsEA (BTCUSDT.cr,M15)	New Greatest Dump = -11.369999999998981 (28218.99)
2023.03.22 13:22:23.066	PumpsAndDumpsEA (BTCUSDT.cr,H4)	New Greatest Pump = 12.43999999999869 (28197.82)
2023.03.22 15:53:54.731	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Pump = 5.319999999999709 (28550.87)
2023.03.22 15:54:22.550	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Pump = 14.529999999998836 (28603.37)
2023.03.22 15:54:31.531	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Dump = -8.220000000001164 (28605.32)
2023.03.22 15:57:59.459	PumpsAndDumpsEA (BTCUSDT.cr,M5)	New Greatest Dump = -10.389999999999418 (28609.65)
2023.03.22 16:00:30.229	PumpsAndDumpsEA (BTCUSDT.cr,M15)	New Greatest Pump = 14.119999999998981 (28613.12)
2023.03.22 16:04:14.251	PumpsAndDumpsEA (BTCUSDT.cr,M15)	New Greatest Dump = -19.639999999999418 (28632.98)
2023.03.22 16:05:28.378	PumpsAndDumpsEA (BTCUSDT.cr,M15)	New Greatest Pump = 14.330000000001746 (28665.2)
2023.03.22 16:50:12.056	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Pump = 16.790000000000873 (28490.5)
2023.03.22 16:53:44.462	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Pump = 18.200000000000728 (28580.57)
2023.03.22 16:53:44.509	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Dump = -18.200000000000728 (28562.37)
2023.03.22 16:53:51.259	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Pump = 20.69999999999709 (28595.1)
2023.03.22 18:21:32.025	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Dump = -32.70999999999913 (28440.08)
2023.03.22 18:33:43.070	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Dump = -15.0099999999984 (28334.99)
2023.03.22 18:55:18.103	PumpsAndDumpsEA (BTCUSDT.cr,H4)	New Greatest Pump = 14.779999999998836 (28432.25)
2023.03.22 18:58:39.598	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Pump = 16.140000000003056 (28540.4)
2023.03.22 18:58:57.806	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Dump = -16.459999999999127 (28513.86)
2023.03.22 19:00:08.341	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Pump = 18.30000000000291 (28496.65)
2023.03.22 19:00:18.515	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Dump = -23.11999999999898 (28655.0)
2023.03.22 19:00:21.004	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Pump = 42.04999999999927 (28652.05)
2023.03.22 19:00:33.480	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Dump = -34.91000000000349 (28808.42)
2023.03.22 19:00:37.590	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Pump = 71.31999999999971 (28771.32)
2023.03.22 19:00:38.963	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Dump = -44.340000000000146 (28742.8)
2023.03.22 19:29:05.621	PumpsAndDumpsEA (BTCUSDT.cr,M5)	New Greatest Dump = -14.479999999999563 (28500.94)
2023.03.22 19:29:05.663	PumpsAndDumpsEA (BTCUSDT.cr,M5)	New Greatest Pump = 14.479999999999563 (28515.42)
2023.03.22 19:31:45.413	PumpsAndDumpsEA (BTCUSDT.cr,M5)	New Greatest Pump = 16.520000000000437 (28565.88)
2023.03.22 19:32:41.397	PumpsAndDumpsEA (BTCUSDT.cr,M1)	New Greatest Dump = -22.389999999999418 (28451.82)
2023.03.22 19:35:48.641	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Dump = -43.580000000001746 (28143.6)
2023.03.22 19:35:48.641	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Pump = 17.110000000000582 (28160.71)
2023.03.22 19:35:51.601	PumpsAndDumpsEA (BTCUSDT.cr,M3)	New Greatest Dump = -60.2599999999984 (28002.34)
2023.03.22 19:35:51.749	PumpsAndDumpsEA (BTCUSDT.cr,M5)	New Greatest Pump = 55.38000000000102 (28057.72)

ON 2023.03.22 :
19:00 USD		FOMC Economic Projections
 	 	  USD		FOMC Statement
 	 	  USD		Federal Funds Rate   5.00%	5.00%	4.75%	
19:30 USD		FOMC Press Conference

*/
