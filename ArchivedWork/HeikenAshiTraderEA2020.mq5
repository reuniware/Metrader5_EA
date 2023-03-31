//+------------------------------------------------------------------+
//|                                      HeikenAshiScannerEA2020.mq5 |
//|                       Copyright 2020, Invest Data Systems France |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Invest Data Systems France"
#property link      "https://ichimokuscanner.000webhostapp.com"
#property version   "1.00"

//--- the number of indicator buffer for storage Open
#define  HA_OPEN     0
//--- the number of the indicator buffer for storage High
#define  HA_HIGH     1
//--- the number of indicator buffer for storage Low
#define  HA_LOW      2
//--- the number of indicator buffer for storage Close
#define  HA_CLOSE    3

input bool runOnlyOnce = true;

bool onlySymbolsInMarketwatch = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //EventSetTimer(60*15);   // daily ; tp 50 sl 200
   EventSetTimer(60);   // 15 min ; tp 25 sl 100
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//done = false;
   EventKillTimer();
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
//bool done = false;
void OnTick()
  {
//---
   /*if(!done)
     {
      HeikenAshi();
      done = true;
     }*/
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//if(!done)
//{
   HeikenAshi();
//EventKillTimer();
//}
  }

//+------------------------------------------------------------------+
int stotal = 0;

