# IchimokuHorizontalLines005.mq5 (source code) / IchimokuHorizontalLines005.ex5 (compiled)

This Expert Advisor can be run on Metatrader 5.

<br/>

It can display all horizontal lines that correspond to :

- Horizontal lines of Kijun Sen since all available history.
- Horizontal lines of Tenkan Sen since all available history.
- Horizontal lines of Senkou Span B since all available history.
- Horizontal lines of Senkou Span A since all available history.

<br/>

As soon as you launch this EA (by attaching it to a chart) it will display Kijun Sen horinzontal lines.

<br/>

Available commands (click on the chart before using them) :

[r] : Reset lines for current chart and timeframe.

[up] / [down] : Increase/Decrease nb of consecutive same value for a line.

[c] : Clear all lines.

[k] : Draw Kijun Sen lines.

[t] : Draw Tenkan Sen lines.

[b] : Draw Senkou Span B lines.

[a] : Draw Senkou Span A lines.

# The n consecutive identical values parameter

If we find n consecutive identical values for Kijun Sen (or Tenkan Sen or SSB or SSA) then we have a line.

This is the "minConsecutiveValues" parameter.

You can modify this value with the UP or DOWN arrow keys on your keyboard.

# Who can benefit from this EA ?

If you are an Ichimoku trader then it will help you identify key levels to trade.

If you are an Ichimoku specialist it will help you identify what key levels in the past still have an impact on the current price of an asset.

# Some tips

You can ask for lines on an upper timeframe (eg. 1W) and then switch to a lower timeframe, and then you will see the 1W levels on the lower timeframe.

When you ask for lines, then just after use the up arrow to filter them.

