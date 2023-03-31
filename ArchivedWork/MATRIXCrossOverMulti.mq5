//+------------------------------------------------------------------+
//|                                              MATRIXCrossOver.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, InvestDataSystems France (investdatasystems@yahoo.com)."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

input bool runOnlyOnce = false; // si true alors s'exécute immédiatement une fois sinon en boucle à chaque de bougie

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(runOnlyOnce)
      EventSetTimer(1);
   else
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
   if(runOnlyOnce)
     {
      ProcessCalculations();
      EventKillTimer();
     }
   else
      ProcessCalculations();
  }

static int BARS;

bool first_run_done[];

static datetime LastBarTime[];//=-1;

int maxhisto = 32;
int stotal = 0;
bool initdone = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessCalculations()
  {
   int stotal = SymbolsTotal(true); // seulement les symboles dans le marketwatch (false)

//printf("pc");
   if(!initdone)
     {
      ArrayResize(first_run_done, stotal, stotal);
      ArrayResize(LastBarTime, stotal, stotal);

      for(int i=0; i<stotal; i++)
        {
         first_run_done[i] = false;
         LastBarTime[i] = -1;
        }
      initdone = true;
     }

   for(int sindex=0; sindex<stotal; sindex++)
     {
      bool ok = false;

      string sname = SymbolName(sindex, true);
      //printf(sname);

      datetime ThisBarTime = (datetime)SeriesInfoInteger(sname, Period(), SERIES_LASTBAR_DATE);
      if(ThisBarTime == LastBarTime[sindex])
        {
         //log("Same bar time (" + sname + ")");
        }
      else
        {
         if(LastBarTime[sindex] == -1)
           {
            //log("First bar (" + sname + ")");
            LastBarTime[sindex] = ThisBarTime;
           }
         else
           {
            //printf("New bar time (" + sname + ")");
            LastBarTime[sindex] = ThisBarTime;
            ok = true;
           }
        }

      if(runOnlyOnce)
         ok = true; // (pour forcer à calculer à chaque fois et non à la fin d'une bougie)

      if(ok)
        {
         MATRIXCrossOverCalculations(sname, Period());
        }

     }

  }
//+------------------------------------------------------------------+

double ma1Buffer[];
double ma2Buffer[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MATRIXCrossOverCalculations(string sname, ENUM_TIMEFRAMES period)
  {
   ArraySetAsSeries(ma1Buffer, true);
   int handle = iMA(sname, period, 20, 0, MODE_SMA, PRICE_CLOSE);
   CopyBuffer(handle, 0, 0, 10, ma1Buffer);
//printf("MA=" + DoubleToString(maBuffer[0]));

   ArraySetAsSeries(ma2Buffer, true);
//handle = iCustom(Symbol(), Period(), "Examples\\Custom Moving Average", 0, 0);

//handle = iCustom(Symbol(), Period(), "Examples\\DEMA", 14, 0, 0, PRICE_CLOSE);
   handle = iMA(sname, period, 9, 0, MODE_EMA, PRICE_CLOSE);
   CopyBuffer(handle, 0, 0, 10, ma2Buffer);
//printf("DEMA=" + DoubleToString(demaBuffer[0]));

   if(ma1Buffer[1] < ma2Buffer[1] && ma1Buffer[0] > ma2Buffer[0])
     {
      string msg = StringSubstr(EnumToString(period), 7) + " : " + sname + " : cross SMA20 > EMA9 (Downtrend)";
      printf(msg); // Downtrend
      SendNotification(msg);
      //processSell();
     }
   else
      if(ma1Buffer[1] > ma2Buffer[1] && ma1Buffer[0] < ma2Buffer[0])
        {
         string msg = StringSubstr(EnumToString(period), 7) + " : " + sname + " : cross EMA9 > SMA20 (Uptrend)";
         printf(msg); // Uptrend
         SendNotification(msg);
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
