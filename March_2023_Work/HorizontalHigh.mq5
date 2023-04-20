//+------------------------------------------------------------------+
//|                                               HorizontalHigh.mq5 |
//|                        Copyright 2023, InvestDataSystems France. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, InvestDataSystems France."
#property link      "https://www.mql5.com"
#property version   "1.00"

long cid;

MqlRates mql_rates[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool firstInitDone = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(firstInitDone)
      return(INIT_SUCCEEDED);

   ArraySetAsSeries(mql_rates, true);

   cid=ChartID();

   processPoint1();

   firstInitDone = true;

   return(INIT_SUCCEEDED);
  }



int index = 1;
double currentHigh = 0;
double currentDelta = 0;
void processPoint1()
  {
  Comment(Point());
//ObjectsDeleteAll(cid);
   /*ObjectDelete(cid, "IFL1");
   ObjectDelete(cid, "IFL2");
   ObjectDelete(cid, "IFL1B");
   ObjectDelete(cid, "IFL2B");*/

   int maxBars = 60*24*7;
   int numCopied = 0;
   numCopied = CopyRates(Symbol(), PERIOD_CURRENT, 0, maxBars, mql_rates);
//printf("numCopied=" + string(numCopied));

   ObjectDelete(cid, "high");
   
   currentHigh = mql_rates[index].high + currentDelta;
   
   bool res;
   res = ObjectCreate(cid, "high", OBJ_HLINE, 0, mql_rates[index].time, currentHigh);

//datetime dtNext = mql_rates[0].time + (mql_rates[0].time - mql_rates[1].time);
//res = ObjectCreate(cid, "vline", OBJ_VLINE, 0, dtNext, 0);


   ChartRedraw(cid);

//for(int i=0; i<96; i++) {
//   printf(string(i) + " " + string(mql_rates[i].time) + " : " + string(mql_rates[i].open));
//}

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
   double trendlinevalueIFL1 = ObjectGetValueByTime(cid,"IFL1",TimeCurrent());
   double trendlinevalueIFL2 = ObjectGetValueByTime(cid,"IFL2",TimeCurrent());
   int numCopied = 0;
   numCopied = CopyRates(Symbol(), PERIOD_CURRENT, 0, 1, mql_rates);
//printf(string(numCopied));
   if(numCopied == 1)
     {
      //Comment("Price=" + string(mql_rates[0].close) + " IFL2=" + string(trendlinevalueIFL2));
      //printf(string(mql_rates[0].close));
      if(mql_rates[0].open > trendlinevalueIFL2 && mql_rates[0].close < trendlinevalueIFL2)
        {
         Comment("Price is getting below IFL2");
         //PlaySound("alert.wav");
        }
      else
         if(mql_rates[0].open < trendlinevalueIFL1 && mql_rates[0].close > trendlinevalueIFL1)
           {
            Comment("Price is getting above IFL1");
            //PlaySound("alert.wav");
           }
     }
   else
     {
      Comment("numCopied=0");
     }
   ArrayFree(mql_rates);
   trendlinevalueIFL2 = NULL;
   trendlinevalueIFL1 = NULL;
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
            //Print("Pressed KEY_NUMLOCK_LEFT");
            /*ObjectSetInteger(cid, "IFL1", OBJPROP_RAY_RIGHT, 0);
            ObjectSetInteger(cid, "IFL2", OBJPROP_RAY_RIGHT, 0);
            ObjectSetInteger(cid, "IFL1B", OBJPROP_RAY_RIGHT, 0);
            ObjectSetInteger(cid, "IFL2B", OBJPROP_RAY_RIGHT, 0);
            ChartRedraw(cid);*/
            break;
         case KEY_NUMLOCK_RIGHT:
            //Print("Pressed KEY_NUMLOCK_RIGHT");
            /*ObjectSetInteger(cid, "IFL1", OBJPROP_RAY_RIGHT, 1);
            ObjectSetInteger(cid, "IFL2", OBJPROP_RAY_RIGHT, 1);
            ObjectSetInteger(cid, "IFL1B", OBJPROP_RAY_RIGHT, 1);
            ObjectSetInteger(cid, "IFL2B", OBJPROP_RAY_RIGHT, 1);
            ChartRedraw(cid);*/
            break;
         case KEY_LEFT:
            //Print("Pressed KEY_LEFT");
            break;
         case KEY_NUMLOCK_UP:
            //Print("Pressed KEY_NUMLOCK_UP");
            index++;
            processPoint1();
            break;
         case KEY_NUMLOCK_DOWN:
            //Print("Pressed KEY_NUMLOCK_DOWN");
            index--;
            if(index < 0)
               index = 1;
            processPoint1();
            break;
         case KEY_UP:
            //Print("Pressed KEY_UP");
            currentDelta += Point();
            processPoint1();
            break;
         case KEY_DOWN:
            //Print("Pressed KEY_DOWN");
            currentDelta -= Point();
            processPoint1();
            break;
         case KEY_RIGHT:
            //Print("Pressed KEY_RIGHT");
            break;
         case KEY_NUMPAD_5:
            //Print("Pressed KEY_NUMPAD_5");
            break;
         case KEY_NUMLOCK_5:
            //Print("Pressed KEY_NUMLOCK_5");
            break;
         default:
            //Print("Pressed unlisted key " + lparam);
            //Comment("Pressed unlisted key " + lparam);
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
               firstInitDone = false;
               currentDelta = 0;
               index = 1;
               OnInit();
               break;
              }
            if(letterPressed == "c")
              {
               cid=ChartID();
               //ObjectsDeleteAll(cid);
               /*ObjectDelete(cid, "IFL1");
               ObjectDelete(cid, "IFL2");
               ObjectDelete(cid, "IFL1B");
               ObjectDelete(cid, "IFL2B");*/
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
