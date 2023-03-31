//+------------------------------------------------------------------+
//|                                    IchimokuUltimateScannerEA.mq5 |
//|                       Copyright 2018, InvestdataSystems@Yahoo.Com|
//|                             https://ichimoku-expert.blogspot.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2018, Investdata Systems"
#property link      "https://ichimoku-expert.blogspot.com"
#property version   "5.3"

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

#include <Controls\Dialog.mqh>
#include <Controls\ListView.mqh>
#include <Controls\Label.mqh>

CAppDialog cAppDialog;
CListView cListView;

CAccountInfo accountInfo;
double initialEquity = 0;
double currentEquity = 0;

input int scanPeriod = 10;
input bool onlySymbolsInMarketwatch = true;
input string symbolToIgnoreIfContains = "";
input bool runOnlyOnce = false;
input bool showProcessedSymbol = false;
input bool currentCurrencyOnly = false;
input bool sendNotifications = true;

string appVersion = "5.4";
string versionInfo = "2020 Version";

int file_handle = INVALID_HANDLE;

string filename = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
// C:\Users\IchimokuKinkoHyo\AppData\Roaming\MetaQuotes\Terminal\Common\Files
   string exportDir = TerminalInfoString(TERMINAL_COMMONDATA_PATH);
   printf("You will find the report in the following folder :");
   printf(exportDir + "\\Files\\");
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

   log("-----------------------------------------");
   log("https://finance.forumactif.com");
   log("https://ichimokuscanner.000webhostapp.com");
   log("Email: investdatasystems@yahoo.com");
   log("-----------------------------------------");

   /*cAppDialog.Create(0, "Controls", 0, 0, 0, 800, 250);
   cListView.Create(0, "ma liste", 0, 0, 0, 770, 220);
   cAppDialog.Add(cListView);

   cAppDialog.Activate();
   cAppDialog.Run();*/

   string output="";
   output = "Starting " + StringSubstr(__FILE__, 0, StringLen(__FILE__) - 4) + " " + appVersion;
   log(output);

//ObjectsDeleteAll(0, "", -1, -1);

   if(runOnlyOnce)
     {
      EventSetTimer(1);
     }
   else
     {
      printf("Scanning in loop ; Timer set to " + IntegerToString(scanPeriod) + " seconds.");
      EventSetTimer(scanPeriod); // 30 secondes pour tout (pas seulement marketwatch)
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string logArray[];
int logArrayIndex = 0;
void log(string str)
  {
   int size = ArraySize(logArray);

   bool found = false;
   for(int i=0; i<size; i++)
     {
      if((StringFind(logArray[i], str) != -1) /*&& (str != "*")*/)
        {
         found = true;
         break;
        }
     }

   if(found == false)
     {
      ArrayResize(logArray, size + 1);
      logArray[logArrayIndex++] = str;
      //printf("new array size = " + ArraySize(logArray));

      //printf("array size = " + size);
      //cListView.AddItem(str, 128);
      printf(str);
      if(sendNotifications)
         SendNotification(str);

      file_handle = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_ANSI|FILE_COMMON);
      if(file_handle > 0)
        {
         FileSeek(file_handle, 0, SEEK_END);
         FileWrite(file_handle, getTimestamp() + " : " + str);
         FileFlush(file_handle);
         FileClose(file_handle);
        }
     }
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
//cAppDialog.Destroy(reason);
   FileClose(file_handle);
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   ArrayFree(time_as_series);
   ArrayFree(logArray);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//Ichimoku();
   if(!initdone)
      return;

   if(currentCurrencyOnly)
     {
      string sname = Symbol();
      int sindex = 0;
     }
   else
     {
      // Multicurrency
      stotal = SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)

      for(int sindex = 0; sindex < stotal; sindex++)
        {
         bool ok = false;

         string sname = SymbolName(sindex, onlySymbolsInMarketwatch);

         if(symbolToIgnoreIfContains != "")
           {
            if(StringFind(sname, symbolToIgnoreIfContains) != -1)
              {
               log("Ignoring : " + sname);
               continue;
              }
           }

        }

     }

   return;
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
datetime allowed_until = D'2020.12.31 23:59';
bool expiration_notified = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool done = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(TimeCurrent() > allowed_until)
     {
      if(expiration_notified == false)
        {
         string output = StringSubstr(__FILE__, 0, StringLen(__FILE__) - 4) + " " + appVersion + " : EXPIRED.\r\nPlease contact Investdata Systems \r\ninvestdatasystems@yahoo.com";
         log(output);
         SendNotification(output);
         MessageBox(output, "IUSCannerEA", 0);
         expiration_notified = true;
        }
      return;
     }

   if(runOnlyOnce)
     {
      log("Running mode : Run Only Once.");
      Ichimoku();
      EventKillTimer();
     }
   else
     {
      Ichimoku();
     }
  }

