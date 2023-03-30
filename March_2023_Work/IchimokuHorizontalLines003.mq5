//+------------------------------------------------------------------+
//|                                   IchimokuHorizontalLines003.mq5 |
//|                                Copyright 2023, InvestDataSystems |
//|                 https://tradingbot.wixsite.com/robots-de-trading |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, InvestDataSystems"
#property link      "https://tradingbot.wixsite.com/robots-de-trading"
#property link      "https://www.botmonster.fr"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
MqlRates mql_rates[];
double tenkan_sen_buffer[];
double kijun_sen_buffer[];
double senkou_span_a_buffer[];
double senkou_span_b_buffer[];
double chikou_span_buffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArraySetAsSeries(mql_rates, true);
   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   IchimokuHorizontalLines();

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
//|                                                                  |
//+------------------------------------------------------------------+
color ExtClr[140]=
  {
   clrAliceBlue,clrAntiqueWhite,clrAqua,clrAquamarine,clrAzure,clrBeige,clrBisque,clrBlack,clrBlanchedAlmond,
   clrBlue,clrBlueViolet,clrBrown,clrBurlyWood,clrCadetBlue,clrChartreuse,clrChocolate,clrCoral,clrCornflowerBlue,
   clrCornsilk,clrCrimson,clrCyan,clrDarkBlue,clrDarkCyan,clrDarkGoldenrod,clrDarkGray,clrDarkGreen,clrDarkKhaki,
   clrDarkMagenta,clrDarkOliveGreen,clrDarkOrange,clrDarkOrchid,clrDarkRed,clrDarkSalmon,clrDarkSeaGreen,
   clrDarkSlateBlue,clrDarkSlateGray,clrDarkTurquoise,clrDarkViolet,clrDeepPink,clrDeepSkyBlue,clrDimGray,
   clrDodgerBlue,clrFireBrick,clrFloralWhite,clrForestGreen,clrFuchsia,clrGainsboro,clrGhostWhite,clrGold,
   clrGoldenrod,clrGray,clrGreen,clrGreenYellow,clrHoneydew,clrHotPink,clrIndianRed,clrIndigo,clrIvory,clrKhaki,
   clrLavender,clrLavenderBlush,clrLawnGreen,clrLemonChiffon,clrLightBlue,clrLightCoral,clrLightCyan,
   clrLightGoldenrod,clrLightGreen,clrLightGray,clrLightPink,clrLightSalmon,clrLightSeaGreen,clrLightSkyBlue,
   clrLightSlateGray,clrLightSteelBlue,clrLightYellow,clrLime,clrLimeGreen,clrLinen,clrMagenta,clrMaroon,
   clrMediumAquamarine,clrMediumBlue,clrMediumOrchid,clrMediumPurple,clrMediumSeaGreen,clrMediumSlateBlue,
   clrMediumSpringGreen,clrMediumTurquoise,clrMediumVioletRed,clrMidnightBlue,clrMintCream,clrMistyRose,clrMoccasin,
   clrNavajoWhite,clrNavy,clrOldLace,clrOlive,clrOliveDrab,clrOrange,clrOrangeRed,clrOrchid,clrPaleGoldenrod,
   clrPaleGreen,clrPaleTurquoise,clrPaleVioletRed,clrPapayaWhip,clrPeachPuff,clrPeru,clrPink,clrPlum,clrPowderBlue,
   clrPurple,clrRed,clrRosyBrown,clrRoyalBlue,clrSaddleBrown,clrSalmon,clrSandyBrown,clrSeaGreen,clrSeashell,
   clrSienna,clrSilver,clrSkyBlue,clrSlateBlue,clrSlateGray,clrSnow,clrSpringGreen,clrSteelBlue,clrTan,clrTeal,
   clrThistle,clrTomato,clrTurquoise,clrViolet,clrWheat,clrWhite,clrWhiteSmoke,clrYellow,clrYellowGreen
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int minConsecutiveValues=2; // Number of identical consecutive kijun values that will make a line drawn
//input bool showTenkanLines = false;
input bool showKijunLines = true;
//input bool showSSBLines = false;

int maxBars=26*8, numCopied;

long cid;

int nbt=-1, nbk=-1, nbssa=-1, nbssb=-1, nbc=-1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void IchimokuHorizontalLines()
  {
   numCopied = 0;
   numCopied = CopyRates(Symbol(), PERIOD_CURRENT, 0, maxBars, mql_rates);
   if(numCopied == maxBars)
     {
      Comment(" price close 0 = " + string(mql_rates[0].close) + " " + string(mql_rates[0].time) + " Max Date = " + string(mql_rates[maxBars-1].time) + " Min Consecutive Kijuns = " + string(minConsecutiveValues));
     }

   /*if(CopyRates(Symbol(), PERIOD_CURRENT, 0, maxBars, mql_rates)>0)
     {
      else Comment("price close 0 = " + string(mql_rates[0].close) + " " + string(mql_rates[0].time) + " Max Date = " + string(mql_rates[maxBars-1].time) + " Min Consecutive Kijuns = " + string(minConsecutiveValues));
     }
   else
      Print("CopyRates(Symbol(), PERIOD_CURRENT,1, 10, mql_rates). Error ", GetLastError());*/

   cid=ChartID();
   ObjectsDeleteAll(cid);

   int tenkan_sen_param = 9;              // period of Tenkan-sen
   int kijun_sen_param = 26;              // period of Kijun-sen
   int senkou_span_b_param = 52;          // period of Senkou Span B
   int handleIchimoku=INVALID_HANDLE;
//int max;

   handleIchimoku=iIchimoku(Symbol(),Period(),tenkan_sen_param,kijun_sen_param,senkou_span_b_param);
//handleIchimoku=iIchimoku(Symbol(),PERIOD_D1,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   int start=0; // bar index
   int count=maxBars; // number of bars
   datetime tm[]; // array storing the returned bar time
   ArraySetAsSeries(tm,true);
   CopyTime(Symbol(),Period(),start,count,tm);

   nbt=-1;
   nbk=-1;
   nbssa=-1;
   nbssb=-1;
   nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, maxBars, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, maxBars, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, maxBars, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, maxBars, senkou_span_b_buffer);
   nbc= CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,maxBars,chikou_span_buffer);


   if(showKijunLines)
      process('k');


   ArrayFree(tm);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

  }
