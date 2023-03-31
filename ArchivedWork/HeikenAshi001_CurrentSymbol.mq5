//+-----------------------------------------------------------------+
//|                                     IchimokuExperimental005.mq5 |
//|                      Copyright 2017, investdatasystems@yahoo.com|
//|                            https://ichimoku-expert.blogspot.com |
//+-----------------------------------------------------------------+

//IchimokuExperimental006_MultiCurrency.mq5

#property copyright "Copyright 2017, Investdata Systems"
#property link      "https://ichimoku-expert.blogspot.com"
#property version   "1.01"

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

CAccountInfo accountInfo;
double initialEquity = 0;
double currentEquity = 0;

input bool exportPrices=false;
int file_handle=INVALID_HANDLE; // File handle
input int scanPeriod=15;
input bool onlySymbolsInMarketwatch=true;
input string symbolToIgnore="EURCZK";
input bool disableUploadHistory=true;
input double tradedLots=1;

// TODO : Gérer plusieurs symboles séparés par des virgules

string appVersion="3.0";
string versionInfo="Experimental May 2017";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//CloseAllPositions();

   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0');

   string output="";
   output = timestamp + " Starting " + StringSubstr(__FILE__,0,StringLen(__FILE__)-4) + " " + appVersion + " Investdata Systems";
   output = output + " Version info : " + versionInfo;
   output = output + " https://ichimoku-ea.000webhostapp.com/";
   printf(output);
//SendNotification(output);

   ObjectsDeleteAll(0,"",-1,-1);

   EventSetTimer(scanPeriod); // 30 secondes pour tout (pas seulement marketwatch)

   initialEquity=accountInfo.Equity();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   EventKillTimer();

  }
//ENUM_TIMEFRAMES workingPeriod=PERIOD_M15;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   return;
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
datetime allowed_until=D'2017.06.16 00:00';
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
         string output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" "+appVersion+" : EXPIRED. Please contact Investdata Systems ";
         printf(output);
         SendNotification(output);
         expiration_notified=true;
        }
      return;
     }

   Ichimoku();
  }

static int BARS;

bool first_run_done[];

static datetime LastBarTime=-1;//[];//=-1;

int maxhisto=64;

bool initdone=false;
int stotal=0;
//bool onlySymbolsInMarketwatch=true;
//datetime allowed_until = D'2016.01.15 00:00';
//bool expiration_notified = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ichimoku()
  {
//printf("ichimoku");
   int tenkan_sen = 9;              // period of Tenkan-sen
   int kijun_sen = 26;              // period of Kijun-sen
   int senkou_span_b = 52;          // period of Senkou Span B

//--- indicator buffer
   double tenkan_sen_bufferH4[];
   double kijun_sen_bufferH4[];
   double senkou_span_a_bufferH4[];
   double senkou_span_b_bufferH4[];
   double chikou_span_bufferH4[];

   ArraySetAsSeries(tenkan_sen_bufferH4,true);
   ArraySetAsSeries(kijun_sen_bufferH4,true);
   ArraySetAsSeries(senkou_span_a_bufferH4,true);
   ArraySetAsSeries(senkou_span_b_bufferH4,true);
   ArraySetAsSeries(chikou_span_bufferH4,true);


   if(!initdone)
     {
      stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)

      ArrayResize(first_run_done,stotal,stotal);
      //ArrayResize(LastBarTime,stotal,stotal);

      //initialisation de tout le tableau à false car sinon la première valeur vaut true par défaut (bug?).
      for(int sindex=0; sindex<stotal; sindex++)
        {
         first_run_done[sindex]=false;
         //LastBarTime[sindex]=-1;
        }

      initdone=true;
     }

   int processingStart=GetTickCount();
   string output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" ("+EnumToString(Period())+")";
   output+=" Processing start = "+IntegerToString(processingStart);
   printf(output);

//for(int sindex=0; sindex<stotal; sindex++)
//{
   bool ok=false;

   string sname=Symbol();//SymbolName(sindex,onlySymbolsInMarketwatch);

                         //printf("Bars = " + Bars(sname, workingPeriod));
   datetime ThisBarTime=(datetime) SeriesInfoInteger(sname,PERIOD_M1,SERIES_LASTBAR_DATE);
   if(ThisBarTime==LastBarTime/*[sindex]*/)
     {
      //printf("Same bar time (" + sname + ")");
     }
   else
     {
      if(LastBarTime/*[sindex]*/==-1)
        {
         //printf("First bar (" + sname + ")");
         LastBarTime/*[sindex]*/=ThisBarTime;
        }
      else
        {
         //printf("New bar time (" + sname + ")");
         LastBarTime/*[sindex]*/=ThisBarTime;
         ok=true;
        }
     }

   if(ok!=true)
     {
      return;
      //continue;
     }

