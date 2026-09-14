#!/usr/bin/env python3
"""Static QA checks for the crypto-tracker-plasmoid tree.

Run from repo root:  python3 tools/qa.py
Optional:            python3 tools/qa.py --online   (also probes the update-check URL)

These checks encode the findings of the 2026-09-14 security audit so the
class of issues found there cannot silently come back:
  - metadata.json / meta.js version + update-check URL consistency, and the
    update URL must be the fork's metadata.json (the old upstream URL pointed
    at a metadata.desktop that no longer exists -> 404 -> parser crash).
  - crypto_data.js: host whitelist for every URL, no dynamic-code tokens,
    every listed exchange must still have at least one usable pair.
  - icons referenced by the generated currencies must exist and be real SVGs
    (glm.svg was once a saved HTML 404 page).
  - main.xml defaults: valid XML/JSON, and every default exchange/crypto/pair
    must exist in the generated data with supported colors and intervals.
"""

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'src'

FIAT = {'CZK', 'EUR', 'GBP', 'JPY', 'PLN', 'USD'}
ALLOWED_TICKER_HOSTS = {
    'api1.binance.com',
    'www.bitstamp.net',
    'api.kraken.com',
    'coinmate.io',
    'api.zonda.exchange',
    # human-facing exchange websites carried in the 'url' field (shown in the
    # config dialog, opened only on explicit user click)
    'binance.com',
    'bitstamp.net',
    'kraken.com',
}
FORBIDDEN_TOKENS = ('eval(', 'XMLHttpRequest', 'atob(', 'document.', 'import(', 'fetch(')
ENTRY_KEYS = {
    'enabled', 'exchange', 'crypto', 'hideCryptoLogo', 'pair', 'refreshRate',
    'hidePriceDecimals', 'useCustomLocale', 'customLocaleName',
    'showPriceChangeMarker', 'showTrendingMarker', 'trendingTimeSpan',
    'flashOnPriceRaise', 'flashOnPriceRaiseColor', 'flashOnPriceDrop',
    'flashOnPriceDropColor', 'markerColorPriceRaise', 'markerColorPriceDrop',
}

problems = []


def check(cond, msg):
    if not cond:
        problems.append(msg)
    return cond


