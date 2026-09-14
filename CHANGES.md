* v3.0.1 (2026-09-14)
  * Added fiat FX pairs: entries of type "Fiat FX" display `USD/EUR 0.87€` — the pair code
    followed by the converted rate with the currency sign of the currency converted into.
    Rates come from the Free Currency Rates API (fawazahmed0, via jsdelivr with its documented
    fallback CDN) — the same source as the krunner-currency plugin. Direct pair lookup means no
    cross-rate arithmetic and no accumulated precision loss; decimals are adaptive (like
    krunner) or fixed per entry (0–12); symbols can be hidden. Note: the API publishes a single
    mid rate per pair (no bid/ask), so there is no buy/sell side to choose.
  * Added monochrome icon mode (Layout page): coin icons are colorized into a single colour
    (following the panel text colour by default, or a custom colour) while preserving the SVG
    transparency.
  * Removed the dead BitBay/zonda exchange entirely (its API no longer resolves).
  * Fixed update checker: upstream fetched a `metadata.desktop` that no longer exists in the
    repo (404) and parsed desktop-format text with an unguarded regex. It now fetches the fork's
    `metadata.json`, parses it safely, and only notifies when the remote version is actually newer.
  * Fixed `NotificationManager` expireTimeout check (`typeof x !== undefined` compared a string
    to the `undefined` value — always true).
  * Fixed trending marker direction (compared `currentRate` instead of the fetched `rate`).
  * `generate_data.py` fixes: deadlocked forever when an exchange API was unreachable
    (BitBay's api.zonda.exchange no longer resolves); Binance pairs were never detected
    (validator expected a list, `/ticker/price` returns an object); Python 3.14 compat (forced
    `fork` start method); disabled dead BitBay; fixed cache dir path (".cryto" typo) and
    "Czech Koruna" name; fixed disabled-exchange removal (KeyError).
  * Config dialog no longer crashes on exchanges with zero pairs or unknown exchange ids, and
    corrupt stored config no longer crashes the widget or the settings page (guarded JSON
    parsing everywhere).
  * XHR failures (non-200) no longer wedge the ticker in "downloading" state.
  * Fixed GLM icon (upstream accidentally committed a saved HTML 404 page as `glm.svg`).
  * Default config now ships Kraken BTC/USD + Binance ETH/USD (the old defaults pointed at
    the dead BitBay API and never displayed a price).
  * Fixed FX combo activation storing the display text ("THB — Thai Baht") instead of
    the currency code — such entries could never fetch (always "---"). Combos now read
    the model's value field; the entry-type switch works from manual activation too.
  * Fixed the exchanges listview rendering FX entries as crypto ones: ListModel roles
    are inferred from appended rows, so rows are normalized to the full key set before
    appending (the edit dialog read the raw JSON and was unaffected).
  * Added `tools/qa.py` — static QA: metadata/meta.js sync, generated-data URL whitelist and
    pair sanity, icon validity, default-config validation.

* v3.0.0 (2026-01-14)
  * Added support for Plasma 6
  * Changed Binance API url to use `/v3/ticker/price` endpoint.
  * Bitstamp ticker queries now lowercase the pairs to make API happy.
  * Added 1INCH, BNT, BTT, EOS, GLM, SOL, THETA, WBTC, XTZ, ZRX.
  * Added new 29 pairs among supported exchanges.
  * Fixed setting not storing number of layout grid column.

* v2.1.0 (2021-05-29)
  * Added support for Binance.
  * Significantly increased number of supported pairs to 365 total.
  * Added ability to cross pair currencies with bigger flexibility.
  * Improved Kraken's API response handling.

* v2.0.0 (2021-05-10)
  * [IMPORTANT] Your current config will NOT be migrated and you will have to re-set
    all the exchanges you had before from scrach. Sorry for the inconvenience.
  * Reworked exchange management and added support for unlimited number of exchanges.
  * Exchanges can be now easily reordered.
  * Added support for Plasma 5.19+ widget background controls.
  * Added support for ETH Classic (patch by César Valadez).

* v1.2.0 (2021-03-24)
  * Internal widget layout grid is configurable now. Requested by @Foul [#11]
  * Widget background can now be set transparent.

* v1.1.2 (2021-03-23)
  * Removed use of backtick syntax due to problems on Debian 10 using old Plasma.

* v1.1.1 (2021-02-25)
  * Fixed exchange configuration not allowing to change fiats under some circumstances.

* v1.1.0 (2021-02-21)
  * Added more pairs for Kraken and Bitstamp.
  * Added support for coinmate.io and CZK fiat.
  * Widget now fades during data downloading for manually triggered refreshes.
  * Added clickable exchange URL to configuration panel.

* v1.0.0 (2021-02-13)
  * Initial public release.

