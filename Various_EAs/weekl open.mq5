
#property copyright   "© mladen, 2017, mladenfx@gmail.com"
#property link        "www.forex-station.com"


double Open[],High[],Low[];
int OnInit()
{
return(0);
}
void OnDeinit(const int reason)
{
}
void OnTick()
{
double open,close,low,high;
open=iOpen(Symbol(),PERIOD_W1,0); //表示获得最近一根月线的开盘价。
close=SymbolInfoDouble(Symbol(),SYMBOL_BID); //表示获得最近一根月线的收盘价。
low=iLow(Symbol(),PERIOD_W1,0); //表示获得最近一根月线的最低价。
//high=iHigh(Symbol(),PERIOD_W1,0); //表示获得最近一根月线的最高价。
}
//double iOpen(string symbol,ENUM_TIMEFRAMES timeframe,int index)
{
double open=0;
ArraySetAsSeries(Open,true);
int copied=CopyOpen(symbol,timeframe,0,Bars(symbol,timeframe),Open); //将指定时间周期的开盘价格复制到指定数组。
if(copied>0 && index<copied) open=Open[index];
return(open);
}
//double iLow(string symbol,ENUM_TIMEFRAMES timeframe,int index)
{
double low=0;
ArraySetAsSeries(Low,true);
int copied=CopyLow(symbol,timeframe,0,Bars(symbol,timeframe),Low);
if(copied>0 && index<copied) low=Low[index];
return(low);
}
//double iHigh(string symbol,ENUM_TIMEFRAMES timeframe,int index)
{
double high=0;
ArraySetAsSeries(High,true);
int copied=CopyHigh(symbol,timeframe,0,Bars(symbol,timeframe),High);
if(copied>0 && index<copied) high=High[index];
return(high);
}
//+------------------------------------------------------------------+