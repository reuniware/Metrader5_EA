//+------------------------------------------------------------------+
//|                                        IchimokuScannerMT5_V2.mq5 |
//|                                Copyright 2018, InvestDataSystems |
//|                 https://tradingbot.wixsite.com/robots-de-trading |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, InvestDataSystems"
#property link      "https://tradingbot.wixsite.com/robots-de-trading"
#property version   "1.00"


double tenkan_sen_buffer[];
double kijun_sen_buffer[];
double senkou_span_a_buffer[];
double senkou_span_b_buffer[];
double chikou_span_buffer[];

double open_array[];
double high_array[];
double low_array[];
double close_array[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int filehandle = INVALID_HANDLE;
string filename="";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   filename = getTimeStamp() + "_" + "IchimokuScannerMT5_V2.csv";
   printf("Log filename = " + filename);
   printf("File created in = " + TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\");
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void log(string str)
  {
   if(!FileIsExist(filename))
     {
      //FileDelete(filename);
      filehandle=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_CSV);
      FileWrite(filehandle,"TimeStamp;Symbol;Bid;Ask;OverKumo;ChikouFree;CrossedOverSSB;CrossedOverKijun;OverKijun;RSI");
     }
   else
     {
      filehandle=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_CSV);
      FileSeek(filehandle,0,SEEK_END);
     }
   FileWrite(filehandle,str);
   FileClose(filehandle);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
bool done=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input bool onlySymbolsInMarketwatch=true;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string sname="";
string finalString="";
string csvline="";
ENUM_TIMEFRAMES workingTimeframe;

datetime allowed_until=D'2018.08.15 00:00';
bool expiration_notified=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
     if(TimeCurrent()>allowed_until)
     {
      if(expiration_notified==false)
        {
         string output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" : LICENSE EXPIRED. Please contact Investdata Systems at investdatasystems@yahoo.com";
         printf(output);
         SendNotification(output);
         expiration_notified=true;
        }
      return;
     }

   if(done==false)
     {

      EventKillTimer();

      printf("Processing start at (Trade Server Time) "+TimeToString(TimeTradeServer())+" ; (Local Machine Time) "+TimeToString(TimeLocal())+" ; (GMT Time) "+TimeToString(TimeGMT()));

      //   while(true){

      int stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)

      for(int sindex=0; sindex<stotal; sindex++)
        {
         sname=SymbolName(sindex,onlySymbolsInMarketwatch);

         finalString="";

         csvline=TimeToString(TimeLocal())+";"+sname+";"+DoubleToString(SymbolInfoDouble(sname,SYMBOL_BID))+";"+DoubleToString(SymbolInfoDouble(sname,SYMBOL_ASK))+";";

         // Vérifier si le prix est au-dessus du Kumo

         workingTimeframe=PERIOD_M1;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M2;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M3;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M4;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M5;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M6;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M10;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M12;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M15;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M20;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M30;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H1;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H2;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H3;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H4;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H6;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H8;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_D1;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_W1;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

/*workingTimeframe=PERIOD_MN1;
         if(PriceIsOverKumo(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";
         */

         if(finalString!="") printf(sname+" is over Kumo in : "+finalString);
         csvline=csvline+finalString+";";

         // Vérifier si la Chikou Span est libre de tout obstacle

         finalString="";

         workingTimeframe=PERIOD_M1;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M2;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M3;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M4;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M5;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M6;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M10;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M12;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M15;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M20;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M30;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H1;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H2;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H3;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H4;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H6;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H8;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_D1;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_W1;
         if(ChikouSpanIsFree(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         if(finalString!="") printf(sname+" has Chikou Span free in : "+finalString);
         csvline=csvline+finalString+";";

         // Vérifier si le cours est passé au-dessus de la SSB

         finalString="";

         workingTimeframe=PERIOD_M1;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M2;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M3;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M4;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M5;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M6;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M10;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M12;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M15;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M20;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M30;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H1;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H2;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H3;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H4;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H6;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H8;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_D1;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_W1;
         if(PriceCrossedKumoSsbUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         if(finalString!="") printf(sname+" crossed Kumo SSB while up in : "+finalString);
         csvline=csvline+finalString+";";

         // Vérifier si le prix est passé au-dessus de la Kijun Sen

         finalString="";

         workingTimeframe=PERIOD_M1;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M2;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M3;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M4;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M5;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M6;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M10;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M12;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M15;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M20;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M30;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H1;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H2;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H3;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H4;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H6;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H8;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_D1;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_W1;
         if(PriceCrossedKijunUp(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         if(finalString!="") printf(sname+" crossed Kijun while up in : "+finalString);
         csvline=csvline+finalString+";";

         // Vérifier si le prix est au-dessus de la Kijun Sen

         finalString="";

         workingTimeframe=PERIOD_M1;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M2;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M3;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M4;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M5;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M6;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M10;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M12;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M15;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M20;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_M30;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H1;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H2;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H3;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H4;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H6;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_H8;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_D1;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         workingTimeframe=PERIOD_W1;
         if(PriceIsOverKijun(sname,workingTimeframe)==true) finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+" ";

         if(finalString!="") printf(sname+" is over Kijun in : "+finalString);
         csvline=csvline+finalString+";";

         // Obtenir les RSI

         finalString="";

         workingTimeframe=PERIOD_M1;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M2;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M3;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M4;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M5;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M6;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M10;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M12;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M15;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M20;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_M30;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_H1;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_H2;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_H3;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_H4;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_H6;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_H8;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_D1;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         workingTimeframe=PERIOD_W1;
         finalString=finalString+StringSubstr(EnumToString(workingTimeframe),7)+"="+getRSI(sname,workingTimeframe)+" ";

         printf(sname+" RSI : "+finalString);
         csvline=csvline+finalString+";";
         log(csvline);

         printf("");

        }

      //} //while

      done=true;

      printf("Processing end");

      FileClose(filehandle);

     }

  }
//+------------------------------------------------------------------+
void onTimer()
  {

  }
//+------------------------------------------------------------------+

int tenkan_sen_param = 9;              // period of Tenkan-sen
int kijun_sen_param = 26;              // period of Kijun-sen
int senkou_span_b_param = 52;          // period of Senkou Span B
int handleIchimoku=INVALID_HANDLE;
int max;
int nbt=-1,nbk=-1,nbssa=-1,nbssb=-1,nbc=-1;
int numO=-1,numH=-1,numL=-1,numC=-1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceIsOverKumo(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   result=false;

// Obtenir les données Ichimoku

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

   if(open_array[1]>senkou_span_a_buffer[1]
      && open_array[1]>senkou_span_b_buffer[1]
      && close_array[1]>senkou_span_a_buffer[1]
      && close_array[1]>senkou_span_b_buffer[1]
      )
      result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return result;
  }
//+------------------------------------------------------------------+

bool ChikouSpanIsFree(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=32;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

//(chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])

   if(chikou_span_buffer[26]>senkou_span_a_buffer[26]
      && chikou_span_buffer[26]>senkou_span_b_buffer[26]
      && chikou_span_buffer[26]>tenkan_sen_buffer[26]
      && chikou_span_buffer[26]>kijun_sen_buffer[26]
      && chikou_span_buffer[26]>open_array[26]
      && chikou_span_buffer[26]>close_array[26]
      )
      result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return result;
  }
//+------------------------------------------------------------------+

bool PriceCrossedKumoSsbUp(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

//(chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])

   if(
      (open_array[1]<senkou_span_b_buffer[1] && close_array[1]>senkou_span_b_buffer[1])
      || (open_array[2]<senkou_span_b_buffer[2] && close_array[2]<senkou_span_b_buffer[2] && open_array[1]>senkou_span_b_buffer[1] && close_array[1]>senkou_span_b_buffer[1])
      || (open_array[2]<senkou_span_b_buffer[2] && close_array[2]<senkou_span_b_buffer[2] && open_array[1]<senkou_span_b_buffer[1] && close_array[1]>senkou_span_b_buffer[1])
      || (open_array[2]<senkou_span_b_buffer[2] && close_array[2]>senkou_span_b_buffer[2] && open_array[1]>senkou_span_b_buffer[1] && close_array[1]>senkou_span_b_buffer[1])
      )
      result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return result;
  }

bool result;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceCrossedKijunUp(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

//(chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])

   if(
      (open_array[1]<kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[2]<kijun_sen_buffer[2] && close_array[2]<kijun_sen_buffer[2] && open_array[1]>kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[2]<kijun_sen_buffer[2] && close_array[2]<kijun_sen_buffer[2] && open_array[1]<kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[2]<kijun_sen_buffer[2] && close_array[2]>kijun_sen_buffer[2] && open_array[1]>kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      )
      result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceIsOverKijun(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=8;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,max,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,max,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,max,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,max,close_array);

// Traitements ici

//(chikou_span_bufferM15[26]>senkou_span_a_bufferM5[26])

   if(open_array[1]>kijun_sen_buffer[1]
      && open_array[1]>kijun_sen_buffer[1]
      && close_array[1]>kijun_sen_buffer[1]
      && close_array[1]>kijun_sen_buffer[1]
      )
      result=true;

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int handleRsi=INVALID_HANDLE;
double iRSIBuffer[];
int resultRsi;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getRSI(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   handleRsi=iRSI(Symbol,TimeFrame,14,PRICE_CLOSE);

   ArraySetAsSeries(iRSIBuffer,true);
   CopyBuffer(handleRsi,0,0,3,iRSIBuffer);

   resultRsi=(int) iRSIBuffer[0];

   ArrayFree(iRSIBuffer);
   IndicatorRelease(handleRsi);

   return "["+IntegerToString(resultRsi)+"]";
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ScanForHorizontalLines(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=64;

   nbt=-1;nbk=-1;nbssa=-1;nbssb=-1;nbc=-1;
   nbt = CopyBuffer(handleIchimoku, TENKANSEN_LINE, 0, max, tenkan_sen_buffer);
   nbk = CopyBuffer(handleIchimoku, KIJUNSEN_LINE, 0, max, kijun_sen_buffer);
   nbssa = CopyBuffer(handleIchimoku, SENKOUSPANA_LINE, 0, max, senkou_span_a_buffer);
   nbssb = CopyBuffer(handleIchimoku, SENKOUSPANB_LINE, 0, max, senkou_span_b_buffer);
   nbc=CopyBuffer(handleIchimoku,CHIKOUSPAN_LINE,0,max,chikou_span_buffer);

// Obtenir les données bougies japonaises
   numO=-1;numH=-1;numL=-1;numC=-1;
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   numO=CopyOpen(Symbol,TimeFrame,0,32,open_array);
   numH=CopyHigh(Symbol,TimeFrame,0,32,high_array);
   numL=CopyLow(Symbol,TimeFrame,0,32,low_array);
   numC=CopyClose(Symbol,TimeFrame,0,32,close_array);

// Traitements ici

   for(int i=0;i<max-3;i++)
     {
      if(kijun_sen_buffer[i]==kijun_sen_buffer[i+1] && kijun_sen_buffer[i+1]==kijun_sen_buffer[i+2])
        {
         printf("Horizontal Kijun Sen level detected in "+StringSubstr(EnumToString(TimeFrame),7)+" = "+DoubleToString(kijun_sen_buffer[i]));
        }
     }

// Libération mémoire   
   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   ArrayFree(tenkan_sen_buffer);
   ArrayFree(kijun_sen_buffer);
   ArrayFree(senkou_span_a_buffer);
   ArrayFree(senkou_span_b_buffer);
   ArrayFree(chikou_span_buffer);

   IndicatorRelease(handleIchimoku);

  }
//+------------------------------------------------------------------+

MqlDateTime mqd;
string getTimeStamp()
{
   TimeCurrent(mqd);
   return string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');
}
