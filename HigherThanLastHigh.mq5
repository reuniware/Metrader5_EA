//+------------------------------------------------------------------+
//|                                           HigherThanLastHigh.mq5 |
//|                          Copyright 2023, Invest Data Systems FR. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Invest Data Systems France."
#property link      "https://www.mql5.com"
#property version   "1.00"

double bid, ask;
double previous_ask, previous_bid;
double highest_26 = 0;
double lowest_26 = 0;
datetime highest_26_datetime;
datetime lowest_26_datetime;
double previous_highest_26 = 0;
double previous_lowest_26 = 0;
int i;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//printf(TerminalInfoString(TERMINAL_PATH));
   bid = 0;
   ask = 0;
   previous_ask = 0;
   previous_bid = 0;
   highest_26 = 0;
   lowest_26 = 0;
   highest_26_datetime = NULL;
   lowest_26_datetime = NULL;
   previous_highest_26 = 0;
   previous_lowest_26 = 0;

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
void OnTick()
  {
   if(done == false)
     {
      //int Interval = 1;
      //datetime d1=TimeCurrent();
      //datetime d2=TimeCurrent()-Interval*60;
      MqlRates mql_rates[];
      ArraySetAsSeries(mql_rates,true);
      if(CopyRates(Symbol(), PERIOD_CURRENT, 0, 32, mql_rates)>0)
        {
         //Print("mql_rates array:");
         //ArrayPrint(mql_rates);
         //printf(mql_rates[0].time);
        }
      else
         Print("CopyRates(Symbol(), PERIOD_CURRENT,1, 10, mql_rates). Error ", GetLastError());

      //done = true;

      bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

      highest_26 = 0;
      lowest_26 = 0x6FFFFFFF;
      for(i=1; i<27; i++)
        {
         if(mql_rates[i].high > highest_26)
           {
            highest_26 = mql_rates[i].high;
            highest_26_datetime = mql_rates[i].time;
           }
         if(mql_rates[i].low < lowest_26)
           {
            lowest_26 = mql_rates[i].low;
            lowest_26_datetime = mql_rates[i].time;
           }
        }

      if(highest_26 != previous_highest_26)
        {
         printf("new current highest 26 = " + highest_26 + " at " + highest_26_datetime);
         previous_highest_26 = highest_26;
        }

      if(lowest_26 != previous_lowest_26)
        {
         printf("new current lowest 26 = " + lowest_26 + " at " + lowest_26_datetime);
         previous_lowest_26 = lowest_26;
        }

      if(previous_bid < highest_26 && bid > highest_26)
        {
         printf("bid has got above highest (" + highest_26 + ") on 26 candlesticks. current bid = " + bid);
         PlaySound("alert.wav");
        }

      if(previous_bid > lowest_26 && bid < lowest_26)
        {
         printf("bid has got below lowest (" + lowest_26 + ") on 26 candlesticks. current bid= " + bid);
         PlaySound("alert.wav");
        }

      previous_ask = ask;
      previous_bid = bid;

      if(previous_highest_26 == 0)
        {
         previous_highest_26 = highest_26;
         printf("current highest 26 = " + highest_26);
        }
      if(previous_lowest_26 == 0)
        {
         previous_lowest_26 = lowest_26;
         printf("current lowest 26 = " + lowest_26);
        }

      //done = true;
      //ArrayFree(high_array);
      //ArrayFree(low_array);
      //ArrayFree(close_array);

      int tenkan_sen = 9;              // period of Tenkan-sen
      int kijun_sen = 26;              // period of Kijun-sen
      int senkou_span_b = 52;          // period of Senkou Span B

      double tenkan_sen_bufferM1[];
      double kijun_sen_bufferM1[];
      double senkou_span_a_bufferM1[];
      double senkou_span_b_bufferM1[];
      double chikou_span_bufferM1[];

      ArraySetAsSeries(tenkan_sen_bufferM1,true);
      ArraySetAsSeries(kijun_sen_bufferM1,true);
      ArraySetAsSeries(senkou_span_a_bufferM1,true);
      ArraySetAsSeries(senkou_span_b_bufferM1,true);
      ArraySetAsSeries(chikou_span_bufferM1,true);

      int max = 64;
      int handleM1;
      handleM1 = iIchimoku(Symbol(), PERIOD_CURRENT, tenkan_sen, kijun_sen, senkou_span_b);
      if(handleM1 != INVALID_HANDLE)
        {
         int nbt=-1,nbk=-1,nbssa=-1,nbssb=-1,nbc=-1;
         nbt = CopyBuffer(handleM1, TENKANSEN_LINE, 0, max, tenkan_sen_bufferM1);
         nbk = CopyBuffer(handleM1, KIJUNSEN_LINE, 0, max, kijun_sen_bufferM1);
         nbssa = CopyBuffer(handleM1, SENKOUSPANA_LINE, 0, max, senkou_span_a_bufferM1);
         nbssb = CopyBuffer(handleM1, SENKOUSPANB_LINE, 0, max, senkou_span_b_bufferM1);
         nbc=CopyBuffer(handleM1, CHIKOUSPAN_LINE, 0, max, chikou_span_bufferM1);

         if(nbk > 0)
           {
            //ArrayPrint(kijun_sen_bufferM1);
            //ArrayPrint(mql_rates);
            //printf("KS = " + kijun_sen_bufferM1[0]);
            if(isNewBar())
              {
               if(mql_rates[1].open > kijun_sen_bufferM1[1])
                  if(mql_rates[1].close < kijun_sen_bufferM1[1])
                     printf("Price has got below its kijun sen");

               if(mql_rates[1].open < kijun_sen_bufferM1[1])
                  if(mql_rates[1].close > kijun_sen_bufferM1[1])
                     printf("Price has got above its kijun sen");

               // Measuring percentages of high of low wicks and if higher wick is greatest that lower wick then
               // assuming than there is a higher probability of going down and if lower wick is greatest than higher wick
               // then assuming than there is a higher probability of going up... Measurements on the previous candlestick.
               if(mql_rates[1].open > mql_rates[1].close)
                 {
                  //bougie verte
                  double diff_high_close = ((mql_rates[1].high - mql_rates[1].close)/mql_rates[1].close)*100;
                  double diff_open_low = ((mql_rates[1].open - mql_rates[1].low)/mql_rates[1].low)*100;
                  printf("previous diff between high and close = " + string(diff_high_close));
                  printf("previous diff between open and low = " + string(diff_open_low));
                  if(diff_high_close > diff_open_low)
                     printf("higher probability of price going down");
                  else
                     printf("higher probability of price going up");
                 }
               else
                  if(mql_rates[1].close > mql_rates[1].open)
                    {
                     //bougie rouge
                     double diff_high_open = ((mql_rates[1].high - mql_rates[1].open)/mql_rates[1].open)*100;
                     double diff_close_low = ((mql_rates[1].close - mql_rates[1].low)/mql_rates[1].low)*100;
                     printf("previous diff between high and open = " + string(diff_high_open));
                     printf("previous diff between close and low = " + string(diff_close_low));
                     if(diff_high_open > diff_close_low)
                        printf("higher probability of price going down");
                     else
                        printf("higher probability of price going up");
                    }

              }


           }

        }

      if(isNewBar())
        {
        }

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

bool trade_done = false;
void Trade()
  {
   if(trade_done == true)
      return;

   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
   request.action    =TRADE_ACTION_DEAL;
   request.symbol    =Symbol();
   request.volume    =1;
   request.type      =ORDER_TYPE_BUY;
   request.price     =ask;
   request.deviation=10;
   request.magic     =123456;
   request.sl = ask - ask/100*0.1;
   request.tp = ask + ask/100*0.5;
   request.type_filling    =ORDER_FILLING_IOC;
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);

//trade_done = true;
  }
