//+------------------------------------------------------------------+
//|                                   IchimokuForecastLinesEA002.mq5 |
//|                        Copyright 2023, InvestDataSystems France. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
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

   ArraySetAsSeries(mql_rates, true);
   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   cid=ChartID();

   processPoint1();

   firstInitDone = true;

   return(INIT_SUCCEEDED);
  }



double tenkan_sen_buffer[];
double kijun_sen_buffer[];
double senkou_span_a_buffer[];
double senkou_span_b_buffer[];
double chikou_span_buffer[];
int nbt=-1, nbk=-1, nbssa=-1, nbssb=-1, nbc=-1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int delta = 0;
bool forceUseHigh = false;
bool forceUseLow = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void processPoint1()
  {
   ObjectsDeleteAll(cid);

   int maxBars = 60*24*52*7*52;
   int numCopied = 0;
   numCopied = CopyRates(Symbol(), PERIOD_CURRENT, 0, maxBars, mql_rates);
//printf("numCopied=" + string(numCopied));

   int tenkan_sen_param = 9;              // period of Tenkan-sen
   int kijun_sen_param = 26;              // period of Kijun-sen
   int senkou_span_b_param = 52;          // period of Senkou Span B
   int handleIchimoku = INVALID_HANDLE;
   handleIchimoku = iIchimoku(Symbol(), Period(), tenkan_sen_param, kijun_sen_param, senkou_span_b_param);

   nbt=-1;
   nbk=-1;
   nbssa=-1;
   nbssb=-1;
   nbc=-1;
   int maxBarsIch = 2048;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, maxBarsIch, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, maxBarsIch, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, maxBarsIch, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, maxBarsIch, senkou_span_b_buffer);
   nbc= CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,maxBarsIch,chikou_span_buffer);

// Traitements
   double initialCandlestickValue;

   double ssa_at_initial = senkou_span_a_buffer[0 + delta];
   double ssb_at_initial = senkou_span_b_buffer[0 + delta];
//printf("SSA at initial candlestick = " + string(ssa_at_initial));
//printf("SSB at initial candlestick = " + string(ssb_at_initial));

   double high_initial = mql_rates[0 + delta].high;
   double low_initial = mql_rates[0 + delta].low;

   bool useHigh = false, useLow = false;

   if(high_initial > ssa_at_initial && high_initial > ssb_at_initial /*&& MathAbs(high_initial - ssb_at_initial) > MathAbs(low_initial - ssb_at_initial)*/)
     {
      useHigh = true;
      useLow = false;
     }
   if(low_initial < ssa_at_initial && low_initial < ssb_at_initial)
     {
      useLow = true;
      useHigh = false;
     }

   if(forceUseHigh)
     {
      useHigh = true;
      useLow = false;
     }
   else
      if(forceUseLow)
        {
         useLow = true;
         useHigh = false;
        }

   if(useHigh)
      initialCandlestickValue = high_initial;
   else
      if(useLow)
         initialCandlestickValue = low_initial;

   datetime dtInitialCandlestick = mql_rates[0 + delta].time;

   double SSBValue, SSAValue, tenkanValue, kijunValue;
   datetime dtSSB, dtSSA;

   tenkanValue = tenkan_sen_buffer[0 + delta];
   kijunValue = kijun_sen_buffer[0 + delta];
   SSAValue = (tenkanValue + kijunValue)/2;
   dtSSA = dtInitialCandlestick + 26*(mql_rates[0].time - mql_rates[1].time);
//printf(string(mql_rates[0].time));
//printf(string(mql_rates[1].time));

   double higherHigh = 0, lowerLow = 0x6FFFFFFF;
   for(int i = 0 + delta; i < 0 + delta + 52 ; i++)
     {
      if(mql_rates[i].high > higherHigh)
         higherHigh = mql_rates[i].high;
      if(mql_rates[i].low < lowerLow)
         lowerLow = mql_rates[i].low;
     }
   SSBValue = (higherHigh + lowerLow)/2;
   dtSSB = dtSSA;
//printf("dtInitialCandlestick = " + string(dtInitialCandlestick));
//printf("dtSSB = dtSSA = " + string(dtSSB));

   datetime diff = dtSSB - dtInitialCandlestick;
