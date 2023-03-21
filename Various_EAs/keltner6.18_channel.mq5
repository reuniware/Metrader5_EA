//----
#property description "Displays classical Keltner Channel technical indicator."
#property description "You can modify main MA period, mode of the MA and type of prices used in MA."
#property description "Buy when candle closes above the upper band."
#property description "Sell when candle closes below the lower band."
#property description "Use *very conservative* stop-loss and 3-4 times higher take-profit."
//----
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 5
#property indicator_width1 2
#property indicator_color1 Brown
#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_label1 "KC-Up"

#property indicator_width2 2
#property indicator_color2 Brown
#property indicator_type2 DRAW_LINE
#property indicator_style2 STYLE_SOLID
#property indicator_label2 "KC-Up2"

#property indicator_width3 2
#property indicator_color3 Blue
#property indicator_type3 DRAW_LINE
#property indicator_style3 STYLE_DASHDOT
#property indicator_label3 "KC-Mid"
#property indicator_width4 2
#property indicator_color4 DarkSlateGray
#property indicator_type4 DRAW_LINE
#property indicator_style4 STYLE_SOLID
#property indicator_label4 "KC-Low"

#property indicator_width5 2
#property indicator_color5 DarkSlateGray
#property indicator_type5 DRAW_LINE
#property indicator_style5 STYLE_SOLID
#property indicator_label5 "KC-Low2"

//---- input parameters
input int MA_Period=10;
input ENUM_MA_METHOD Mode_MA=MODE_SMA;
input ENUM_APPLIED_PRICE Price_Type=PRICE_TYPICAL;
input double Multiplier=6.18;
//----
double upper[],up2[],middle[],lower[],low2[],MA_Buffer;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
   Comment("");
   SetIndexBuffer(0,upper,INDICATOR_DATA);
   SetIndexBuffer(1,up2,INDICATOR_DATA);
   SetIndexBuffer(2,middle,INDICATOR_DATA);
   SetIndexBuffer(3,lower,INDICATOR_DATA);  
   SetIndexBuffer(4,low2,INDICATOR_DATA);
//----
   IndicatorSetString(INDICATOR_SHORTNAME,"KC("+IntegerToString(MA_Period)+")");
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &High[],
                const double &Low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int limit;
   double avg;
//----
   int counted_bars=prev_calculated;
//----
   if(counted_bars < 0) return(-1);
   if(counted_bars>0) counted_bars--;
//----
   limit=counted_bars;
//----
   if(limit<MA_Period) limit=MA_Period;
//----
   int myMA=iMA(NULL,0,MA_Period,0,Mode_MA,Price_Type);
   if(CopyBuffer(myMA, 0, 0, rates_total, middle) != rates_total) return(0);
//----
   for(int i=rates_total-1; i>=limit; i--)
     {
      avg=findAvg(MA_Period,i,High,Low);
      upper[i] = middle[i] + avg;
      up2[i] = middle[i] + Multiplier * avg;
      lower[i] = middle[i] - avg;
      low2[i] = middle[i] - Multiplier * avg;
     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Finds the moving average of the price ranges                     |
//+------------------------------------------------------------------+  
double findAvg(int period,int shift,const double &High[],const double &Low[])
  {
   double sum=0;
//----
   for(int i=shift; i>(shift-period); i--)
      sum+=High[i]-Low[i];
//----
   sum=sum/period;
//----
   return(sum);
  }
//+------------------------------------------------------------------+
