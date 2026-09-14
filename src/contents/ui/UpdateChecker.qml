/**
 * Crypto Tracker widget for KDE
 *
 * @author    Marcin Orlowski <mail (#) marcinOrlowski (.) com>
 * @copyright 2021-2026 Marcin Orlowski
 * @license   http://www.opensource.org/licenses/mit-license.php MIT
 * @link      https://github.com/MarcinOrlowski/crypto-tracker-plasmoid
 */

import QtQuick
import QtCore
import "../js/meta.js" as Meta

Item {
	// URL to metadata file of recent stable public release. Must point at a
	// JSON metadata.json — upstream's old URL referenced a metadata.desktop
	// that no longer exists in the repo (404), which crashed the old parser.
	property string plasmoidUMetaDataUrl: Meta.updateCheckerUrl

	// Periodic update check interval (millis). Timer disabled if set to 0
	property var checkInterval: 0

	Timer {
		interval: checkInterval
		repeat: true
		running: checkInterval !== 0
		triggeredOnStart: checkInterval !== 0
		onTriggered: checkUpdateAvailability()
	}

	NotificationManager {
		id: updateCheckerNotificationManager
	}

	Settings {
		id: updateCheckerSettings
		category: "UpdateChecker"
		property string lastVersionCheckDate: ''
	}

	/** 'x[.y[.z]]' → single integer suitable for < / > comparisons. */
	function versionToNumber(v) {
		var parts = String(v || '').split('.')
		var num = 0
		for (var i = 0; i < 3; i++) {
			num = (num * 100) + ((i < parts.length && parseInt(parts[i], 10)) || 0)
		}
		return num
	}

	function checkUpdateAvailability(force) {
		if (force === undefined) force = false

		var d = new Date()
		var today = d.getFullYear() + '-' + d.getMonth() + '-' + d.getDate()
		if (!force && today === updateCheckerSettings.lastVersionCheckDate) {
			return
		}

		var xhr = new XMLHttpRequest()
		xhr.open('GET', plasmoidUMetaDataUrl)
		xhr.onreadystatechange = (function () {
			// We only care about DONE readyState.
			if (xhr.readyState !== 4) return
			if (xhr.status !== 200) {
				console.debug('checkUpdateAvailability(): HTTP ' + xhr.status + ' for ' + plasmoidUMetaDataUrl)
				return
			}

			updateCheckerSettings.lastVersionCheckDate = today

			var remoteVersion = ''
			try {
				remoteVersion = JSON.parse(xhr.responseText)['KPlugin']['Version']
			} catch (error) {
				console.error('checkUpdateAvailability(): failed to parse metadata:', error)
				return
			}

			if (versionToNumber(remoteVersion) > versionToNumber(Meta.version)) {
				updateCheckerNotificationManager.post({
					'title': Meta.title,
					'summary': i18n("New version (v%1) available!", remoteVersion),
					'body': i18n("You are currently using version %1. See project page for more information (link in About dialog).", Meta.version),
					'expireTimeout': 0,
				});
			} else {
				if (force) {
					updateCheckerNotificationManager.post({
						'title': Meta.title,
						'summary': i18n("No update available."),
						'body': i18n("You are using most recent version of %1.", Meta.title),
						'expireTimeout': 1000 * 10,
					});
				}
			}
		});
		xhr.send()
	}
}