def js_const(js, name):
    m = re.search(r'const {}="([^"]*)"'.format(re.escape(name)), js)
    return m.group(1) if m else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--online', action='store_true',
                        help='Also fetch the update-check URL and validate it parses.')
    args = parser.parse_args()

    # --- metadata.json / meta.js consistency --------------------------------
    meta_json = json.loads((SRC / 'metadata.json').read_text())
    meta_js = (SRC / 'contents' / 'js' / 'meta.js').read_text()

    version_json = meta_json['KPlugin']['Version']
    version_js = js_const(meta_js, 'version')
    check(version_json == version_js,
          "version mismatch: metadata.json {!r} vs meta.js {!r}".format(version_json, version_js))

    url_json = meta_json.get('X-KDE-PluginInfo-UpdateChecker-Url', '')
    url_js = js_const(meta_js, 'updateCheckerUrl')
    check(url_json == url_js,
          "update-check URL mismatch: metadata.json {!r} vs meta.js {!r}".format(url_json, url_js))

    check(urlparse(url_json).netloc == 'raw.githubusercontent.com',
          "update-check URL must be raw.githubusercontent.com, got {!r}".format(url_json))
    check(url_json.endswith('/src/metadata.json'),
          "update-check URL must point at metadata.json (old metadata.desktop target 404s): {!r}".format(url_json))

    if args.online:
        import urllib.request
        with urllib.request.urlopen(url_json, timeout=15) as fh:
            remote = json.loads(fh.read().decode())
        check(remote['KPlugin']['Version'] == version_json,
              "remote metadata version {!r} != local {!r}".format(
                  remote['KPlugin']['Version'], version_json))

    # --- crypto_data.js ------------------------------------------------------
    data_file = SRC / 'contents' / 'js' / 'crypto_data.js'
    check(data_file.exists(), "missing generated file: {}".format(data_file))
    data_js = data_file.read_text() if data_file.exists() else ''

    urls = re.findall(r'https?://[^"\'`\s)]+',
                      re.sub(r'^\s*//.*$', '', data_js, flags=re.M))
    for url in urls:
        host = urlparse(url).netloc
        check(host in ALLOWED_TICKER_HOSTS,
              "unexpected host in crypto_data.js: {!r} ({})".format(host, url))
    for token in FORBIDDEN_TOKENS:
        check(token not in data_js,
              "forbidden token {!r} present in crypto_data.js".format(token))

    exchanges_block = re.findall(r'"([\w.-]+)":\s*\{\s*\n\t\t"name": "([^"]+)"(.*?)\n\t\},', data_js, re.S)
    check(len(exchanges_block) > 0, "no exchanges found in crypto_data.js")
    known_cryptos = set()
    exchange_pairs = {}   # exchange code -> {crypto -> [pairs]}
    for code, name, body in exchanges_block:
        cryptos = re.findall(r'"(\w+)":\s*\[([^\]]*)\]', body)
        pairs_total = sum(c[1].count('"') // 2 for c in cryptos)
        check(pairs_total > 0,
              "exchange {!r} ({}) has 0 supported pairs — dead API shipped?".format(code, name))
        exchange_pairs[code] = {}
        for crypto, pairs_blob in cryptos:
            known_cryptos.add(crypto)
            exchange_pairs[code][crypto] = re.findall(r'"(\w+)"', pairs_blob)
            check(re.fullmatch(r'[A-Z0-9]+', crypto) is not None,
                  "odd crypto code {!r} on {}".format(crypto, code))
            for pair in exchange_pairs[code][crypto]:
                check(re.fullmatch(r'[A-Z0-9]+', pair) is not None,
                      "odd pair code {!r} on {}".format(pair, code))

    # --- icons ---------------------------------------------------------------
    img_dir = SRC / 'contents' / 'images'
    for crypto in sorted(known_cryptos):
        if crypto in FIAT:
            continue  # fiat pairs have no coin icon (same as upstream's check)
        icon = img_dir / '{}.svg'.format(crypto.lower())
        if not check(icon.exists(), "missing icon for {}: {}".format(crypto, icon)):
            continue
        content = icon.read_text(errors='replace')
        check('<svg' in content.lower(),
              "icon for {} is not an SVG: {}".format(crypto, icon))

    # --- main.xml defaults ---------------------------------------------------
    cfg = ET.parse(SRC / 'contents' / 'config' / 'main.xml').getroot()
    # kcfg files use the KDE standards namespace; iter() does not support the
    # '{*}tag' wildcard, so derive the ns from the root tag instead.
    ns = re.match(r'\{([^}]+)\}', cfg.tag).group(1)
    entries = {e.get('name'): e for e in cfg.iter('{%s}entry' % ns)}
    check('exchanges' in entries, "main.xml has no 'exchanges' entry")
    default_el = entries['exchanges'].find('{%s}default' % ns)
    check(default_el is not None and (default_el.text or '').strip(),
          "main.xml 'exchanges' has no default value")
    defaults = json.loads(default_el.text)
    check(isinstance(defaults, list) and len(defaults) > 0,
          "main.xml 'exchanges' default must be a non-empty list")

    for i, entry in enumerate(defaults):
        check(set(entry.keys()) == ENTRY_KEYS,
              "default entry {} key set drift: missing={} extra={}".format(
                  i, ENTRY_KEYS - set(entry.keys()), set(entry.keys()) - ENTRY_KEYS))
        if not entry.get('enabled'):
            continue
        ex = entry.get('exchange')
        cr = entry.get('crypto')
        pr = entry.get('pair')
        if exchange_pairs:
            check(ex in exchange_pairs, "default entry {}: unknown exchange {!r}".format(i, ex))
            if ex in exchange_pairs and cr in exchange_pairs[ex]:
                check(pr in exchange_pairs[ex][cr],
                      "default entry {}: pair {!r} not supported for {!r} on {!r}".format(i, pr, cr, ex))
        check(isinstance(entry.get('refreshRate'), int) and 1 <= entry['refreshRate'] <= 600,
              "default entry {}: refreshRate out of range".format(i))
        for key in entry:
            if key.endswith('Color'):
                check(re.fullmatch(r'#[0-9a-fA-F]{6}', str(entry[key])) is not None,
                      "default entry {}: bad color {!r} in {}".format(i, entry[key], key))

    # --- config.qml pages exist ----------------------------------------------
    cfg_qml = (SRC / 'contents' / 'config' / 'config.qml').read_text()
    for src_path in re.findall(r'source:\s*"([^"]+)"', cfg_qml):
        check((SRC / 'contents' / 'ui' / src_path).exists(),
              "config.qml references missing page: {}".format(src_path))

    # --- verdict -------------------------------------------------------------
    if problems:
        print('FAILED ({}):'.format(len(problems)))
        for p in problems:
            print('  - {}'.format(p))
        return 1
    print('qa: OK — metadata sync, generated-data whitelist, icons, and defaults all valid.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
