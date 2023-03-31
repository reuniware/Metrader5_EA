//+------------------------------------------------------------------+
//|                                              MATRIXCrossOver.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   EventSetTimer(5);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  }
//+------------------------------------------------------------------+
void OnTimer()
  {
   ProcessCalculations();
  }

static int BARS;

bool first_run_done;

static datetime LastBarTime;//=-1;

int maxhisto=32;

bool initdone=false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessCalculations()
  {
   if(!initdone)
     {
      first_run_done = false;
      LastBarTime = -1;
      initdone = true;
     }

   bool ok=false;

   datetime ThisBarTime =(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   if(ThisBarTime == LastBarTime)
     {
      //log("Same bar time (" + Symbol() + ")");
     }
   else
     {
      if(LastBarTime == -1)
        {
         //printf("First bar (" + Symbol() + ")");
         LastBarTime = ThisBarTime;
        }
      else
        {
         //printf("New bar time (" + Symbol() + ")");
         LastBarTime = ThisBarTime;
         ok = true;
        }
     }

   if(ok)
     {
      MATRIXCrossOverCalculations();
     }

  }
//+------------------------------------------------------------------+

double ma1Buffer[];
double ma2Buffer[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MATRIXCrossOverCalculations()
  {
   ArraySetAsSeries(ma1Buffer, true);
   int handle = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE);
   CopyBuffer(handle, 0, 0, 10, ma1Buffer);
//printf("MA=" + DoubleToString(maBuffer[0]));

   ArraySetAsSeries(ma2Buffer, true);
//handle = iCustom(Symbol(), Period(), "Examples\\Custom Moving Average", 0, 0);

   //handle = iCustom(Symbol(), Period(), "Examples\\DEMA", 14, 0, 0, PRICE_CLOSE);
   handle = iMA(Symbol(), Period(), 9, 0, MODE_EMA, PRICE_CLOSE);
   CopyBuffer(handle, 0, 0, 10, ma2Buffer);
//printf("DEMA=" + DoubleToString(demaBuffer[0]));

   if(ma1Buffer[1]<ma2Buffer[1] && ma1Buffer[0]>ma2Buffer[0])
     {
      printf("cross MA1>MA2"); // Downtrend
      //processSell();
     }
   else
      if(ma1Buffer[1]>ma2Buffer[1] && ma1Buffer[0]<ma2Buffer[0])
        {
         printf("cross MA2>MA1"); // Uptrend
         //processBuy();
        }
  }
//+------------------------------------------------------------------+

CTrade trade;
CPositionInfo positionInfo;
CDealInfo cdealInfo;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void processBuy()
  {
   if(PositionsTotal() == 0)
     {
      BUY(Symbol());
     }
   else
     {
      for(int x=0; x<PositionsTotal(); x++)
        {
         cdealInfo.SelectByIndex(x);
         //printf("commission = " + cdealInfo.Commission());
         //SendNotification("profit = " + cdealInfo.Profit());
         trade.PositionClose(Symbol());
        }
      BUY(Symbol());
     }
  }

void processSell()
  {
   if(PositionsTotal() == 0)
     {
      SELL(Symbol());
     }
   else
     {
      for(int x=0; x<PositionsTotal(); x++)
        {
         cdealInfo.SelectByIndex(x);
         //printf("commission = " + cdealInfo.Commission());
         //SendNotification("profit = " + cdealInfo.Profit());
         trade.PositionClose(Symbol());
        }
      SELL(Symbol());
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BUY(string symbol,double takeprofit_pips=0.00010, double stoploss_pips=0.00500)
  {
   MqlTick lasttick;
   SymbolInfoTick(symbol,lasttick);
   double spread = lasttick.ask - lasttick.bid; // spread = prix de vente - prix d'achat
   double price = SymbolInfoDouble(symbol,SYMBOL_ASK);

   MqlTradeRequest request = {0};
   MqlTradeResult  result = {0};
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = 0.02;
   request.type = ORDER_TYPE_BUY;
   request.price = SymbolInfoDouble(symbol, SYMBOL_ASK);

   double stoploss = 0, takeprofit = 0;

   stoploss = price - stoploss_pips;
   takeprofit = lasttick.bid + spread + takeprofit_pips;

   request.sl = stoploss;
   request.tp = takeprofit;

   if(!OrderSend(request, result))
     {
      PrintFormat(symbol+" : OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
      return false;
     }
   else
     {
      printf(symbol+" : OrderSend ok");
      return true;
     }
  }
//+------------------------------------------------------------------+
bool SELL(string symbol,double takeprofit_pips=0.00010, double stoploss_pips=0.00500)
  {
   MqlTick lasttick;
   SymbolInfoTick(symbol,lasttick);
   double spread = lasttick.ask - lasttick.bid; // spread = prix de vente - prix d'achat
   double price = SymbolInfoDouble(symbol,SYMBOL_BID);

   MqlTradeRequest request = {0};
   MqlTradeResult  result = {0};
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = 0.02;
   request.type = ORDER_TYPE_SELL;
   request.price = SymbolInfoDouble(symbol, SYMBOL_BID);

   double stoploss = 0, takeprofit = 0;

   stoploss = price + stoploss_pips;
   takeprofit = lasttick.ask - spread - takeprofit_pips;

   request.sl = stoploss;
   request.tp = takeprofit;

   if(!OrderSend(request, result))
     {
      PrintFormat(symbol+" : OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
      return false;
     }
   else
     {
      printf(symbol+" : OrderSend ok");
      return true;
     }
  }
//+------------------------------------------------------------------+
