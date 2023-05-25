//+------------------------------------------------------------------+
//|                                         SetTPForAllPositions.mq5 |
//|                       Copyright 2023, InvestData Systems France. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, InvestData Systems France."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- variables pour retourner les valeurs des propriétés de l'ordre
   ulong    ticket;
   double   open_price;
   double   initial_volume;
   datetime time_setup;
   string   symbol;
   string   type;
   long     order_magic;
   long     positionID;
//--- nombre d'ordres en attente en cours
   uint     total=PositionsTotal();
   printf(total);
//--- parcours les ordres dans une boucle
   for(uint i=0; i<total; i++)
     {
      //--- retourne le ticket de l'ordre par sa position dans la liste
      if((ticket=PositionGetTicket(i))>0)
        {
         if(trade.PositionModify(ticket, 0, 1.06100) == true)
           {
            printf("TP modified : Ok");
            //printf("code retour =", trade.ResultRetcode());
           }
        }
     }
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
void OnTick()
  {
//---

  }
//+------------------------------------------------------------------+
