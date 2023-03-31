//+------------------------------------------------------------------+
//|                                                KPIchimokuBot.mq5 |
//|              Copyright 2018, InvestDataSystems +33 7 87 81 74 34 |
//|                 https://tradingbot.wixsite.com/robots-de-trading |
//+------------------------------------------------------------------+

#property copyright "Copyright 2018, InvestDataSystems"
#property link      "https://tradingbot.wixsite.com/robots-de-trading"
#property version   "1.00"


#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

double tenkan_sen_buffer[];
double kijun_sen_buffer[];
double senkou_span_a_buffer[];
double senkou_span_b_buffer[];
double chikou_span_buffer[];

double open_array[];
double high_array[];
double low_array[];
double close_array[];

input int scanTimer=10;
input bool runInLoop=false;
input bool showProcessedSymbol=false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   printf("OnInit : KPIchimokuBot : "+EnumToString(Period()));
   workingPeriod=Period();
   done=false;
   EventKillTimer();
   EventSetTimer(scanTimer);
   printf("scan will start in "+IntegerToString(scanTimer)+" seconds");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   printf("OnDeinit : KPIchimokuBot : "+EnumToString(Period()));
   EventKillTimer();
  }

static int BARS;
static datetime LastBarTime=-1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   Ichimoku();
  }

