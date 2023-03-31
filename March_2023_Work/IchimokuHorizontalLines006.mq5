//+------------------------------------------------------------------+
//|                                   IchimokuHorizontalLines006.mq5 |
//|                                Copyright 2023, InvestDataSystems |
//|                 https://tradingbot.wixsite.com/robots-de-trading |
//+------------------------------------------------------------------+

// EXPERIMENTAL (LOGGING SOME DATA TO FILE)

// THIS VERSION WORKS WITH ALL DATA HISTORY
// Previous versions work on a specific number of bars

#property copyright "Copyright 2023, InvestDataSystems"
#property link      "https://tradingbot.wixsite.com/robots-de-trading"
#property link      "https://www.botmonster.fr"
#property link      "mailto:investdatasystems@yahoo.com"
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

bool enableLogs = false;
int file_handle = INVALID_HANDLE;
string filename;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool firstInitDone = false;
int OnInit()
  {
   if(enableLogs)
     {
      string exportDir = TerminalInfoString(TERMINAL_COMMONDATA_PATH);
      printf("You will find the report in the following folder :");
      printf(exportDir + "\\Files\\");
      //FolderClean("Files", 0);
      filename = getTimestamp() + "_ichimoku.txt";
      printf("Report filename is : " + filename);
      file_handle = FileOpen(filename, FILE_WRITE|FILE_ANSI|FILE_COMMON);
      if(file_handle > 0)
        {
         printf("File created ok");
         FileClose(file_handle);
        }
      else
        {
         printf("Error file : " + GetLastError());
        }
     }

   ArraySetAsSeries(mql_rates, true);
   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   if(!firstInitDone)
     {
      IchimokuHorizontalLines();
      firstInitDone = true;
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  }

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
bool showKijunLines = true;
bool showTenkanLines = false;
bool showSsbLines = false;
bool showSsaLines = false;
//input bool showSSBLines = false;

int maxBars=26*8, numCopied;

long cid;

int nbt=-1, nbk=-1, nbssa=-1, nbssb=-1, nbc=-1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void IchimokuHorizontalLines()
  {
   maxBars = 60*24*365*100;
//printf("maxBars=" + string(numCopied));
   numCopied = 0;
   numCopied = CopyRates(Symbol(), PERIOD_CURRENT, 0, maxBars, mql_rates);
//printf("numCopied=" + string(numCopied));

   string details = "";
   if(showKijunLines)
      details+= "Kijun;";
   if(showTenkanLines)
      details+= "Tenkan;";
   if(showSsbLines)
      details+= "SSB;";
   if(showSsaLines)
      details+= "SSA;";

//if(numCopied == maxBars)
   if(numCopied > 0)
     {
      Comment("maxBars=[" + string(maxBars) + "] numCopied=[" + string(numCopied) + "] priceClose0=[" + string(mql_rates[0].close) + "] priceTime0=[" + string(mql_rates[0].time) + "] MaxDate=[" + string(mql_rates[numCopied-1].time) + "] minConsecutiveValues=[" + string(minConsecutiveValues) + "]" + " Showing=[" + details + "]");
     }

   cid=ChartID();
   ObjectsDeleteAll(cid);

   int tenkan_sen_param = 9;              // period of Tenkan-sen
   int kijun_sen_param = 26;              // period of Kijun-sen
   int senkou_span_b_param = 52;          // period of Senkou Span B
   int handleIchimoku=INVALID_HANDLE;

   handleIchimoku=iIchimoku(Symbol(), Period(), tenkan_sen_param, kijun_sen_param, senkou_span_b_param);

   int start=0; // bar index
   int count=maxBars; // number of bars

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
   if(showTenkanLines)
      process('t');
   if(showSsbLines)
      process('b');
   if(showSsaLines)
      process('a');

   /*for(int m=0; m<numCopied; m++)
     {
      log(string(kijun_sen_buffer[m]));
     }*/


   /*for(double p_ = 0; p_<2; p_+=0.05)
     {
      double p = NormalizeDouble(p_, 2);
      int nbFound = 0;
      for(int m=0; m<numCopied; m++)
        {
         if(NormalizeDouble(mql_rates[m].close, 2) == p)
           {
            //printf("Price = " + string(p) + " at " + string(mql_rates[m].time));
            nbFound++;
           }
        }

      if(nbFound>0)
        {
         //printf(string(p) + " found " + string(nbFound) + " times.");
         log(string(p) + " found " + string(nbFound) + " times.");
        }
     }*/



   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);
   ArrayFree(mql_rates);

   IndicatorRelease(handleIchimoku);
   FileClose(file_handle);

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

   short sym;
   string letterPressed;

   if(id==CHARTEVENT_KEYDOWN)
     {
      switch((int)lparam)
        {
         case KEY_NUMLOCK_LEFT:
            Print("Pressed KEY_NUMLOCK_LEFT");
            // Decrease by 100 the number of bars to search for Kijun flat lines
            maxBars-=100;
            if(maxBars < 0)
               maxBars = 0;
            Comment("maxBars=" + string(maxBars));
            IchimokuHorizontalLines();
            break;
         case KEY_NUMLOCK_RIGHT:
            Print("Pressed KEY_NUMLOCK_RIGHT");
            // Increase by 100 the number of bars to search for Kijun flat lines
            maxBars+=100;
            Comment("maxBars=" + string(maxBars));
            IchimokuHorizontalLines();
            break;
         case KEY_LEFT:
            //Print("Pressed KEY_LEFT");
            break;
         case KEY_NUMLOCK_UP:
            Print("Pressed KEY_NUMLOCK_UP");
            // Increase by 1 the number of bars to search for Kijun flat lines
            maxBars++;
            Comment("maxBars=" + string(maxBars));
            IchimokuHorizontalLines();
            break;
         case KEY_NUMLOCK_DOWN:
            Print("Pressed KEY_NUMLOCK_DOWN");
            // Decrease by 1 the number of bars to search for Kijun flat lines
            maxBars--;
            Comment("maxBars=" + string(maxBars));
            IchimokuHorizontalLines();
            break;
         case KEY_UP:
            //Print("Pressed KEY_UP");
            // Up key : Increase the minimum number of consecutive same value needed for identifying a flat (of kijun, tenkan etc...)
            minConsecutiveValues++;
            IchimokuHorizontalLines();
            break;
         case KEY_RIGHT:
            //Print("Pressed KEY_RIGHT");
            break;
         case KEY_DOWN:
            //Print("Pressed KEY_DOWN");
            // Down key : Decrease the minimum number of consecutive same value needed for identifying a flat (of kijun, tenkan etc...)
            minConsecutiveValues--;
            if(minConsecutiveValues < 0)
               minConsecutiveValues = 0;
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

            sym = TranslateKey((int)lparam);
            letterPressed = ShortToString(sym);
            if(letterPressed == "k")
              {
               showKijunLines = true;
               showTenkanLines = false;
               showSsbLines = false;
               showSsaLines = false;
               IchimokuHorizontalLines();
               break;
              }
            if(letterPressed == "t")
              {
               showKijunLines = false;
               showTenkanLines = true;
               showSsbLines = false;
               showSsaLines = false;
               IchimokuHorizontalLines();
               break;
              }
            if(letterPressed == "b")
              {
               showKijunLines = false;
               showTenkanLines = false;
               showSsbLines = true;
               showSsaLines = false;
               IchimokuHorizontalLines();
               break;
              }
            if(letterPressed == "a")
              {
               showKijunLines = false;
               showTenkanLines = false;
               showSsbLines = false;
               showSsaLines = true;
               IchimokuHorizontalLines();
               break;
              }
            if(letterPressed == "r")
              {
               cid=ChartID();
               ObjectsDeleteAll(cid);
               IchimokuHorizontalLines();
               break;
              }
            if(letterPressed == "c")
              {
               cid=ChartID();
               ObjectsDeleteAll(cid);
              }
            if(letterPressed == "h")
              {
               string msg = "[r] : Reset lines for current chart and timeframe.\r\n";
               msg += "[up]/[down] : Increase/Decrease nb of consecutive same value for a line.\r\n";
               msg += "[c] : Clear all lines.\r\n";
               msg += "[k] : Draw Kijun Sen lines.\r\n";
               msg += "[t] : Draw Tenkan Sen lines.\r\n";
               msg += "[b] : Draw Senkou Span B lines.\r\n";
               msg += "[a] : Draw Senkou Span A lines.\r\n";
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
//|                                                                  |
//+------------------------------------------------------------------+
void process(char sIchimokuLineToProcess)
  {
   int nb = 0;

   string prefix = "";
   switch((char)sIchimokuLineToProcess)
     {
      case 'k':
         prefix = "kijun";
         nb = nbk;
         break;
      case 't':
         prefix = "tenkan";
         nb = nbt;
         break;
      case 'b':
         prefix = "ssb";
         nb = nbssb;
         break;
      case 'a':
         prefix = "ssa";
         nb = nbssa;
         break;
      default:
         break;
     }

   string strPeriod, objectName;
   bool res;

   double previousValue = 0;
   double currentValue = 0;
   int nbConsecutiveSameValue = 0;

   int nbValuesFound = 0;

// kijun sen horizontal lines
   for(int i=0; i<nb; i++)
      //for(int i=0; i<nbk-minNumberOfSameConsecutiveValuesNeeded_KS; i++)
     {
      if(sIchimokuLineToProcess == 'k')
         currentValue = kijun_sen_buffer[i];
      else
         if(sIchimokuLineToProcess == 't')
            currentValue = tenkan_sen_buffer[i];
         else
            if(sIchimokuLineToProcess == 'b')
               currentValue = senkou_span_b_buffer[i];
            else
               if(sIchimokuLineToProcess == 'a')
                  currentValue = senkou_span_a_buffer[i];

      if(currentValue == previousValue && currentValue != EMPTY_VALUE)
        {
         nbConsecutiveSameValue++;
         //printf("Increasing nb consecutive same value " + string(currentValue) + " ; nb = " + string(nbConsecutiveSameValue));
        }
      else
        {
         if(currentValue != previousValue)
           {
            if(nbConsecutiveSameValue >= minConsecutiveValues)
              {
               strPeriod = EnumToString(Period());
               StringReplace(strPeriod, "PERIOD_", "");
               //printf(strPeriod);

               nbValuesFound++;

               objectName = prefix + "_" + strPeriod + "_" + string(i) + "_" + mql_rates[i].time;

               //printf("Will draw a line at " + string(previousValue));
               res = ObjectCreate(cid, objectName, OBJ_HLINE, 0, 0, previousValue);
               if(res)
                 {
                  ObjectSetInteger(0, objectName, OBJPROP_COLOR, clrGray);
                  ObjectSetInteger(0, objectName, OBJPROP_STYLE, STYLE_DOT);
                  //ObjectSetInteger(0, prefix + strPeriod + i, OBJPROP_BACK, true); // background object
                 }
              }
            //printf("Current value has changed, now = " + string(currentValue));
            nbConsecutiveSameValue = 0;
           }
        }

      previousValue = currentValue;
     }

   printf("nbValues Found=" + string(nbValuesFound));

   ChartRedraw(cid);
   ChartNavigate(cid,CHART_END,0);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getTimestamp()
  {
   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp = string(mqd.year) + "_" + IntegerToString(mqd.mon, 2, '0') + "_" + IntegerToString(mqd.day, 2, '0') + "_" + IntegerToString(mqd.hour, 2, '0') + "_" + IntegerToString(mqd.min,2,'0') + "_" + IntegerToString(mqd.sec, 2, '0') + "_" +GetTickCount();
   return timestamp;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void log(string str)
  {
   if(!enableLogs)
      return;
   printf(str);
   file_handle = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_ANSI|FILE_COMMON);
   if(file_handle > 0)
     {
      FileSeek(file_handle, 0, SEEK_END);
      FileWrite(file_handle, getTimestamp() + " : " + str);
      FileFlush(file_handle);
      FileClose(file_handle);
     }
  }
//+------------------------------------------------------------------+