// Ici est sur une nouvelle bougie !

   printf("new bar");

   MqlTick lasttick;
   double price;
   double sell;
   double buy;
   ulong vol;
   double spread;

   price= 0;
   sell = 0;
   buy=0;
   spread=0;
   vol=0;

   int handleH4;
   //handleH4=iIchimoku(sname, PERIOD_H4, tenkan_sen, kijun_sen, senkou_span_b);
   handleH4=iCustom(NULL,PERIOD_M1,"Examples\\Heiken_Ashi");
   if(handleH4!=INVALID_HANDLE)
     {
      printf("processing.");
      if(BarsCalculated(handleH4)>16)
        {
            printf("data available");
        } else {
            printf("not enough data available");
        }
      
      IndicatorRelease(handleH4);
     }
   else
     {
      printf(sname + " : ERROR : " + GetLastError());
     }
//}//fin boucle sur sindex

   int processingEnd=GetTickCount();
//printf("Processing end = "+IntegerToString(processingEnd));
   int processingDelta=processingEnd-processingStart;
   int seconds=processingDelta/1000;
   output=StringSubstr(__FILE__,0,StringLen(__FILE__)-4)+" ("+EnumToString(Period())+") : Total processing time = "+IntegerToString(processingDelta)+"ms = "+IntegerToString(seconds)+"s";
   output+= " Memory used = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE));
   output+= " Memory total = " + IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_TOTAL));
//printf(output);
//SendNotification(output);

