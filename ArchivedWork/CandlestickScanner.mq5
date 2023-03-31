//+------------------------------------------------------------------+
//|                                           CandlestickScanner.mq5 |
//|                                Copyright 2018, InvestDataSystems |
//|                 https://tradingbot.wixsite.com/robots-de-trading |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, InvestDataSystems"
#property link      "https://tradingbot.wixsite.com/robots-de-trading"
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
MqlTick last_tick;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double previousAsk=0;
double actualAsk=0;
double diff=0;
double max_diff=0;
CTrade trade;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   /*int i=PositionsTotal()-1;
   while(i>=0)
     {
      double profit;
      PositionGetDouble(POSITION_PROFIT, profit);
      //printf(PositionGetSymbol(i) + " PnL=" + DoubleToString(profit));
      if (profit>2) {
         trade.PositionClose(i);
         i--;
      }
     }*/

   if(SymbolInfoTick(Symbol(),last_tick))
     {
      actualAsk=last_tick.ask;

      if(previousAsk!=0)
        {
         diff=actualAsk-previousAsk;
         if(MathAbs(diff)>MathAbs(max_diff))
           {
            max_diff=diff;
            printf("new max_diff = "+DoubleToString(max_diff));
           }
        }

      previousAsk=last_tick.ask;
     }
   else Print("SymbolInfoTick() failed, error = ",GetLastError());
  }
//+------------------------------------------------------------------+
