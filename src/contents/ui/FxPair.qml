/**
 * Crypto Tracker widget for KDE
 *
 * @author    Marcin Orlowski <mail (#) marcinOrlowski (.) com>
 * @copyright 2021-2026 Marcin Orlowski
 * @license   http://www.opensource.org/licenses/mit-license.php MIT
 * @link      https://github.com/MarcinOrlowski/crypto-tracker-plasmoid
 */

// Fiat FX entry: displays "BASE/QUOTE 0.87€" style tickers using the
// Free Currency Rates API (same source as the krunner-currency plugin).

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import "../js/fiat.js" as Fiat

Item {
    id: fxRoot

    implicitWidth: contentLayout.implicitWidth
    implicitHeight: contentLayout.implicitHeight

    property var json: undefined

    property string base: ''
    property string quote: ''
    property int decimals: 0          // 0 = auto
    property bool hideSymbol: false
    property bool useCustomLocale: false
    property string customLocaleName: ''
    property int refreshRate: 60

    property bool showPriceChangeMarker: true
    property string markerColorPriceRaise: '#78c625'
    property string markerColorPriceDrop: '#ff006e'

    // --------------------------------------------------------------------------------------------

    Component.onCompleted: {
        if (json !== undefined) {
            base = json.fxBase
            quote = json.fxQuote
            decimals = json.fxDecimals
            hideSymbol = json.fxHideSymbol
            refreshRate = json.refreshRate
            useCustomLocale = json.useCustomLocale
            customLocaleName = json.customLocaleName
            showPriceChangeMarker = json.showPriceChangeMarker
            markerColorPriceRaise = json.markerColorPriceRaise
            markerColorPriceDrop = json.markerColorPriceDrop
        }
    }

    onBaseChanged: { invalidateData(); fetchRate() }
    onQuoteChanged: { invalidateData(); fetchRate() }

    // --------------------------------------------------------------------------------------------

    property bool currentRateValid: false
    property var currentRate: 0
    property var lastRate: 0
    property int rateChangeDirection: 0   // -1, 0, 1

    function invalidateData() {
        currentRateValid = false
        currentRate = 0
        lastRate = 0
        rateChangeDirection = 0
    }

    function getRateText() {
        if (!currentRateValid) return '---'
        return Fiat.formatRate(currentRate, useCustomLocale ? customLocaleName : '',
                               decimals, hideSymbol, quote)
    }

    function getRateChangeMarkerText() {
        var color = (rateChangeDirection === +1) ? markerColorPriceRaise
                 : (rateChangeDirection === -1) ? markerColorPriceDrop
                 : '#ffffff'
        var rateText = ''
        if (rateChangeDirection !== 0) {
            rateText += ' <span style="color: ' + color + ';">'
            if (rateChangeDirection === +1) rateText += '▲'
            if (rateChangeDirection === -1) rateText += '▼'
            rateText += '</span>'
        }
        return rateText
    }

    // --------------------------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent
        z: 1
        onClicked: {
            if (!dataDownloadInProgress) {
                fxRoot.opacity = 0.5
                fetchRate()
            }
        }
    }

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent

        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignHCenter
            height: 20
            textFormat: Text.RichText
            fontSizeMode: Text.Fit
            minimumPixelSize: 8
            // "USD/EUR 0.87€" — pair code, then the converted rate with the
            // sign of the currency converted into.
            text: '<span>' + base + '/' + quote + '</span>'
        }

        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignHCenter
            height: 20
            textFormat: Text.RichText
            fontSizeMode: Text.Fit
            minimumPixelSize: 8
            text: getRateText()
        }

        PlasmaComponents.Label {
            visible: showPriceChangeMarker
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignHCenter
            height: 16
            textFormat: Text.RichText
            fontSizeMode: Text.Fit
            minimumPixelSize: 8
            text: getRateChangeMarkerText()
        }
    }

    // --------------------------------------------------------------------------------------------

    Timer {
        interval: refreshRate * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchRate()
    }

    // --------------------------------------------------------------------------------------------

    property bool dataDownloadInProgress: false
    function fetchRate() {
        if (dataDownloadInProgress) return
        if (base === '' || quote === '') return
        if (base === quote) return
        dataDownloadInProgress = true

        downloadRate(function(rate) {
            var now = new Date()
            if (rate !== null) {
                if (currentRateValid) {
                    lastRate = currentRate
                }
                currentRate = rate
                if (currentRateValid) {
                    if (currentRate > lastRate) {
                        rateChangeDirection = 1
                    } else if (currentRate < lastRate) {
                        rateChangeDirection = -1
                    } else {
                        rateChangeDirection = 0
                    }
                }
                currentRateValid = true
            }
            fxRoot.opacity = 1
            dataDownloadInProgress = false
        })
    }

    function downloadRate(callback) {
        // Direct pair lookup from the API's per-base rate table: no cross-rate
        // math, so no accumulated precision loss. Falls back to the API's
        // second CDN when the first one fails.
        var url = Fiat.primaryUrl.arg(base.toLowerCase())
        request(url, function(text, ok) {
            if (ok && text !== null && text.length !== 0) {
                try {
                    var json = JSON.parse(text)
                    var rates = json[base.toLowerCase()]
                    var rate = (rates !== undefined) ? rates[quote.toLowerCase()] : undefined
                    if (rate !== undefined && rate !== null) {
                        callback(Number(rate))
                    } else {
                        console.error('FxPair.downloadRate(): no rate for ' + base + '/' + quote)
                        callback(null)
                    }
                } catch (error) {
                    console.error('FxPair.downloadRate(): parse failed for ' + url + ': ' + error)
                    callback(null)
                }
            } else {
                var fallback = Fiat.fallbackUrl.arg(base.toLowerCase())
                request(fallback, function(text2, ok2) {
                    if (ok2 && text2 !== null && text2.length !== 0) {
                        try {
                            var json2 = JSON.parse(text2)
                            var rates2 = json2[base.toLowerCase()]
                            var rate2 = (rates2 !== undefined) ? rates2[quote.toLowerCase()] : undefined
                            if (rate2 !== undefined && rate2 !== null) {
                                callback(Number(rate2))
                            } else {
                                callback(null)
                            }
                        } catch (error2) {
                            console.error('FxPair.downloadRate(): fallback parse failed: ' + error2)
                            callback(null)
                        }
                    } else {
                        callback(null)
                    }
                })
            }
        })
    }

    function request(url, callback) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    callback(xhr.responseText, true)
                } else {
                    console.debug('FxPair.request(): HTTP ' + xhr.status + ' for ' + url)
                    callback(null, false)
                }
            }
        }
        xhr.open('GET', url, true)
        xhr.send('')
    }

    // --------------------------------------------------------------------------------------------

}