bool onlySymbolsInMarketwatch=true;
bool done=false;
ENUM_TIMEFRAMES workingPeriod=Period();
MqlTick mqlTick;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ichimoku()
  {
   if(runInLoop==false)
     {
      if(done==true)
        {
         //printf("scan already done");
         return;
        }
     }

   printf("scan started");

   int stotal=SymbolsTotal(onlySymbolsInMarketwatch); // seulement les symboles dans le marketwatch (false)

   for(int sindex=0; sindex<stotal; sindex++)
     {
      string sname=SymbolName(sindex,onlySymbolsInMarketwatch);
      if(showProcessedSymbol) printf("Processing "+sname);

      if(CurrentCandlestickCrossedKijunUp(sname,workingPeriod))
        {
         SymbolInfoTick(sname,mqlTick);
         printf(sname+" : current candlestick crossed kijun while up in "+EnumToString(workingPeriod)+" ; Ask = "+NormalizeDouble(mqlTick.ask,5)+" ; TimeLocal() = "+TimeToString(TimeLocal()));
         if(ChikouSpanIsFree(sname,workingPeriod))
           {
            printf(sname+" : And Chikou Span is free");
           }
        }

      if(PreviousCandlestickCrossedKijunUp(sname,workingPeriod))
        {
         SymbolInfoTick(sname,mqlTick);
         printf(sname+" : previous candlestick crossed kijun while up in "+EnumToString(workingPeriod)+" ; Ask = "+NormalizeDouble(mqlTick.ask,5)+" ; TimeLocal() = "+TimeToString(TimeLocal()));

         if(CurrentPriceIsOverKijun(sname,workingPeriod))
           {
            printf(sname+" : And current price is over kijun");
           }

         if(ChikouSpanIsFree(sname,workingPeriod))
           {
            printf(sname+" : And Chikou Span is free");
           }
        }

     }

   if(runInLoop==false)
     {
      done=true;
     }

   printf("scan ended");
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
bool BUY()
  {
   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);
   double spread=lasttick.ask-lasttick.bid; // spread = prix de vente - prix d'achat
   double price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);

   MqlTradeRequest tradeRequest={0};
   MqlTradeResult  tradeResult={0};
   tradeRequest.action=TRADE_ACTION_DEAL;
   tradeRequest.symbol=Symbol();
   tradeRequest.volume=0.5;
   tradeRequest.type=ORDER_TYPE_BUY;
   tradeRequest.price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);

   double stoploss=0,takeprofit=lasttick.bid+0.00100;
   tradeRequest.sl = stoploss;
   tradeRequest.tp = takeprofit;

   if(!OrderSend(tradeRequest,tradeResult))
     {
      PrintFormat(Symbol()+" : OrderSend error %d",GetLastError());
      return false;
     }
   else
     {
      printf(Symbol()+" : OrderSend ok");
      return true;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SELL()
  {
   MqlTick lasttick;
   SymbolInfoTick(Symbol(),lasttick);
   double spread=lasttick.ask-lasttick.bid; // spread = prix de vente - prix d'achat
   double price = SymbolInfoDouble(Symbol(),SYMBOL_BID);

   MqlTradeRequest tradeRequest={0};
   MqlTradeResult  tradeResult={0};
   tradeRequest.action=TRADE_ACTION_DEAL;
   tradeRequest.symbol=Symbol();
   tradeRequest.volume=0.5;
   tradeRequest.type=ORDER_TYPE_SELL;
   tradeRequest.price=SymbolInfoDouble(Symbol(),SYMBOL_BID);

   double stoploss=0,takeprofit=lasttick.ask-0.00100;
   tradeRequest.sl = stoploss;
   tradeRequest.tp = takeprofit;

   if(!OrderSend(tradeRequest,tradeResult))
     {
      PrintFormat(Symbol()+" : OrderSend error %d",GetLastError());
      return false;
     }
   else
     {
      printf(Symbol()+" : OrderSend ok");
      return true;
     }
  }

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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceIsOverKumo(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

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
      Result=true;

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

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

bool PriceIsUnderKumo(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

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

   if(open_array[1]<senkou_span_a_buffer[1]
      && open_array[1]<senkou_span_b_buffer[1]
      && close_array[1]<senkou_span_a_buffer[1]
      && close_array[1]<senkou_span_b_buffer[1]
      )
      Result=true;

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

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChikouSpanIsFree(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=27;

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
      Result=true;

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

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

bool PriceCrossedKumoSsbUp(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

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
      Result=true;

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

   return Result;
  }

bool Result;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CurrentCandlestickCrossedKijunUp(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=4;

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

/*if(
      (open_array[1]<kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[2]<kijun_sen_buffer[2] && close_array[2]<kijun_sen_buffer[2] && open_array[1]>kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[2]<kijun_sen_buffer[2] && close_array[2]<kijun_sen_buffer[2] && open_array[1]<kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      || (open_array[2]<kijun_sen_buffer[2] && close_array[2]>kijun_sen_buffer[2] && open_array[1]>kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      )
      Result=true;*/

   if(
      (open_array[0]<kijun_sen_buffer[0] && close_array[0]>kijun_sen_buffer[0])
      )
      Result=true;

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

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PreviousCandlestickCrossedKijunUp(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=4;

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

   if(
      (open_array[1]<kijun_sen_buffer[1] && close_array[1]>kijun_sen_buffer[1])
      )
      Result=true;

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

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CurrentPriceIsOverKijun(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

   ArraySetAsSeries(tenkan_sen_buffer,true);
   ArraySetAsSeries(kijun_sen_buffer,true);
   ArraySetAsSeries(senkou_span_a_buffer,true);
   ArraySetAsSeries(senkou_span_b_buffer,true);
   ArraySetAsSeries(chikou_span_buffer,true);

   handleIchimoku=iIchimoku(Symbol,TimeFrame,tenkan_sen_param,kijun_sen_param,senkou_span_b_param);

   max=4;

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

   if(
      (close_array[0]>kijun_sen_buffer[0])
      )
      Result=true;

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

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceCrossedKijunDown(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

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
      (open_array[1]>kijun_sen_buffer[1] && close_array[1]<kijun_sen_buffer[1])
      || (open_array[2]>kijun_sen_buffer[2] && close_array[2]>kijun_sen_buffer[2] && open_array[1]<kijun_sen_buffer[1] && close_array[1]<kijun_sen_buffer[1])
      || (open_array[2]>kijun_sen_buffer[2] && close_array[2]>kijun_sen_buffer[2] && open_array[1]>kijun_sen_buffer[1] && close_array[1]<kijun_sen_buffer[1])
      || (open_array[2]>kijun_sen_buffer[2] && close_array[2]<kijun_sen_buffer[2] && open_array[1]<kijun_sen_buffer[1] && close_array[1]<kijun_sen_buffer[1])
      )
      Result=true;

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

   return Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PriceIsOverKijun(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   Result=false;

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
      Result=true;

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

   return Result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int handleRsi=INVALID_HANDLE;
double iRSIBuffer[];
int ResultRsi;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getRSI(string Symbol,ENUM_TIMEFRAMES TimeFrame)
  {
   handleRsi=iRSI(Symbol,TimeFrame,14,PRICE_CLOSE);

   ArraySetAsSeries(iRSIBuffer,true);
   CopyBuffer(handleRsi,0,0,3,iRSIBuffer);

   ResultRsi=(int) iRSIBuffer[0];

   ArrayFree(iRSIBuffer);
   IndicatorRelease(handleRsi);

   return "["+IntegerToString(ResultRsi)+"]";
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getTimeStamp()
  {
   TimeCurrent(mqd);
   return string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');
  }
//+------------------------------------------------------------------+

/*void OnTimer()
  {
   datetime ThisBarTime=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   if(ThisBarTime==LastBarTime)
     {
      //printf("Same bar time ("+Symbol()+")");
     }
   else
     {
      if(LastBarTime==-1)
        {
         //printf("First bar ("+Symbol()+")");
         LastBarTime=ThisBarTime;
        }
      else
        {
         //printf("New bar time ("+Symbol()+")");
         LastBarTime=ThisBarTime;

         Ichimoku();
        }
     }
  }*/
//+------------------------------------------------------------------+