//+------------------------------------------------------------------+

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

   if(id==CHARTEVENT_KEYDOWN)
     {
      switch((int)lparam)
        {
         case KEY_NUMLOCK_LEFT:
            Print("Pressed KEY_NUMLOCK_LEFT");
            break;
         case KEY_LEFT:
            //Print("Pressed KEY_LEFT");
            maxBars-=100;
            if(maxBars < 0)
               maxBars = 0;
            Comment("maxBars=" + string(maxBars));
            IchimokuHorizontalLines();
            break;
         case KEY_NUMLOCK_UP:
            Print("Pressed KEY_NUMLOCK_UP");
            break;
         case KEY_UP:
            //Print("Pressed KEY_UP");
            maxBars++;
            Comment("maxBars=" + string(maxBars));
            IchimokuHorizontalLines();
            break;
         case KEY_NUMLOCK_RIGHT:
            Print("Pressed KEY_NUMLOCK_RIGHT");
            break;
         case KEY_RIGHT:
            //Print("Pressed KEY_RIGHT");
            maxBars+=100;
            Comment("maxBars=" + string(maxBars));
            IchimokuHorizontalLines();
            break;
         case KEY_NUMLOCK_DOWN:
            Print("Pressed KEY_NUMLOCK_DOWN");
            break;
         case KEY_DOWN:
            //Print("Pressed KEY_DOWN");
            maxBars--;
            Comment("maxBars=" + string(maxBars));
            IchimokuHorizontalLines();
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
            if(lparam == 33)
              {
               minConsecutiveValues++;
               IchimokuHorizontalLines();
              }
            if(lparam == 34)
              {
               minConsecutiveValues--;
               if(minConsecutiveValues < 0)
                  minConsecutiveValues = 0;
               IchimokuHorizontalLines();
              }
        }
     }
  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void process(char sIchimokuLineToProcess)
  {
   string prefix = "";
   switch((char)sIchimokuLineToProcess)
     {
      case 'k':
         prefix = "kijun";
         break;
      case 't':
         break;
      default:
         break;
     }

   double previousValue = 0;
   double currentValue = 0;
   int nbConsecutiveSameValue = 0;
// kijun sen horizontal lines
   for(int i=0; i<nbk; i++)
      //for(int i=0; i<nbk-minNumberOfSameConsecutiveValuesNeeded_KS; i++)
     {
      if(sIchimokuLineToProcess == 'k')
        {
         currentValue = kijun_sen_buffer[i];
        }
      if(currentValue == previousValue && currentValue != EMPTY_VALUE)
        {
         nbConsecutiveSameValue++;
         printf("Increasing nb consecutive same value " + string(currentValue) + " ; nb = " + string(nbConsecutiveSameValue));
        }
      else
        {
         if(currentValue != previousValue)
           {
            if(nbConsecutiveSameValue >= minConsecutiveValues)
              {
               printf("Will draw a line at " + string(previousValue));
               bool res = ObjectCreate(cid, prefix + string(i), OBJ_HLINE, 0, 0, previousValue);
               if(res)
                 {
                  ObjectSetInteger(0, prefix+i, OBJPROP_COLOR, clrDarkTurquoise);
                  ObjectSetInteger(0, prefix+i, OBJPROP_STYLE, STYLE_DOT);
                 }
              }
            printf("Current value has changed, now = " + string(currentValue));
            nbConsecutiveSameValue = 0;
           }
        }

      previousValue = currentValue;
     }
   ChartRedraw(cid);
   ChartNavigate(cid,CHART_END,0);
  }
//+------------------------------------------------------------------+
