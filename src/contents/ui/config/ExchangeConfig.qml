/**
 * Crypto Tracker widget for KDE
 *
 * @author    Marcin Orlowski <mail (#) marcinOrlowski (.) com>
 * @copyright 2021-2026 Marcin Orlowski
 * @license   http://www.opensource.org/licenses/mit-license.php MIT
 * @link      https://github.com/MarcinOrlowski/crypto-tracker-plasmoid
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQControls
import org.kde.plasma.components as PlasmaComponents
import "../../js/crypto.js" as Crypto
import "../../js/fiat.js" as Fiat
import ".."

ColumnLayout {
    Layout.fillWidth: true

    property string exchange: undefined
    property string crypto: undefined
    property string pair: undefined

    // Entry type: 'crypto' (exchange ticker) or 'fx' (fiat FX pair)
    property bool fxType: false
    property string fxBase: 'USD'
    property string fxQuote: 'EUR'

    // ------------------------------------------------------------------------------------------------------------------------

    function init(asFx) {
        fromJson({
            'enabled': true,

            'type': asFx ? 'fx' : 'crypto',
            'exchange': Crypto.getExchageIds()[0],
            'crypto': Crypto.BTC,   // FIXME we should fetch first crypto supported by exchange!
            'fxBase': 'USD',
            'fxQuote': 'EUR',
            'fxDecimals': 0,
            'fxHideSymbol': false,
            'hideCryptoLogo': false,
            'pair': Crypto.USD,   // FIXME we should fetch first pair supported by exchange!
            'refreshRate': asFx ? 60 : 15,
            'hidePriceDecimals': false,
            'useCustomLocale': false,
            'customLocaleName': '',

            'showPriceChangeMarker': true,
            'showTrendingMarker': true,
            'trendingTimeSpan': 60,

            'flashOnPriceRaise': true,
            'flashOnPriceRaiseColor': '#78c625',
            'flashOnPriceDrop': true,
            'flashOnPriceDropColor': '#ff006e',
            'markerColorPriceRaise': '#78c625',
            'markerColorPriceDrop': '#ff006e',
        })
    }

    function fromJson(json) {
        exchangeEnabled.checked = json.enabled

        // Type must be set first so updateModels() (fired by the property
        // changes below) can skip crypto model work for FX entries.
        fxType = (json.type === 'fx')
        typeComboBox.syncFrom(fxType ? 'fx' : 'crypto')

        fxBase = (json.fxBase !== undefined) ? json.fxBase : 'USD'
        fxQuote = (json.fxQuote !== undefined) ? json.fxQuote : 'EUR'
        fxDecimals.value = (json.fxDecimals !== undefined) ? json.fxDecimals : 0
        fxHideSymbol.checked = (json.fxHideSymbol !== undefined) ? json.fxHideSymbol : false
        fxBaseComboBox.syncFrom(fxBase)
        fxQuoteComboBox.syncFrom(fxQuote)

		exchange = json.exchange
		crypto = json.crypto
		hideCryptoLogo.checked = json.hideCryptoLogo
        pair = json.pair
		refreshRate.value = json.refreshRate
		hidePriceDecimals.checked = json.hidePriceDecimals
		useCustomLocale.checked = json.useCustomLocale
		customLocaleName.text = json.customLocaleName

		showPriceChangeMarker.checked = json.showPriceChangeMarker
		showTrendingMarker.checked = json.showTrendingMarker
		trendingTimeSpan.value = json.trendingTimeSpan

		flashOnPriceRaise.checked = json.flashOnPriceRaise
		flashOnPriceRaiseColor.color = json.flashOnPriceRaiseColor
		flashOnPriceDrop.checked = json.flashOnPriceDrop
		flashOnPriceDropColor.color = json.flashOnPriceDropColor
		markerColorPriceRaise.color = json.markerColorPriceRaise
		markerColorPriceDrop.color = json.markerColorPriceDrop
    }

    function toJson() {
        return {
            'enabled': exchangeEnabled.checked,

            'type': fxType ? 'fx' : 'crypto',
            'exchange': exchange,
            'crypto': crypto,
            'fxBase': fxBase,
            'fxQuote': fxQuote,
            'fxDecimals': fxDecimals.value,
            'fxHideSymbol': fxHideSymbol.checked,
            'hideCryptoLogo': hideCryptoLogo.checked,
            'pair': pair,
            'refreshRate': refreshRate.value,
            'hidePriceDecimals': hidePriceDecimals.checked,
            'useCustomLocale': useCustomLocale.checked,
            'customLocaleName': customLocaleName.text,

            'showPriceChangeMarker': showPriceChangeMarker.checked,
            'showTrendingMarker': showTrendingMarker.checked,
            'trendingTimeSpan': trendingTimeSpan.value,

            'flashOnPriceRaise': flashOnPriceRaise.checked,
            'flashOnPriceRaiseColor': flashOnPriceRaiseColor.color.toString(),
            'flashOnPriceDrop': flashOnPriceDrop.checked,
            'flashOnPriceDropColor': flashOnPriceDropColor.color.toString(),
            'markerColorPriceRaise': markerColorPriceRaise.color.toString(),
            'markerColorPriceDrop': markerColorPriceDrop.color.toString(),
        }
    }

    // ------------------------------------------------------------------------------------------------------------------------

    onExchangeChanged: updateModels()
    onCryptoChanged: updateModels()
    onPairChanged: updateModels()

    function updateModels() {
        if (fxType) {
            // FX entries have no crypto exchange model behind them.
            return
        }
        if (typeof exchange === 'undefined' || exchange === '') {
            return
        }
        if (typeof crypto === 'undefined' || crypto === '' || !Crypto.isCryptoSupported(exchange, crypto)) {
            var cryptos = Crypto.getAllExchangeCryptos(exchange);
            crypto = (cryptos !== null && cryptos.length > 0) ? cryptos[0].value : ''
        }
        if (crypto === '') {
            // Exchange unknown to the generated data (dead or removed): leave the
            // stored values untouched so an existing config stays editable
            // instead of crashing the dialog on empty models.
            exchangeComboBox.updateModel(exchange)
            return
        }
        if (typeof pair === 'undefined' || pair === '' || !Crypto.isPairSupported(exchange, crypto, pair)) {
            var pairs = Crypto.getPairsForCrypto(exchange, crypto)
            pair = (pairs !== null && pairs.length > 0) ? pairs[0].value : ''
        }

        exchangeComboBox.updateModel(exchange)
        cryptoComboBox.updateModel(exchange, crypto)
        pairComboBox.updateModel(exchange, crypto, pair)
    }

    // ------------------------------------------------------------------------------------------------------------------------

    Kirigami.FormLayout {
        Layout.fillWidth: true
        CheckBox {
            id: exchangeEnabled
            Kirigami.FormData.label: i18n('Enabled')
            checked: true
        }

        PlasmaComponents.ComboBox {
            id: typeComboBox
            enabled: exchangeEnabled.checked
            Kirigami.FormData.label: i18n('Entry type')
            textRole: 'text'
            model: [{'value': 'crypto', 'text': i18n('Crypto')}, {'value': 'fx', 'text': i18n('Fiat FX')}]
            onActivated: {
                fxType = (currentValue === 'fx')
                if (fxType) {
                    // switching to FX mid-edit: point the currency combos at
                    // the entry's current fx values instead of list defaults
                    fxBaseComboBox.syncFrom(fxBase)
                    fxQuoteComboBox.syncFrom(fxQuote)
                }
            }

            function syncFrom(t) {
                currentIndex = (t === 'fx') ? 1 : 0
                fxType = (t === 'fx')
            }
        }

        PlasmaComponents.ComboBox {
            id: exchangeComboBox

            visible: !fxType
            enabled: exchangeEnabled.checked
            Kirigami.FormData.label: i18n('Exchange')
            textRole: "text"
            // Component.onCompleted: populateExchageModel()
            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < model.length) exchange = model[currentIndex]['value']
            }

            function updateModel(exchange) {
                var tmp = []
                var idx = 0
                var currentIdx = 0
                for(const key in Crypto.exchanges) {
                    tmp.push({'value': key, 'text': Crypto.getExchangeName(key)})
                    if (key === exchange) currentIdx = idx
                    idx++
                }
                model = tmp
                currentIndex = currentIdx
            }

            Component.onCompleted: updateModel(exchange)
        }

        ClickableLabel {
            visible: !fxType
            text: '<u>' + Crypto.getExchangeUrl(exchange) + '</u>'
            url: Crypto.getExchangeUrl(exchange)
        }

        PlasmaComponents.SpinBox {
            id: refreshRate
            enabled: exchangeEnabled.checked
            editable: true
            from: 1
            to: 600
            stepSize: 15
            Kirigami.FormData.label: i18n("Update interval (minutes)")
        }

        // ------------------------------------------------------------------------------------------------------------------------

        RowLayout {
            visible: !fxType
            Kirigami.FormData.label: i18n('Crypto')
            enabled: exchangeEnabled.checked

            PlasmaComponents.ComboBox {
                id: cryptoComboBox
                textRole: "text"
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < model.length) crypto = model[currentIndex]['value']
                }

                function updateModel(exchange, crypto) {
                    var tmp = []
                    var currentIdx = 0
                    if (exchange in Crypto.exchanges) {
                        var tmp = Crypto.getAllExchangeCryptos(exchange);
                        for (var i=0; i<tmp.length; i++) {
                            if (tmp[i].value == crypto) currentIdx = i
                        }
                    }
                    model = tmp
                    currentIndex = (tmp.length > 0) ? currentIdx : -1

                    // as the model is swapped, different crypto can be at already set index
                    // so we need to ensure we do not use old value any more.
                    if (tmp.length > 0) {
                        crypto = model[currentIndex]['value']
                    }
                }
            }

            CheckBox {
                id: hideCryptoLogo
                text: i18n("Hide currency icon")
            }
        }

        // ------------------------------------------------------------------------------------------------------------------------

        RowLayout {
            visible: !fxType
            Kirigami.FormData.label: i18n('Pair')
            enabled: exchangeEnabled.checked

            PlasmaComponents.ComboBox {
                id: pairComboBox
                textRole: "text"
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < model.length) pair = model[currentIndex]['value']
                }

                function updateModel(exchange, crypto, pair) {
                    var tmp = []
                    var currentIdx = 0
                    if ((exchange in Crypto.exchanges) && (crypto in Crypto.exchanges[exchange]['pairs'])) {
                        tmp = Crypto.getPairsForCrypto(exchange, crypto)
                        for (var i=0; i<tmp.length; i++) {
                            if (tmp[i].value === pair) currentIdx = i
                        }
                    }
                    model = tmp
                    currentIndex = (tmp.length > 0) ? currentIdx : -1

                    // as the model is swapped, different pair can be at already set index
                    // so we need to ensure we do not use old value any more.
                    if (tmp.length > 0) {
                        pair = model[currentIndex]['value']
                    }
                }
            }

            // FIXME should be per Pair as we may have i.e. LTCBTC pair soon
            // and this would make no sense then.
            PlasmaComponents.CheckBox {
                id: hidePriceDecimals
                text: i18n("Hide decimals")
            }
        }

        // ------------------------------------------------------------------------------------------------------------------------

        RowLayout {
            visible: fxType
            enabled: exchangeEnabled.checked
            Kirigami.FormData.label: i18n('Base currency')

            PlasmaComponents.ComboBox {
                id: fxBaseComboBox
                textRole: 'text'
                model: Fiat.currencyModel()
                onActivated: fxBase = currentValue

                function syncFrom(code) {
                    var idx = 0
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].value === code) { idx = i; break }
                    }
                    currentIndex = idx
                    fxBase = model[currentIndex].value
                }
            }

            PlasmaComponents.ComboBox {
                id: fxQuoteComboBox
                textRole: 'text'
                Kirigami.FormData.label: i18n('Converted into')
                model: Fiat.currencyModel()
                onActivated: fxQuote = currentValue

                function syncFrom(code) {
                    var idx = 0
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].value === code) { idx = i; break }
                    }
                    currentIndex = idx
                    fxQuote = model[currentIndex].value
                }
            }
        }

        PlasmaComponents.SpinBox {
            id: fxDecimals
            visible: fxType
            enabled: exchangeEnabled.checked
            editable: true
            from: 0
            to: 12
            Kirigami.FormData.label: i18n("Decimals (0 = auto)")
        }

        PlasmaComponents.CheckBox {
            id: fxHideSymbol
            visible: fxType
            enabled: exchangeEnabled.checked
            text: i18n("Hide currency symbol")
        }

        CheckBox {
            id: showPriceChangeMarker
            text: i18n("Show price change markers")
            enabled: exchangeEnabled.checked
        }

        CheckBox {
            id: showTrendingMarker
            visible: !fxType
            text: i18n("Show trending markers")
            enabled: exchangeEnabled.checked
        }

        PlasmaComponents.SpinBox {
            id: trendingTimeSpan
            visible: !fxType
            enabled: showTrendingMarker.checked && exchangeEnabled.checked
            editable: true
            from: 1
            to: 600
            stepSize: 15
            Kirigami.FormData.label: i18n("Trending span (minutes)")
        }

        KQControls.ColorButton {
            id: markerColorPriceRaise
            enabled: (showPriceChangeMarker.checked | showTrendingMarker.checked) && exchangeEnabled.checked
            Kirigami.FormData.label: i18n('Price raise markers')
            dialogTitle: i18n('Price raise marker color')
        }

        KQControls.ColorButton {
            id: markerColorPriceDrop
            enabled: (showPriceChangeMarker.checked | showTrendingMarker.checked) && exchangeEnabled.checked
            Kirigami.FormData.label: i18n('Price drop markers')
            dialogTitle: i18n('Price drop marker color')
        }

        // ------------------------------------------------------------------------------------------------------------------------

        RowLayout {
            enabled: exchangeEnabled.checked
            Kirigami.FormData.label: i18n('Use custom locale')
            CheckBox {
                id: useCustomLocale
            }

            TextField {
                id: customLocaleName
                enabled: useCustomLocale.checked
                placeholderText: "en_US"
            }
        }

        // ------------------------------------------------------------------------------------------------------------------------

        RowLayout {
            enabled: exchangeEnabled.checked
            Kirigami.FormData.label: i18n("Flash on price raise")
            CheckBox {
                id: flashOnPriceRaise
            }
            KQControls.ColorButton {
                id: flashOnPriceRaiseColor
                enabled: flashOnPriceRaise.checked
                dialogTitle: i18n('Price raise flash background color')
            }
        }

        RowLayout {
            enabled: exchangeEnabled.checked
            Kirigami.FormData.label: i18n("Flash on price drop")

            CheckBox {
                id: flashOnPriceDrop
            }
            KQControls.ColorButton {
                id: flashOnPriceDropColor
                enabled: flashOnPriceDrop.checked
                dialogTitle: i18n('Price drop flash background color')
            }
        }

        // ------------------------------------------------------------------------------------------------------------------------

    } // Kirigami.FormLayout
} // ColumnLayout
