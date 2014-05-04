#Overview

Use libnotify to display coin markets fetched from either SwissCEX and/or MintPal. BTC/USD Prices from Bitstamp as well.

#Example
 
__Basic (DOGE/BTC from Mintpal. No API Key Needed.)__

./notify-ticker.pl --coins="doge" --to_satoshi

__Notify DOGE/BTC, DOGE/LTC, VERT/BTC Markets. Try SwissCEX first and stop if all coins found.__

./notify_ticker.pl --coins="doge/btc, doge, vert/btc" --to_satoshi --market="ltc" --preferred_exchange="SwissCex" --swisscex_key="<key>"

#Script Arguments

__coins__: A list of markets to fetch. If no secondary (trade) market is specified, it uses the market argument.

__to_satoshi__: Converts from 1BTC to Satoshis. Notify boxes are small and full prices don't play well. Default True.

__swisscex_key__: SwissCEX API Key. Required to fetch from SwissCEX.

__market__: The default trade market to use if no market is specified. Default BTC

__preferred_exchange__: Return prices from this exchange if applicable. Default MintPal.

** The script will not fetch from two exchanges unless every market was not returned from the preferred exchange.
