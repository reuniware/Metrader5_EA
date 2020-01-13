# Metrader5_EA

This Expert Advisor for Metatrader 5 will scan all financial symbols that are in the Market Watch window of Metatrader 5 and will report those which have validated Ichimoku Kinko Hyo conditions.

You can use it in 2 ways :
  - Normal mode : It will scan for Ichimoku conditions every 15 minutes (at each start of a new 15-minute japanese candlestick).
  - Run only once mode : It will immediately scan for Ichimoku conditions, once and only once. For this mode, as soon as you attach the EA to a financial symbol, then go to "Input data" tab and set the variable "runOnlyOnce" to "true".

You must attach the EA to one financial symbol and it will scan for every symbols that have been previously added in the Market Watch window.

Ichimoku main detection :
  - When price gets over the Kumo

Ichimoku validations that are checked by this EA are :
  - Validation 1 : SSA > SSB <=> Senkou Span A is greater than Senkou Span B 
  - Validation 2 : Open price > Kumo cloud (Open price of previous 15-minute japanese candlestick)
  - Validation 3 : Open price > Kijun sen
  - Validation 4 : Open price > Tenkan sen
  - Validation 5 : Chikou span > Kumo
  - Validation 6 : Chikou span > Kijun
  - Validation 7 : Chikou span > Tenkan sen
  - Validation 8 : Chikou span > Higher price (Higher price of previous 15-minute japanese candlestick)
 
Feel free to contact me :

e-mail : investdatasystems@yahoo.com


IchimokuUltimateScannerEA2020.Ex5 is experimental (completely new source code).

IchimokuUltimateScannerEA2020_ChikouSpanScanner.Ex5 is experimental and scans for financial instruments that are in the Market Watch window of Metatrader 5, and finds those for which the Lagging span is free (uptrend or downtrend).

IchimokuUltimateScannerEA2020_KijunSenScanner.Ex5 is experimental and scans for financial instruments that are in the Market Watch window of Metatrader 5, and finds those for which the price is getting over the Kijun Sen Line or under the Kijun Sen Line.

IchimokuUltimateScannerEA2020_PriceAndChikouScanner.Ex5 is experimental and scans for financial instruments that are in the Market Watch window of Metatrader 5, and finds those for which the price and the Chikou Span Line are free of obstacles <=> Free of going on their trend.

There are samples of outputs in the Reports folder : https://github.com/reuniware/Metrader5_EA/tree/master/Reports

https://finance.forumactif.com

https://ichimokuscanner.000webhostapp.com


You might also be interested  in the following links with my latest Ichimoku Scanners EA with licence expiring on 31st of december 2020 :

https://finance.forumactif.com/t25-ichimoku-ultimate-scanner-ea-2020-version-kumo-scanner

https://finance.forumactif.com/t27-ichimoku-ultimate-scanner-ea-2020-kijun-sen-scanner
