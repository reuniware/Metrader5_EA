//+------------------------------------------------------------------+
//|                                                   Sell20Lots.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include<Trade\Trade.mqh>
//--- object for performing trade operations
CTrade  trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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
void OnTick()
  {
   while(true)
     {
      if(!trade.Sell(20))
        {
         //--- failure message
         Print("Buy() method failed. Return code=",trade.ResultRetcode(), ". Code description: ",trade.ResultRetcodeDescription());
        }
      else
        {
         Print("Buy() method executed successfully. Return code=",trade.ResultRetcode()," (",trade.ResultRetcodeDescription(),")");
         return;
        }
     }

  }
//+------------------------------------------------------------------+
