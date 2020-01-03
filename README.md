# Metrader5_EA

This Expert Advisor for Metatrader 5 will scan all financial symbols that are in the Market Watch window of Metatrader 5 and will report those which have validated Ichimoku Kinko Hyo conditions.

You can use it in 2 ways :
  - Normal mode : It will scan for Ichimoku conditions every 15 minutes (at each start of a new 15 minute japanese candlestick).
  - Run only once mode : It will immediately scan for Ichimoku conditions, once and only once.

You must attach the EA to one financial symbol and it will scan for every symbols that have been previously added in the Market Watch window.

Ichimoku validations that are checked by this EA are :
  - Validation 1 : SSA > SSB <=> Senkou Span A is greater than Senkou Span B 
  - Validation 2 : Open price > Kumo cloud (Open price of previous 15-minute japanese candlestick)
  - Validation 3 : Open price > Kijun sen
  - Validation 4 : Open price > Tenkan sen
  - Validation 5 : Chikou span > Kumo
  - Validation 6 : Chikou span > Kijun
  - Validation 7 : Chikou span > Tenkan sen
  - Validation 8 : Chikou span > Higher price (Higher price of previous 15-minute japanese candlestick)
 
