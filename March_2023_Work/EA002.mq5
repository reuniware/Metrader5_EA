//+------------------------------------------------------------------+
//|                                           HigherThanLastHigh.mq5 |
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
CTrade trade;
void OnTick()
  {
   /*if(PositionSelect(Symbol()))
     {
      if(PositionGetDouble(POSITION_PROFIT) > 5 || PositionGetDouble(POSITION_PROFIT) > 5)
        {
         trade.PositionClose(Symbol());
        }
     }*/

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
      
      // Si le prix passe sous le plus bas précédent et repasse au-dessus du plus bas précédent
      if (previous_bid < mql_rates[1].low && bid > mql_rates[1].low) {
         Trade_buy_2();
      }
      
      if (previous_bid > mql_rates[1].high && bid < mql_rates[1].high) {
         Trade_sell_2();
      }


      bool showHighestsAndLowests = false; /********/

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
         if(showHighestsAndLowests)
            printf("new current highest 26 = " + highest_26 + " at " + highest_26_datetime);
         previous_highest_26 = highest_26;
        }

      if(lowest_26 != previous_lowest_26)
        {
         if(showHighestsAndLowests)
            printf("new current lowest 26 = " + lowest_26 + " at " + lowest_26_datetime);
         previous_lowest_26 = lowest_26;
        }

      if(previous_bid < highest_26 && bid > highest_26)
        {
         if(showHighestsAndLowests)
            printf("bid has got above highest (" + highest_26 + ") on 26 candlesticks. current bid = " + bid);
         if(showHighestsAndLowests)
            PlaySound("alert.wav");
        }

      if(previous_bid > lowest_26 && bid < lowest_26)
        {
         if(showHighestsAndLowests)
            printf("bid has got below lowest (" + lowest_26 + ") on 26 candlesticks. current bid= " + bid);
         if(showHighestsAndLowests)
            PlaySound("alert.wav");
          //Trade_buy_2();
        }

      previous_ask = ask;
      previous_bid = bid;

      if(previous_highest_26 == 0)
        {
         previous_highest_26 = highest_26;
         if(showHighestsAndLowests)
            printf("current highest 26 = " + highest_26);
        }
      if(previous_lowest_26 == 0)
        {
         previous_lowest_26 = lowest_26;
         if(showHighestsAndLowests)
            printf("current lowest 26 = " + lowest_26);
        }

      //done = true;
      //ArrayFree(high_array);
      //ArrayFree(low_array);
      //ArrayFree(close_array);

      int tenkan_sen = 9;              // period of Tenkan-sen
      int kijun_sen = 26;              // period of Kijun-sen
      int senkou_span_b = 52;          // period of Senkou Span B

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

      bool showIchimokuInfos = false;
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
            if(isNewBar())
              {
               if(mql_rates[1].open > kijun_sen_buffer[1])
                  if(mql_rates[1].close < kijun_sen_buffer[1])
                     if(showIchimokuInfos)
                        printf("Price has got below its kijun sen");

               if(mql_rates[1].open < kijun_sen_buffer[1])
                  if(mql_rates[1].close > kijun_sen_buffer[1])
                     if(showIchimokuInfos)
                        printf("Price has got above its kijun sen");

               if(mql_rates[1].open > tenkan_sen_buffer[1])
                  if(mql_rates[1].close < tenkan_sen_buffer[1])
                     if(showIchimokuInfos)
                        printf("Price has got below its tenkan sen");

               if(mql_rates[1].open < tenkan_sen_buffer[1])
                  if(mql_rates[1].close > tenkan_sen_buffer[1])
                     if(showIchimokuInfos)
                        printf("Price has got above its tenkan sen");

               // Measuring percentages of high of low wicks and if higher wick is greatest that lower wick then
               // assuming than there is a higher probability of going down and if lower wick is greatest than higher wick
               // then assuming than there is a higher probability of going up... Measurements on the previous candlestick.
               bool showWicksProbability = false; /********/
               if(mql_rates[1].open > mql_rates[1].close)
                 {
                  //bougie verte
                  double diff_high_close = ((mql_rates[1].high - mql_rates[1].close)/mql_rates[1].close)*100;
                  double diff_open_low = ((mql_rates[1].open - mql_rates[1].low)/mql_rates[1].low)*100;
                  if(showWicksProbability)
                     printf("previous diff between high and close = " + string(diff_high_close));
                  if(showWicksProbability)
                     printf("previous diff between open and low = " + string(diff_open_low));
                  if(diff_high_close > diff_open_low)
                    {
                     if(showWicksProbability)
                        printf("higher probability of price going down");
                     //Trade_sell();
                    }
                  else
                    {
                     if(showWicksProbability)
                        printf("higher probability of price going up");
                     //Trade_buy_2();
                    }
                 }
               else
                  if(mql_rates[1].close > mql_rates[1].open)
                    {
                     //bougie rouge
                     double diff_high_open = ((mql_rates[1].high - mql_rates[1].open)/mql_rates[1].open)*100;
                     double diff_close_low = ((mql_rates[1].close - mql_rates[1].low)/mql_rates[1].low)*100;
                     if(showWicksProbability)
                        printf("previous diff between high and open = " + string(diff_high_open));
                     if(showWicksProbability)
                        printf("previous diff between close and low = " + string(diff_close_low));
                     if(diff_high_open > diff_close_low)
                       {
                        if(showWicksProbability)
                           printf("higher probability of price going down");
                        //Trade_sell();
                       }
                     else
                       {
                        if(showWicksProbability)
                           printf("higher probability of price going up");
                        //Trade_buy_2();
                       }
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


CTrade         m_trade;                      // object of CTrade class

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trade_buy_2()
  {
   MqlTick tick;
   if(!SymbolInfoTick(Symbol(),tick))
     {
      Alert(__FUNCTION__,", ERROR SymbolInfoTick");
      return;
     }

   ushort TakeProfit=60;
   ushort StopLoss=60;

   double StopLossLevel = tick.bid - (tick.bid/100*0.05);
   double TakeProfitLevel = tick.ask + (tick.ask/100*0.05);

   if(!m_trade.Buy(4.7, Symbol(), tick.ask, StopLossLevel, TakeProfitLevel))
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



void Trade_sell_2()
  {
   MqlTick tick;
   if(!SymbolInfoTick(Symbol(),tick))
     {
      Alert(__FUNCTION__,", ERROR SymbolInfoTick");
      return;
     }

   ushort TakeProfit=60;
   ushort StopLoss=60;

   double StopLossLevel = tick.ask + (tick.ask/100*0.05);
   double TakeProfitLevel = tick.bid - (tick.bid/100*0.05);

   if(!m_trade.Sell(4.7, Symbol(), tick.ask, StopLossLevel, TakeProfitLevel))
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




//bool trade_done = false;
void Trade_buy()
  {
//if(trade_done == true)
//return;

//if(PositionSelect(Symbol()) == true)
//return;

   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
   request.action    =TRADE_ACTION_DEAL;
   request.symbol    =Symbol();
   request.volume    =0.1;
   request.type      =ORDER_TYPE_BUY;
   request.price     =SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   request.deviation=10;
   request.magic     =123456;
//request.sl = NormalizeDouble(bid - bid/100*0.0025, _Digits);
//request.tp = NormalizeDouble(bid + bid/100*0.05, _Digits);
   request.type_filling    =ORDER_FILLING_IOC;
   if(!OrderSend(request, result))
      PrintFormat("OrderSend error %d",GetLastError());
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);


   int total = PositionsTotal();
   printf("total =" + string(total));
   for(int i=0; i<total; i++)
     {
      ulong position_ticket = PositionGetTicket(i);
      printf("ticket =" + string(position_ticket));
     }

   printf("result.deal =" + string(result.deal));
   printf("result.order =" + string(result.order));


   ulong ticket_id = result.order;
   ZeroMemory(request);
   ZeroMemory(result);


   request.action   =TRADE_ACTION_SLTP;        // type of trade operation
   request.position =ticket_id+10;          // ticket of the position
   request.symbol   =Symbol();          // symbol
   request.magic    =123456;             // MagicNumber of the position
//request.sl = NormalizeDouble(bid - bid/100*0.0025, _Digits);
//request.tp = NormalizeDouble(ask + ask/100*0.05, _Digits);
   request.sl = NormalizeDouble(bid - 0.25, _Digits);
   request.tp = NormalizeDouble(ask + 0.25, _Digits);
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code

   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
//---

//trade_done = true;
  }
//+------------------------------------------------------------------+


//bool trade_done = false;
void Trade_sell()
  {
//if(trade_done == true)
//return;

//if(PositionSelect(Symbol()) == true)
//return;

   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
   request.action    =TRADE_ACTION_DEAL;
   request.symbol    =Symbol();
   request.volume    =0.1;
   request.type      =ORDER_TYPE_SELL;
   request.price     =ask;
   request.deviation=10;
   request.magic     =123456;
   request.sl = ask + ask/100*0.05;
   request.tp = ask - ask/100*0.0025;
   request.type_filling    =ORDER_FILLING_IOC;
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);

//trade_done = true;
  }
//+------------------------------------------------------------------+
