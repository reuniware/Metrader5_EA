//+------------------------------------------------------------------+
//|                                  AlertMessageOnProfitReached.mq5 |
//|                                Copyright 2018, InvestDataSystems |
//|                 https://tradingbot.wixsite.com/robots-de-trading |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, InvestDataSystems"
#property link      "https://tradingbot.wixsite.com/robots-de-trading"
#property version   "1.00"
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
  }

double profit;
input double profitToReach=10;
bool done=false;
int x = 0;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(done==false)
     {
      //printf("Numbers of opened positions : %G",PositionsTotal());
      for(x=0;x<PositionsTotal();x++)
        {
         //printf("Index of the position %G",x);
         //printf("Symbol of the selected position : %s",PositionGetSymbol(x));
         //printf("Profit on the selected position : %G",PositionGetDouble(POSITION_PROFIT));
         if (PositionGetDouble(POSITION_PROFIT)>=profitToReach)
         {
            printf("Position Profit >= " + profitToReach + " !");
            SendNotification("Position Profit >= " + profitToReach + " !");
            done = true;
         }
        }
     }

  }
//+------------------------------------------------------------------+