static int BARS;
bool first_run_done[];
static datetime LastBarTime[];//=-1;

int maxhisto = 32;

bool initdone = false;
int stotal = 0;
bool debug = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ichimoku()
  {

   int processingStart = GetTickCount();

   int stotal = SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)
   for(int sindex = 0; sindex < stotal; sindex++)
     {
      string sname = SymbolName(sindex, onlySymbolsInMarketwatch);
      //if(StringFind(sname, "EUR")!=-1)
      //{
      //process(sname, PERIOD_M1);
      //process(sname, PERIOD_M2);
      //process(sname, PERIOD_M3);
      //process(sname, PERIOD_M4);
      process(sname, PERIOD_M5);
      //process(sname, PERIOD_M6);
      //process(sname, PERIOD_M10);
      //process(sname, PERIOD_M12);
      process(sname, PERIOD_M15);
      //process(sname, PERIOD_M30);
      process(sname, PERIOD_H1);
      //process(sname, PERIOD_H2);
      //process(sname, PERIOD_H3);
      process(sname, PERIOD_H4);
      //process(sname, PERIOD_H6);
      //process(sname, PERIOD_H8);
      //process(sname, PERIOD_H12);
      process(sname, PERIOD_D1);
      //process(sname, PERIOD_W1);
      //process(sname, PERIOD_MN1);
      //log("*");
      //}
     }

   int processingEnd = GetTickCount();
   int processingDelta = processingEnd-processingStart;
   if(processingDelta > 0)
     {
      int seconds = processingDelta/1000;
      string output = StringSubstr(__FILE__, 0, StringLen(__FILE__) - 4) + " (" + EnumToString(Period()) + ") : Total processing time = " + IntegerToString(processingDelta) + "ms = " + IntegerToString(seconds) + "s";
      output += " Memory used = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE));
      output += " Memory total = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_TOTAL));
      //log(output);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

double tenkan_sen_buffer[];
double kijun_sen_buffer[];
double senkou_span_a_buffer[];
double senkou_span_b_buffer[];
double chikou_span_buffer[];

double open_array[];
double high_array[];
double low_array[];
double close_array[];

datetime time_as_series[];

datetime trade_time;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void process(string sname, ENUM_TIMEFRAMES period)
  {
   /*double tenkan_sen_buffer[];
   double kijun_sen_buffer[];
   double senkou_span_a_buffer[];
   double senkou_span_b_buffer[];
   double chikou_span_buffer[];

   double open_array[];
   double high_array[];
   double low_array[];
   double close_array[];*/

   int tenkan_sen = 9;              // period of Tenkan-sen
   int kijun_sen = 26;              // period of Kijun-sen
   int senkou_span_b = 52;          // period of Senkou Span B

   ArraySetAsSeries(tenkan_sen_buffer, true);
   ArraySetAsSeries(kijun_sen_buffer, true);
   ArraySetAsSeries(senkou_span_a_buffer, true);
   ArraySetAsSeries(senkou_span_b_buffer, true);
   ArraySetAsSeries(chikou_span_buffer, true);

   ArraySetAsSeries(open_array, true);
   ArraySetAsSeries(high_array, true);
   ArraySetAsSeries(low_array, true);
   ArraySetAsSeries(close_array, true);

   ArraySetAsSeries(time_as_series, true);

   int handle;
   handle = iIchimoku(sname, period, tenkan_sen, kijun_sen, senkou_span_b);

   if(handle != INVALID_HANDLE)
     {
      int max = maxhisto;

      int nbt=-1, nbk=-1, nbssa=-1, nbssb=-1, nbc=-1;
      nbt = CopyBuffer(handle, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
      nbk = CopyBuffer(handle, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
      nbssa = CopyBuffer(handle, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
      nbssb = CopyBuffer(handle, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
      nbc = CopyBuffer(handle,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

      int numO=-1, numH=-1, numL=-1, numC=-1;
      numO = CopyOpen(sname, period, 0, max, open_array);
      numH = CopyHigh(sname, period, 0, max, high_array);
      numL = CopyLow(sname, period, 0, max, low_array);
      numC = CopyClose(sname, period, 0, max, close_array);

      int copied = CopyTime(sname, period, 0, max, time_as_series);
      //printf("time_as_series[0] = " + time_as_series[0]);


      string priceData = " --- ASK/BUY = " + getAskPriceForSymbol(sname) + " --- BID/SELL = " + getBidPriceForSymbol(sname) + " --- KIJUN = " + DoubleToString(getKijunSen(0, kijun_sen_buffer));

      if(JCSHasCrossedOverKumo(-1, senkou_span_a_buffer, senkou_span_b_buffer, open_array, close_array))
        {
         //log(sname + " : CURR japanese candlestick HAS CROSSED OVER kumo on candlestick of " + time_as_series[0] + " in " + StringSubstr(EnumToString(period), 7));
         if(LaggingSpanIsFreeUp(senkou_span_a_buffer, senkou_span_b_buffer, chikou_span_buffer, tenkan_sen_buffer, kijun_sen_buffer, open_array, close_array, high_array, low_array))
           {
            //log(sname + " : *** And Chikou Span is Free Up in " + StringSubstr(EnumToString(period), 7));
            if(PriceIsFreeUp(-1, senkou_span_a_buffer, senkou_span_b_buffer, chikou_span_buffer, tenkan_sen_buffer, kijun_sen_buffer, open_array, close_array, high_array, low_array))
              {
               if(JCSIsOverKumo(0, senkou_span_a_buffer, senkou_span_b_buffer, open_array, close_array))
                 {
                  //log(sname + " : PREV japanese candlestick HAS CROSSED OVER kumo on candlestick of " + time_as_series[1] + " in " + StringSubstr(EnumToString(period), 7));
                  //log(sname + " : *** And Chikou Span is Free Up in " + StringSubstr(EnumToString(period), 7));
                  //log(sname + " : *** And Price is FREE UP in " + StringSubstr(EnumToString(period), 7));
                  //log(sname + " : *** And CURR japanese candlestick is OVER kumo on candlestick of " + time_as_series[0] + " in " + StringSubstr(EnumToString(period), 7));
                  if (trade_time == "1970.01.01 00:00:00")
                  {
                     BUY(sname);
                     trade_time = time_as_series[0];
                  }
                  else
                  {
                     if (PositionsTotal() == 0)
                     {
                        if (time_as_series[0] != trade_time) 
                        {
                           BUY(sname);
                           trade_time = time_as_series[0];                          
                        }                        
                     }
                  } 
                 

                 }
              }
           }
        }

      if(JCSHasCrossedUnderKumo(-1, senkou_span_a_buffer, senkou_span_b_buffer, open_array, close_array))
        {
         //log(sname + " : CURR japanese candlestick HAS CROSSED UNDER kumo on candlestick of " + time_as_series[0] + " in " + StringSubstr(EnumToString(period), 7));
         if(LaggingSpanIsFreeDown(senkou_span_a_buffer, senkou_span_b_buffer, chikou_span_buffer, tenkan_sen_buffer, kijun_sen_buffer, open_array, close_array, high_array, low_array))
           {
            //log(sname + " : *** And Chikou Span is Free Down in " + StringSubstr(EnumToString(period), 7));
            if(PriceIsFreeDown(-1, senkou_span_a_buffer, senkou_span_b_buffer, chikou_span_buffer, tenkan_sen_buffer, kijun_sen_buffer, open_array, close_array, high_array, low_array))
              {
               //log(sname + " : Price is FREE DOWN in " + StringSubstr(EnumToString(period), 7) + priceData);
               if(LaggingSpanIsFreeDown(senkou_span_a_buffer, senkou_span_b_buffer, chikou_span_buffer, tenkan_sen_buffer, kijun_sen_buffer, open_array, close_array, high_array, low_array))
                 {
                  if(JCSIsUnderKumo(0, senkou_span_a_buffer, senkou_span_b_buffer, open_array, close_array))
                    {
                     //log(sname + " : PREV japanese candlestick HAS CROSSED UNDER kumo on candlestick of " + time_as_series[1] + " in " + StringSubstr(EnumToString(period), 7));
                     //log(sname + " : *** And Chikou Span is Free Down in " + StringSubstr(EnumToString(period), 7));
                     //log(sname + " : *** And Price and Chikou Span (Lagging Span) are FREE DOWN in " + StringSubstr(EnumToString(period), 7));
                     //log(sname + " : *** And CURR japanese candlestick is UNDER kumo on candlestick of " + time_as_series[0] + " in " + StringSubstr(EnumToString(period), 7));
                    }
                 }
              }
           }
        }

      // fin traitements détection

      ArrayFree(open_array);
      ArrayFree(close_array);
      ArrayFree(high_array);
      ArrayFree(low_array);

      ArrayFree(tenkan_sen_buffer);
      ArrayFree(kijun_sen_buffer);
      ArrayFree(senkou_span_a_buffer);
      ArrayFree(senkou_span_b_buffer);
      ArrayFree(chikou_span_buffer);

     }


  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool JCSIsOverKumo(
   int n,
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &open_array[],
   double &close_array[]
)
  {
   if(n<0)
      n = -n;

   if(senkou_span_a_buffer[n] > senkou_span_b_buffer[n])
     {
      if(open_array[n] > senkou_span_a_buffer[n] && close_array[n] > senkou_span_a_buffer[n])
        {
         return true;
        }
     }

   if(senkou_span_b_buffer[n] > senkou_span_a_buffer[n])
     {
      if(open_array[n] > senkou_span_b_buffer[n] && close_array[n] > senkou_span_b_buffer[n])
        {
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool JCSIsUnderKumo(
   int n,
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &open_array[],
   double &close_array[]
)
  {
   if(n<0)
      n = -n;

   if(senkou_span_a_buffer[n] > senkou_span_b_buffer[n])
     {
      if(open_array[n] < senkou_span_b_buffer[n] && close_array[n] < senkou_span_b_buffer[n])
        {
         return true;
        }
     }

   if(senkou_span_b_buffer[n] > senkou_span_a_buffer[n])
     {
      if(open_array[n] < senkou_span_a_buffer[n] && close_array[n] < senkou_span_a_buffer[n])
        {
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool JCSHasCrossedOverKumo(
   int n,
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &open_array[],
   double &close_array[]
)
  {
   if(n<0)
      n = -n;

   if(senkou_span_a_buffer[n] > senkou_span_b_buffer[n])
     {
      if(open_array[n] < senkou_span_a_buffer[n] && close_array[n] > senkou_span_a_buffer[n])
        {
         return true;
        }
     }

   if(senkou_span_b_buffer[1] > senkou_span_a_buffer[1])
     {
      if(open_array[n] < senkou_span_b_buffer[n] && close_array[n] > senkou_span_b_buffer[n])
        {
         return true;
        }
     }

   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool JCSHasCrossedUnderKumo(
   int n,
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &open_array[],
   double &close_array[]
)
  {
   if(n<0)
      n = -n;

   if(senkou_span_a_buffer[n] > senkou_span_b_buffer[n])
     {
      if(open_array[n] > senkou_span_b_buffer[n] && close_array[n] < senkou_span_b_buffer[n])
        {
         return true;
        }
     }

   if(senkou_span_b_buffer[n] > senkou_span_a_buffer[n])
     {
      if(open_array[n] > senkou_span_a_buffer[n] && close_array[n] < senkou_span_a_buffer[n])
        {
         return true;
        }
     }

   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LaggingSpanIsFreeUp(
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &chikou_span_buffer[],
   double &tenkan_sen_buffer[],
   double &kijun_sen_buffer[],
   double &open_array[],
   double &close_array[],
   double &high_array[],
   double &low_array[]
)
  {
   if(
      (chikou_span_buffer[26]>senkou_span_a_buffer[26])
      && (chikou_span_buffer[26]>senkou_span_b_buffer[26])
      && (chikou_span_buffer[26]>tenkan_sen_buffer[26])
      && (chikou_span_buffer[26]>kijun_sen_buffer[26])
      && (chikou_span_buffer[26]>close_array[26])
      && (chikou_span_buffer[26]>open_array[26])
      && (chikou_span_buffer[26]>close_array[26])
      && (chikou_span_buffer[26]>high_array[26])
      && (chikou_span_buffer[26]>low_array[26])
   )
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LaggingSpanIsFreeDown(
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &chikou_span_buffer[],
   double &tenkan_sen_buffer[],
   double &kijun_sen_buffer[],
   double &open_array[],
   double &close_array[],
   double &high_array[],
   double &low_array[]
)
  {
   if(
      (chikou_span_buffer[26]<senkou_span_a_buffer[26])
      && (chikou_span_buffer[26]<senkou_span_b_buffer[26])
      && (chikou_span_buffer[26]<tenkan_sen_buffer[26])
      && (chikou_span_buffer[26]<kijun_sen_buffer[26])
      && (chikou_span_buffer[26]<close_array[26])
      && (chikou_span_buffer[26]<open_array[26])
      && (chikou_span_buffer[26]<close_array[26])
      && (chikou_span_buffer[26]<high_array[26])
      && (chikou_span_buffer[26]<low_array[26])
   )
     {
      return true;
     }

   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool JCSHasCrossedOverKijun(
   int n,
   double &kijun_sen_buffer[],
   double &open_array[],
   double &close_array[]
)
  {

   if(n<0)
      n = -n;

   if(
      open_array[n] < kijun_sen_buffer[n]
      && close_array[n] > kijun_sen_buffer[n]
   )
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool JCSHasCrossedUnderKijun(
   int n,
   double &kijun_sen_buffer[],
   double &open_array[],
   double &close_array[]
)
  {

   if(n<0)
      n = -n;

   if(
      open_array[n] > kijun_sen_buffer[n]
      && close_array[n] < kijun_sen_buffer[n]
   )
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool JCSIsOverKijun(
   int n,
   double &kijun_sen_buffer[],
   double &open_array[],
   double &close_array[]
)
  {
   if(n<0)
      n = -n;

   if(
      open_array[n] > kijun_sen_buffer[n]
      && close_array[n] > kijun_sen_buffer[n]
   )
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool JCSIsUnderKijun(
   int n,
   double &kijun_sen_buffer[],
   double &open_array[],
   double &close_array[]
)
  {
   if(n<0)
      n = -n;

   if(
      open_array[n] < kijun_sen_buffer[n]
      && close_array[n] < kijun_sen_buffer[n]
   )
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceIsFreeUp(
   int n,
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &chikou_span_buffer[],
   double &tenkan_sen_buffer[],
   double &kijun_sen_buffer[],
   double &open_array[],
   double &close_array[],
   double &high_array[],
   double &low_array[]
)
  {

   if(n<0)
      n = -n;

   if(
      (close_array[n]>senkou_span_a_buffer[n])
      && (close_array[n]>senkou_span_b_buffer[n])
      && (close_array[n]>tenkan_sen_buffer[n])
      && (close_array[n]>kijun_sen_buffer[n])
   )
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceIsFreeDown(
   int n,
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &chikou_span_buffer[],
   double &tenkan_sen_buffer[],
   double &kijun_sen_buffer[],
   double &open_array[],
   double &close_array[],
   double &high_array[],
   double &low_array[]
)
  {

   if(n<0)
      n = -n;

   if(
      (close_array[n]<senkou_span_a_buffer[n])
      && (close_array[n]<senkou_span_b_buffer[n])
      && (close_array[n]<tenkan_sen_buffer[n])
      && (close_array[n]<kijun_sen_buffer[n])
   )
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool KijunIsOverKumo(
   int n,
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &kijun_sen_buffer[]
)
  {

   if(n<0)
      n = -n;

   if(senkou_span_a_buffer[n] > senkou_span_b_buffer[n])
     {
      if(kijun_sen_buffer[n] > senkou_span_a_buffer[n])
        {
         return true;
        }
     }

   if(senkou_span_b_buffer[n] > senkou_span_a_buffer[n])
     {
      if(kijun_sen_buffer[n] > senkou_span_b_buffer[n])
        {
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool KijunIsUnderKumo(
   int n,
   double &senkou_span_a_buffer[],
   double &senkou_span_b_buffer[],
   double &kijun_sen_buffer[]
)
  {

   if(n<0)
      n = -n;

   if(senkou_span_a_buffer[n] > senkou_span_b_buffer[n])
     {
      if(kijun_sen_buffer[n] < senkou_span_b_buffer[n])
        {
         return true;
        }
     }

   if(senkou_span_b_buffer[n] > senkou_span_a_buffer[n])
     {
      if(kijun_sen_buffer[n] < senkou_span_a_buffer[n])
        {
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getKijunSen(
   int n,
   double &kijun_sen_buffer[]
)
  {
   if(n<0)
      n = -n;

   return kijun_sen_buffer[n];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getAskPriceForSymbol(string sname)
  {
   MqlTick lasttick;
   SymbolInfoTick(sname, lasttick);
   double spread = lasttick.ask - lasttick.bid; // spread = prix de vente - prix d'achat
   double ask = SymbolInfoDouble(sname, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sname, SYMBOL_BID);
   return ask;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getBidPriceForSymbol(string sname)
  {
   MqlTick lasttick;
   SymbolInfoTick(sname, lasttick);
   double spread = lasttick.ask - lasttick.bid; // spread = prix de vente - prix d'achat
   double ask = SymbolInfoDouble(sname, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sname, SYMBOL_BID);
   return bid;
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BUY(string symbol,double takeprofit_pips=0.00050, double stoploss_pips=0.0200)
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