// Si le déclenchement de cette fonction est fait depuis un OnTick, il est mieux d'avoir une temporisation ici
// Si le déclenchement est fait depuis un OnTimer, pas nécessaire
//Sleep(15000);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getTimeStamp()
  {
   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0')+"."+GetTickCount();
   return timestamp;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   CTrade trade;
   int i=PositionsTotal()-1;
   while(i>=0)
     {
      if(trade.PositionClose(PositionGetSymbol(i))) i--;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BUY(string symbol, double takeprofit_pips = 0.00250, double stoploss_pips = 0.01000)
  {
   MqlTick lasttick;
   SymbolInfoTick(symbol,lasttick);
   double spread=lasttick.ask-lasttick.bid; // spread = prix de vente - prix d'achat
   double price = SymbolInfoDouble(symbol,SYMBOL_ASK);

   MqlTradeRequest request={0};
   MqlTradeResult  result={0};
   request.action=TRADE_ACTION_DEAL;                     // type of trade operation
   request.symbol=symbol;                                // symbol
   request.volume=tradedLots;                                     // volume of 0.1 lot
   request.type=ORDER_TYPE_BUY;                          // order type
   request.price=SymbolInfoDouble(symbol,SYMBOL_ASK);    // price for opening

                                                         //request.sl = price-(price/100)*2;
//request.tp = lasttick.bid+(lasttick.bid/100)/2;

   double stoploss=0,takeprofit=0;
   if(Digits()==5)
     {
      stoploss=price-stoploss_pips;
      takeprofit=lasttick.bid+spread+takeprofit_pips;
        } else {
      printf(symbol+":no ordersend because digits != 5");
      return false;
     }

   request.sl = stoploss;
   request.tp = takeprofit;
//request.deviation=5;                                     // allowed deviation from the price
//request.magic    =EXPERT_MAGIC;                          // MagicNumber of the order
   if(!OrderSend(request,result))
     {
      PrintFormat(symbol+":OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
      return false;
     }
   else
     {
      printf(symbol+":OrderSend ok");
      return true;
     }
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---

  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
  
   /*string desc=EnumToString(trans.type)+"\r\n";
   desc+="Symbol: "+trans.symbol+"\r\n";
   desc+="Deal ticket: "+(string)trans.deal+"\r\n";
   desc+="Deal type: "+EnumToString(trans.deal_type)+"\r\n";
   desc+="Order ticket: "+(string)trans.order+"\r\n";
   desc+="Order type: "+EnumToString(trans.order_type)+"\r\n";
   desc+="Order state: "+EnumToString(trans.order_state)+"\r\n";
   desc+="Order time type: "+EnumToString(trans.time_type)+"\r\n";
   desc+="Order expiration: "+TimeToString(trans.time_expiration)+"\r\n";
   desc+="Price: "+StringFormat("%G",trans.price)+"\r\n";
   desc+="Price trigger: "+StringFormat("%G",trans.price_trigger)+"\r\n";
   desc+="Stop Loss: "+StringFormat("%G",trans.price_sl)+"\r\n";
   desc+="Take Profit: "+StringFormat("%G",trans.price_tp)+"\r\n";
   desc+="Volume: "+StringFormat("%G",trans.volume)+"\r\n";
   printf(desc);*/
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   double ret=0.0;
   return(ret);
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
  {
  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
  {
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//bool disableUploadHistory = false
void uploadHistory(string timestamp,string name,double buy,double sell)
  {
   if(disableUploadHistory == true) return;

// "https://ichimoku-ea.000webhostapp.com/ichimoku-ea-v2/?upload_history="
   string cookie=NULL,headers;
   char post[],result[];

   string history=timestamp+";"+name+";"+DoubleToString(buy)+";"+DoubleToString(sell);

   string google_url="https://ichimoku-ea.000webhostapp.com/ichimoku-ea-v2/?upload_history="+history;
   int timeout=2500; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   int res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
   if(res==-1)
     {
      Print("WebRequest error code=",GetLastError()+" - "+name+" - "+timestamp);
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      //MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
      Sleep(250);
     }
   else
     {
      //printf("WebRequest ok =" + CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      //printf("History sent successfully");
     }
//disableUploadHistory = true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void upload2JCSAlert(string timestamp,string period,string symbol,double buy,double sell,string h1_ls_validated,string m1_ls_validated)
  {
// "https://ichimoku-ea.000webhostapp.com/ichimoku-ea-v2/?upload_2jcs_alert=test"
   string cookie=NULL,headers;
   char post[],result[];

   string jcsalert=timestamp+";"+period+";"+symbol+";"+DoubleToString(buy)+";"+DoubleToString(sell)+";"+h1_ls_validated+";"+m1_ls_validated;

   string google_url="https://ichimoku-ea.000webhostapp.com/ichimoku-ea-v2/?upload_2jcs_alert="+jcsalert;
   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   int res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
   if(res==-1)
     {
      Print("Error in WebRequest. Error code  =",GetLastError());
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      //MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     }
   else
     {
      //printf(CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      printf("2JCS Alert sent successfully");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void uploadSSBAlert(string timestamp,string period,string name,string type,double price,double ssb)
  {
// "https://ichimoku-ea.000webhostapp.com/?notification=test"
   string cookie=NULL,headers;
   char post[],result[];

   string ssbalert=timestamp+";"+period+";"+name+";"+type+";"+DoubleToString(price)+";"+DoubleToString(ssb);

   string google_url="https://ichimoku-ea.000webhostapp.com/?upload_ssb_alert="+ssbalert;
   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   int res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
   if(res==-1)
     {
      Print("Error in WebRequest. Error code  =",GetLastError());
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      //MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     }
   else
     {
      //printf(CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      printf("SSB Alert sent successfully");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resetAllRemoteData()
  {
// "https://ichimoku-ea.000webhostapp.com/?notification=test"
   string cookie=NULL,headers;
   char post[],result[];
   string google_url="https://ichimoku-ea.000webhostapp.com/?reset_all=true";
   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   int res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
   if(res==-1)
     {
      Print("Error in WebRequest. Error code  =",GetLastError());
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      //MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     }
   else
     {
      printf(CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      printf("Reset command sent successfully");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resetSSBAlertsRemoteData()
  {
// "https://ichimoku-ea.000webhostapp.com/?notification=test"
   string cookie=NULL,headers;
   char post[],result[];
   string google_url="https://ichimoku-ea.000webhostapp.com/?reset_ssb_alerts=true";
   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection 
   int res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
   if(res==-1)
     {
      Print("Error in WebRequest. Error code  =",GetLastError());
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address 
      //MessageBox("Add the address '"+google_url+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     }
   else
     {
      printf(CharArrayToString(result));
      //--- Load successfully 
      //PrintFormat("The file has been successfully loaded, File size =%d bytes.",ArraySize(result)); 
      printf("Reset command sent successfully");
     }
  }
//+------------------------------------------------------------------+