//printf("diff = " + string(diff));

   /*SSBValue = senkou_span_b_buffer[0 + delta];
   dtSSB = mql_rates[0 + delta].time;
   printf("ssb = " + string(SSBValue));*/

   /*SSAValue = senkou_span_a_buffer[0 + delta];
   dtSSA = mql_rates[0 + delta].time;
   printf("ts = " + string(SSAValue));*/

   bool res;
   res = ObjectCreate(cid, "IFL1", OBJ_TREND, 0, dtInitialCandlestick, initialCandlestickValue, dtSSB, SSBValue);
   res = ObjectCreate(cid, "IFL2", OBJ_TREND, 0, dtInitialCandlestick, initialCandlestickValue, dtSSA, SSAValue);

   res = ObjectCreate(cid, "vlineInitial", OBJ_VLINE, 0, dtInitialCandlestick, 0);
   res = ObjectCreate(cid, "vlineSSASSB", OBJ_VLINE, 0, dtSSB, 0);

//datetime dtNext = mql_rates[0].time + (mql_rates[0].time - mql_rates[1].time);
//res = ObjectCreate(cid, "vline", OBJ_VLINE, 0, dtNext, 0);


   ChartRedraw(cid);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

//for(int i=0; i<96; i++) {
//   printf(string(i) + " " + string(mql_rates[i].time) + " : " + string(mql_rates[i].open));
//}

   ArrayFree(mql_rates);

   processPoint2();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void processPoint2()
  {
//ObjectsDeleteAll(cid);

   int maxBars = 60*24*52*7*52;
   int numCopied = 0;
   numCopied = CopyRates(Symbol(), PERIOD_CURRENT, 0, maxBars, mql_rates);
//printf("numCopied=" + string(numCopied));

   int tenkan_sen_param = 9;              // period of Tenkan-sen
   int kijun_sen_param = 26;              // period of Kijun-sen
   int senkou_span_b_param = 52;          // period of Senkou Span B
   int handleIchimoku = INVALID_HANDLE;
   handleIchimoku = iIchimoku(Symbol(), Period(), tenkan_sen_param, kijun_sen_param, senkou_span_b_param);

   nbt=-1;
   nbk=-1;
   nbssa=-1;
   nbssb=-1;
   nbc=-1;
   int maxBarsIch = 2048;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, maxBarsIch, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, maxBarsIch, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, maxBarsIch, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, maxBarsIch, senkou_span_b_buffer);
   nbc= CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,maxBarsIch,chikou_span_buffer);

// Traitements
   double initialCandlestickValue;

   double ssa_at_initial = senkou_span_a_buffer[0 + delta + 26];
   double ssb_at_initial = senkou_span_b_buffer[0 + delta + 26];
//printf("SSA at initial candlestick = " + string(ssa_at_initial));
//printf("SSB at initial candlestick = " + string(ssb_at_initial));

   double high_initial = mql_rates[0 + delta + 26].high;
   double low_initial = mql_rates[0 + delta + 26].low;

   bool useHigh = false, useLow = false;

   if(high_initial > ssa_at_initial && high_initial > ssb_at_initial /*&& MathAbs(high_initial - ssb_at_initial) > MathAbs(low_initial - ssb_at_initial)*/)
     {
      useHigh = true;
      useLow = false;
     }
   if(low_initial < ssa_at_initial && low_initial < ssb_at_initial)
     {
      useLow = true;
      useHigh = false;
     }

   if(forceUseHigh)
     {
      useHigh = true;
      useLow = false;
     }
   else
      if(forceUseLow)
        {
         useLow = true;
         useHigh = false;
        }

   if(useHigh)
      initialCandlestickValue = high_initial;
   else
      if(useLow)
         initialCandlestickValue = low_initial;

   datetime dtInitialCandlestick = mql_rates[0 + delta + 26].time;

   double SSBValue, SSAValue, tenkanValue, kijunValue;
   datetime dtTenkan, dtKijun;

   tenkanValue = tenkan_sen_buffer[0 + delta];
   kijunValue = kijun_sen_buffer[0 + delta];
//SSAValue = (tenkanValue + kijunValue)/2;
   dtTenkan = dtInitialCandlestick + 26*(mql_rates[0].time - mql_rates[1].time);
