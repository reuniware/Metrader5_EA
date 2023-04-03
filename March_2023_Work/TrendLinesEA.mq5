//+------------------------------------------------------------------+
//|                                                 TrendLinesEA.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

long cid;
int OnInit()
  {
   cid=ChartID();
   processPoint1();
   processPoint2();
   return(INIT_SUCCEEDED);
  }


MqlRates mql_rates[];
double maxPrice1=0, maxPrice2=0;
datetime dtMaxPrice1, dtMaxPrice2;
const int barsForTrendline = 30;
string arrayDateTimesAndHighs[30];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void processPoint1()
  {
   ObjectsDeleteAll(cid);

   ArraySetAsSeries(mql_rates, true);

   int maxBars = 60*24*10;
   int numCopied = 0;
   numCopied = CopyRates(Symbol(), PERIOD_CURRENT, 0, maxBars, mql_rates);
   printf("numCopied=" + string(numCopied));

   for(int i=0; i<barsForTrendline; i++)
     {
      double price = mql_rates[i].high;
      if(price > maxPrice1)
        {
         maxPrice1 = price;
         dtMaxPrice1 = mql_rates[i].time;
        }
     }

   for(int i=0; i<barsForTrendline; i++)
     {
      arrayDateTimesAndHighs[i] = string(mql_rates[i].time) + "#" + string(mql_rates[i].high);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void processPoint2()
  {
   dtMaxPrice2 = NULL;
   maxPrice2 = 0;
   for(int i=0; i<barsForTrendline; i++)
     {
      string strDateTimeAndHigh = arrayDateTimesAndHighs[i];
      string result[];
      int resultat = StringSplit(strDateTimeAndHigh, '#', result);
      if(resultat>0)
        {
         datetime dt = StringToTime(result[0]);
         double high = StringToDouble(result[1]);
         //printf(string(dt));
         //printf(string(high));
         if(dt != dtMaxPrice1)
           {
            if(high > maxPrice2)
              {
               dtMaxPrice2 = dt;
               maxPrice2 = high;
              }
           }
        }
     }

   printf("2nd point datetime = " + string(dtMaxPrice2));
   printf("2nd point price = " + string(maxPrice2));

   bool res;
   res = ObjectCreate(cid, "trendline1", OBJ_TREND, 0, dtMaxPrice1, maxPrice1, dtMaxPrice2, maxPrice2);
   ObjectSetInteger(cid, "trendline1", OBJPROP_RAY_RIGHT, 1);
   ChartRedraw(cid);

//ArrayPrint(arrayDateTimesAndHighs);
//ArrayRemove(arrayDateTimesAndHighs, 5, 1);
//ArrayPrint(arrayDateTimesAndHighs);

   ArrayFree(mql_rates);

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

datetime dateTimesToBypass[];

#define KEY_NUMPAD_5       12
#define KEY_LEFT           37
#define KEY_UP             38
#define KEY_RIGHT          39
#define KEY_DOWN           40
#define KEY_NUMLOCK_DOWN   98
#define KEY_NUMLOCK_LEFT  100
#define KEY_NUMLOCK_5     101
#define KEY_NUMLOCK_RIGHT 102
#define KEY_NUMLOCK_UP    104
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   short sym;
   string letterPressed;

   if(id==CHARTEVENT_KEYDOWN)
     {
      switch((int)lparam)
        {
         case KEY_NUMLOCK_LEFT:
            Print("Pressed KEY_NUMLOCK_LEFT");
            break;
         case KEY_NUMLOCK_RIGHT:
            Print("Pressed KEY_NUMLOCK_RIGHT");
            break;
         case KEY_LEFT:
            //Print("Pressed KEY_LEFT");
            break;
         case KEY_NUMLOCK_UP:
            Print("Pressed KEY_NUMLOCK_UP");
            // Increase by 1 the number of bars to search for Kijun flat lines
            break;
         case KEY_NUMLOCK_DOWN:
            Print("Pressed KEY_NUMLOCK_DOWN");
            // Decrease by 1 the number of bars to search for Kijun flat lines
            break;
         case KEY_UP:
            Print("Pressed KEY_UP");
            printf("ArraySize1=" + string(ArraySize(arrayDateTimesAndHighs)));
            ArrayPrint(arrayDateTimesAndHighs);
            for(int i=0; i<barsForTrendline; i++)
              {
               string strDateTimeAndHigh = arrayDateTimesAndHighs[i];
               string result[];

               int resultat = StringSplit(strDateTimeAndHigh, '#', result);
               if(resultat > 0)
                 {
                  //printf(result[0]);
                  //printf(result[1]);
                  datetime dt = StringToTime(result[0]);
                  double high = StringToDouble(result[1]);
                  //printf(string(dt));
                  //printf(string(high));
                  if(dt == dtMaxPrice2)
                    {
                     ArrayRemove(arrayDateTimesAndHighs, i, 1);
                     break;
                    }
                  printf("ArraySize2=" + string(ArraySize(arrayDateTimesAndHighs)));
                  ArrayPrint(arrayDateTimesAndHighs);
                  processPoint2();
                 }
               else
                 {
                  processPoint1();
                  processPoint2();
                 }
              }
            break;
         case KEY_DOWN:
            //Print("Pressed KEY_DOWN");
            break;
         case KEY_RIGHT:
            //Print("Pressed KEY_RIGHT");
            break;
         case KEY_NUMPAD_5:
            Print("Pressed KEY_NUMPAD_5");
            break;
         case KEY_NUMLOCK_5:
            Print("Pressed KEY_NUMLOCK_5");
            break;
         default:
            Print("Pressed unlisted key " + lparam);
            Comment("Pressed unlisted key " + lparam);
            sym = TranslateKey((int)lparam);
            letterPressed = ShortToString(sym);
            if(letterPressed == "k")
              {
               break;
              }
            if(letterPressed == "t")
              {
               break;
              }
            if(letterPressed == "b")
              {
               break;
              }
            if(letterPressed == "a")
              {
               break;
              }
            if(letterPressed == "r")
              {
               break;
              }
            if(letterPressed == "c")
              {
               long cid=ChartID();
               ObjectsDeleteAll(cid);
              }
            if(letterPressed == "h")
              {
               string msg = "[h] : Help";
               MessageBox(msg, "HELP");
               break;
              }

            if(lparam == 33)
              {
              }
            if(lparam == 34)
              {
              }
        }
     }
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
