//+------------------------------------------------------------------+
//|                                                 TrendLinesEA.mq5 |
//|                        Copyright 2023, InvestDataSystems France. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

long cid;

MqlRates mql_rates[];
double maxPrice1=0, maxPrice2=0;
datetime dtMaxPrice1, dtMaxPrice2;
int barsForTrendline = 64;
string arrayDateTimesAndHighs[64];

bool initDone = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(initDone == true)
     {
      return(INIT_SUCCEEDED);
     }

   printf("onInit");
   string msg = "Number of bars for finding trendlines = " + string(barsForTrendline);
   //msg += "r\nUP/DOWN (Numeric keypad) to change the number of bars.";
   msg += "\r\nPress the UP arrow to change the 2nd point of the trendline.";
   Comment(msg);

   ArraySetAsSeries(mql_rates, true);

   cid=ChartID();

   maxPrice1 = 0;
   maxPrice2 = 0;
   dtMaxPrice1 = NULL;
   dtMaxPrice2 = NULL;
   ArrayFree(arrayDateTimesAndHighs);

   processPoint1();
   processPoint2();

   initDone = true;

   return(INIT_SUCCEEDED);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void processPoint1()
  {
   ObjectsDeleteAll(cid);

   ArrayFree(arrayDateTimesAndHighs);

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

   printf("1st point datetime (dtMaxPrice1) = " + string(dtMaxPrice1));
   printf("1st point price (maxPrice1) = " + string(maxPrice1));

   for(int i=0; i<barsForTrendline; i++)
     {
      if(mql_rates[i].time > dtMaxPrice1)
        {
         arrayDateTimesAndHighs[i] = string(mql_rates[i].time) + "#" + string(mql_rates[i].high);
        }
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

   printf("2nd point datetime (dtMaxPrice2) = " + string(dtMaxPrice2));
   printf("2nd point price (maxPrice2) = " + string(maxPrice2));

   bool res;
   res = ObjectCreate(cid, "trendline1", OBJ_TREND, 0, dtMaxPrice1, maxPrice1, dtMaxPrice2, maxPrice2);
   ObjectSetInteger(cid, "trendline1", OBJPROP_RAY_RIGHT, 1);
   ChartRedraw(cid);

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
   double trendlinevalue = ObjectGetValueByTime(cid,"trendline1",TimeCurrent());
   int numCopied = 0;
   numCopied = CopyRates(Symbol(), PERIOD_CURRENT, 0, 1, mql_rates);
   //printf(string(numCopied));
   if(numCopied == 1) {
      //printf(string(mql_rates[0].close));
      if (mql_rates[0].open < trendlinevalue && mql_rates[0].close > trendlinevalue) {
         PlaySound("alert.wav");
      }
   }
   ArrayFree(mql_rates);
   trendlinevalue = NULL;
   numCopied = NULL;
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
            //printf("ArraySize1=" + string(ArraySize(arrayDateTimesAndHighs)));
            //ArrayPrint(arrayDateTimesAndHighs);
            for(int i=0; i<barsForTrendline; i++)
              {
               string strDateTimeAndHigh = arrayDateTimesAndHighs[i];
               string result[];

               int resultat = StringSplit(strDateTimeAndHigh, '#', result);
               if(resultat > 0 && strDateTimeAndHigh != NULL)
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
                  //printf("ArraySize2=" + string(ArraySize(arrayDateTimesAndHighs)));
                  //ArrayPrint(arrayDateTimesAndHighs);
                  processPoint2();
                 }
               else
                 {
                  /*printf("GetLastError()=" + string(GetLastError()));
                  if(strDateTimeAndHigh == NULL)
                     printf("strDateTimeAndHigh=NULL");*/
                  //processPoint1();
                  //processPoint2();
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
               initDone = false;
               OnInit();
               break;
              }
            if(letterPressed == "c")
              {
               cid=ChartID();
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