datetime time_as_series[];
datetime trade_time;
int index_achat = 0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HeikenAshi()
  {
   stotal = SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch = true

   for(int sindex=0; sindex<stotal; sindex++)
     {
      string sname = SymbolName(sindex, onlySymbolsInMarketwatch);
      //printf(sname);

      int handle = iCustom(sname, Period(), "Examples\\Heiken_Ashi", 0, 0);

      int max = 4;
      double haOpen[], haHigh[], haLow[], haClose[];
      ArrayResize(haOpen, max, max);
      ArrayResize(haHigh, max, max);
      ArrayResize(haLow, max, max);
      ArrayResize(haClose, max, max);
      ArraySetAsSeries(haOpen, true);
      ArraySetAsSeries(haHigh, true);
      ArraySetAsSeries(haLow, true);
      ArraySetAsSeries(haClose, true);
      CopyBuffer(handle, HA_OPEN, 0, max, haOpen);
      CopyBuffer(handle, HA_HIGH, 0, max, haHigh);
      CopyBuffer(handle, HA_LOW, 0, max, haLow);
      CopyBuffer(handle, HA_CLOSE, 0, max, haClose);

      ArraySetAsSeries(time_as_series, true);
      ArrayResize(time_as_series, max, max);
      int copied = CopyTime(sname, Period(), 0, max, time_as_series);

      //printf(sname + ": haOpen=" + normalized_haOpen);
      //printf(sname + ": haLow=" + normalized_haLow);

      /*if(haOpen[1] < haClose[1])
        {
         // bougie verte
         if(normalized_haLow == normalized_haOpen)
           {
            printf(sname + ": La bougie précédente " + StringSubstr(EnumToString(Period()), 7) + " de " + time_as_series[1] + " n'a pas d'ombre inférieure");
           }
        }
      if(haOpen[1] > haClose[1])
        {
         // bougie rouge
         if(normalized_haHigh == normalized_haOpen)
           {
            printf(sname + ": La bougie précédente " + StringSubstr(EnumToString(Period()), 7) + " de " + time_as_series[1] + " n'a pas d'ombre supérieure");
           }
        }*/

      //CheckCandlestick(sname, -1, haOpen, haClose, haHigh, haLow, time_as_series);
      //CheckCandlestick(sname, -2, haOpen, haClose, haHigh, haLow, time_as_series);
      //CheckCandlestick(sname, -3, haOpen, haClose, haHigh, haLow, time_as_series);

      if(CandlestickIsGreen(sname, -3, haOpen, haClose))
        {
         if(CandlestickIsGreen(sname, -2, haOpen, haClose))
           {
            if(CandlestickIsRed(sname, -1, haOpen, haClose))
              {
               //printf(sname + ": CS[-3] is GREEN and CS[-2] is GREEN and CS[-1] is RED in " + StringSubstr(EnumToString(Period()), 7));
              }
           }
        }

      if(CandlestickIsRed(sname, -3, haOpen, haClose))
        {
         if(CandlestickIsRed(sname, -2, haOpen, haClose))
           {
            if(CandlestickIsGreen(sname, -1, haOpen, haClose))
              {
               //printf(sname + ": CS[-3] is RED and CS[-2] is RED and CS[-1] is GREEN in " + StringSubstr(EnumToString(Period()), 7));
               if(trade_time == "1970.01.01 00:00:00")
                 {
                  printf("premier achat numéro " + index_achat);
                  index_achat++;
                  BUY(sname);
                  trade_time = time_as_series[0];
                 }
               else
                 {
                  if(PositionsTotal() == 0)
                    {
                     if(time_as_series[0] != trade_time)
                       {
                        printf("achat numéro " + index_achat);
                        index_achat++;
                        BUY(sname);
                        trade_time = time_as_series[0];
                       }
                    }
                 }
              }
           }
        }

      //printf("");

      ArrayFree(haOpen);
      ArrayFree(haLow);
      ArrayFree(haHigh);
      ArrayFree(haClose);

      ArrayFree(time_as_series);


     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckCandlestick(string sname, int n, double &haOpen[], double &haClose[], double &haHigh[], double &haLow[], datetime &time_as_series[])
  {
   if(n<0)
      n = -n;

   int digits = (int)SymbolInfoInteger(sname, SYMBOL_DIGITS);
   string normalized_haOpen = NormalizeDouble(haOpen[1], digits);
   string normalized_haLow = NormalizeDouble(haLow[1], digits);
   string normalized_haHigh = NormalizeDouble(haHigh[1], digits);
   string normalized_haClose = NormalizeDouble(haClose[1], digits);

   if(haOpen[n] < haClose[n])
     {
      // bougie verte
      printf(sname + ": La bougie [-" + n + "] en " + StringSubstr(EnumToString(Period()), 7) + " de " + time_as_series[n] + " est haussière");
      if(normalized_haLow == normalized_haOpen)
        {
         printf(sname + ": La bougie [-" + n + "] en " + StringSubstr(EnumToString(Period()), 7) + " de " + time_as_series[n] + " n'a pas d'ombre inférieure");
        }
     }

   if(haOpen[n] > haClose[n])
     {
      // bougie rouge
      printf(sname + ": La bougie [-" + n + "] en " + StringSubstr(EnumToString(Period()), 7) + " de " + time_as_series[n] + " est baissière");
      if(normalized_haHigh == normalized_haOpen)
        {
         printf(sname + ": La bougie [-" + n + "] en " + StringSubstr(EnumToString(Period()), 7) + " de " + time_as_series[n] + " n'a pas d'ombre supérieure");
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool CandlestickIsGreen(string sname, int n, double &haOpen[], double &haClose[])
  {
   if(n<0)
      n = -n;
   if(haOpen[n] < haClose[n])
     {
      // bougie verte
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CandlestickIsRed(string sname, int n, double &haOpen[], double &haClose[])
  {
   if(n<0)
      n = -n;
   if(haOpen[n] > haClose[n])
     {
      // bougie rouge
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BUY(string symbol,double takeprofit_pips=0.00025, double stoploss_pips=0.0050)
  {
   MqlTick lasttick;
   SymbolInfoTick(symbol,lasttick);
   double spread = lasttick.ask - lasttick.bid; // spread = prix de vente - prix d'achat
   double price = SymbolInfoDouble(symbol,SYMBOL_ASK);

   MqlTradeRequest request = {0};
   MqlTradeResult  result = {0};
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = 1.0;
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
