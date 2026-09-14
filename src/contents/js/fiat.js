/**
 * Crypto Tracker widget for KDE
 *
 * @author    Marcin Orlowski <mail (#) marcinOrlowski (.) com>
 * @copyright 2021-2026 Marcin Orlowski
 * @license   http://www.opensource.org/licenses/mit-license.php MIT
 * @link      https://github.com/MarcinOrlowski/crypto-tracker-plasmoid
 */

// Fiat FX support backed by the Free Currency Rates API
// (https://github.com/fawazahmed0/currency-api) — the same source the
// krunner-currency plugin uses. The API publishes a single mid rate per
// pair (no bid/ask), fetched directly for the requested base currency, so
// no cross-rate arithmetic is performed and no precision is lost beyond
// what the API itself publishes.
.pragma library

// Primary CDN and its documented fallback.
const primaryUrl = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/%1.json'
const fallbackUrl = 'https://latest.currency-api.pages.dev/v1/currencies/%1.json'

// Curated list of common fiat currencies: code → { name, symbol }.
// Symbol '' falls back to showing the ISO code next to the rate.
const currencies = {
    'AED': { name: 'UAE Dirham', symbol: '' },
    'ARS': { name: 'Argentine Peso', symbol: '$' },
    'AUD': { name: 'Australian Dollar', symbol: '$' },
    'BGN': { name: 'Bulgarian Lev', symbol: 'лв' },
    'BRL': { name: 'Brazilian Real', symbol: 'R$' },
    'CAD': { name: 'Canadian Dollar', symbol: '$' },
    'CHF': { name: 'Swiss Franc', symbol: 'Fr' },
    'CLP': { name: 'Chilean Peso', symbol: '$' },
    'CNY': { name: 'Chinese Yuan', symbol: '¥' },
    'COP': { name: 'Colombian Peso', symbol: '$' },
    'CZK': { name: 'Czech Koruna', symbol: 'Kč' },
    'DKK': { name: 'Danish Krone', symbol: 'kr' },
    'EGP': { name: 'Egyptian Pound', symbol: 'E£' },
    'EUR': { name: 'Euro', symbol: '€' },
    'GBP': { name: 'British Pound', symbol: '£' },
    'HKD': { name: 'Hong Kong Dollar', symbol: 'HK$' },
    'HUF': { name: 'Hungarian Forint', symbol: 'Ft' },
    'IDR': { name: 'Indonesian Rupiah', symbol: 'Rp' },
    'ILS': { name: 'Israeli New Shekel', symbol: '₪' },
    'INR': { name: 'Indian Rupee', symbol: '₹' },
    'JPY': { name: 'Japanese Yen', symbol: '¥' },
    'KES': { name: 'Kenyan Shilling', symbol: 'KSh' },
    'KRW': { name: 'South Korean Won', symbol: '₩' },
    'MAD': { name: 'Moroccan Dirham', symbol: '' },
    'MXN': { name: 'Mexican Peso', symbol: '$' },
    'MYR': { name: 'Malaysian Ringgit', symbol: 'RM' },
    'NGN': { name: 'Nigerian Naira', symbol: '₦' },
    'NOK': { name: 'Norwegian Krone', symbol: 'kr' },
    'NZD': { name: 'New Zealand Dollar', symbol: '$' },
    'PHP': { name: 'Philippine Peso', symbol: '₱' },
    'PLN': { name: 'Polish Zloty', symbol: 'zł' },
    'RON': { name: 'Romanian Leu', symbol: 'lei' },
    'RUB': { name: 'Russian Ruble', symbol: '₽' },
    'SAR': { name: 'Saudi Riyal', symbol: '﷼' },
    'SEK': { name: 'Swedish Krona', symbol: 'kr' },
    'SGD': { name: 'Singapore Dollar', symbol: 'S$' },
    'THB': { name: 'Thai Baht', symbol: '฿' },
    'TRY': { name: 'Turkish Lira', symbol: '₺' },
    'TWD': { name: 'New Taiwan Dollar', symbol: 'NT$' },
    'UAH': { name: 'Ukrainian Hryvnia', symbol: '₴' },
    'USD': { name: 'US Dollar', symbol: '$' },
    'VND': { name: 'Vietnamese Dong', symbol: '₫' },
    'ZAR': { name: 'South African Rand', symbol: 'R' },
}

function exists(code) {
    return code in currencies
}

function getName(code) {
    return exists(code) ? currencies[code]['name'] : code
}

/** Symbol for a code; falls back to the code itself when unknown. */
function symbolFor(code) {
    if (exists(code) && currencies[code]['symbol'] !== '') {
        return currencies[code]['symbol']
    }
    return code
}

/** ComboBox-friendly model: [{ value, text }] */
function currencyModel() {
    var model = []
    for (var code in currencies) {
        model.push({'value': code, 'text': code + ' — ' + currencies[code]['name']})
    }
    return model
}

/**
 * Adaptive decimal formatting (same algorithm as the krunner-currency
 * plugin): 2 decimals for values >= 1; below 1 the decimal count grows
 * with the magnitude down to 12; trailing zeros are dropped.
 */
function formatRate(rate, localeName, fixedDecimals, hideSymbol, quoteCode) {
    var locale = Qt.locale(localeName)
    var value = Number(rate)
    if (!isFinite(value)) {
        return '---'
    }

    var decimals = fixedDecimals
    if (decimals <= 0) {  // 0 = auto
        decimals = 2
        var abs = Math.abs(value)
        if (abs !== 0 && abs < 1.0) {
            decimals = Math.max(2, Math.min(12, 3 - Math.floor(Math.log(abs) / Math.LN10)))
        }
    }

    var text = value.toLocaleString(locale, 'f', decimals)
    if (fixedDecimals <= 0) {
        // drop trailing zeros and a dangling decimal separator (auto mode only)
        // NB: decimalPoint is a property of the QML locale wrapper, not a method.
        var sep = locale.decimalPoint
        while (text.length > 0 && text[text.length - 1] === '0') {
            text = text.slice(0, -1)
        }
        if (text.length > 0 && text[text.length - 1] === sep) {
            text = text.slice(0, -1)
        }
    }

    if (hideSymbol) {
        return text
    }
    // Currency sign of the currency converted into, attached ("0.87€").
    // Codes without a known symbol fall back to the ISO code ("0.87 THB").
    if (exists(quoteCode) && currencies[quoteCode]['symbol'] !== '') {
        return text + currencies[quoteCode]['symbol']
    }
    return text + ' ' + quoteCode
}