//printf(string(mql_rates[0].time));
//printf(string(mql_rates[1].time));

   double higherHigh = 0, lowerLow = 0x6FFFFFFF;
   for(int i = 0 + delta; i < 0 + delta + 52 ; i++)
     {
      if(mql_rates[i].high > higherHigh)
         higherHigh = mql_rates[i].high;
      if(mql_rates[i].low < lowerLow)
         lowerLow = mql_rates[i].low;
     }
//SSBValue = (higherHigh + lowerLow)/2;
   dtKijun = dtTenkan;
//printf("dtInitialCandlestick = " + string(dtInitialCandlestick));
//printf("dtSSB = dtSSA = " + string(dtSSB));

//   datetime diff = dtTenkan - dtInitialCandlestick;
//printf("diff = " + string(diff));

   /*SSBValue = senkou_span_b_buffer[0 + delta];
   dtSSB = mql_rates[0 + delta].time;
   printf("ssb = " + string(SSBValue));*/

   /*SSAValue = senkou_span_a_buffer[0 + delta];
   dtSSA = mql_rates[0 + delta].time;
   printf("ts = " + string(SSAValue));*/

   bool res;
   res = ObjectCreate(cid, "IFL1B", OBJ_TREND, 0, dtInitialCandlestick, initialCandlestickValue, dtTenkan, tenkanValue);
   res = ObjectCreate(cid, "IFL2B", OBJ_TREND, 0, dtInitialCandlestick, initialCandlestickValue, dtTenkan, kijunValue);

   res = ObjectCreate(cid, "vlineInitialB", OBJ_VLINE, 0, dtInitialCandlestick, 0);
   res = ObjectCreate(cid, "vlineSSASSBB", OBJ_VLINE, 0, dtTenkan, 0);

//datetime dtNext = mql_rates[0].time + (mql_rates[0].time - mql_rates[1].time);
//res = ObjectCreate(cid, "vline", OBJ_VLINE, 0, dtNext, 0);


   ChartRedraw(cid);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

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
         PlaySound("alert.wav");
        }
      else
         if(mql_rates[0].open < trendlinevalueIFL1 && mql_rates[0].close > trendlinevalueIFL1)
           {
            Comment("Price is getting above IFL1");
            PlaySound("alert.wav");
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
            ObjectSetInteger(cid, "IFL1", OBJPROP_RAY_RIGHT, 0);
            ObjectSetInteger(cid, "IFL2", OBJPROP_RAY_RIGHT, 0);
            ObjectSetInteger(cid, "IFL1B", OBJPROP_RAY_RIGHT, 0);
            ObjectSetInteger(cid, "IFL2B", OBJPROP_RAY_RIGHT, 0);
            ChartRedraw(cid);
            break;
         case KEY_NUMLOCK_RIGHT:
            //Print("Pressed KEY_NUMLOCK_RIGHT");
            ObjectSetInteger(cid, "IFL1", OBJPROP_RAY_RIGHT, 1);
            ObjectSetInteger(cid, "IFL2", OBJPROP_RAY_RIGHT, 1);
            ObjectSetInteger(cid, "IFL1B", OBJPROP_RAY_RIGHT, 1);
            ObjectSetInteger(cid, "IFL2B", OBJPROP_RAY_RIGHT, 1);
            ChartRedraw(cid);
            break;
         case KEY_LEFT:
            //Print("Pressed KEY_LEFT");
            break;
         case KEY_NUMLOCK_UP:
            //Print("Pressed KEY_NUMLOCK_UP");
            // Increase by 1 the number of bars to search for Kijun flat lines
            Comment("forceUseHigh = true");
            forceUseHigh = true;
            forceUseLow = false;
            processPoint1();
            break;
         case KEY_NUMLOCK_DOWN:
            //Print("Pressed KEY_NUMLOCK_DOWN");
            // Decrease by 1 the number of bars to search for Kijun flat lines
            Comment("forceUseLow = true");
            forceUseHigh = false;
            forceUseLow = true;
            processPoint1();
            break;
         case KEY_UP:
            //Print("Pressed KEY_UP");
            Comment("");
            forceUseHigh = false;
            forceUseLow = false;
            delta++;
            processPoint1();
            break;
         case KEY_DOWN:
            //Print("Pressed KEY_DOWN");
            Comment("");
            forceUseHigh = false;
            forceUseLow = false;
            delta--;
            if(delta < 0)
               delta = 0;
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