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
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../js/crypto.js" as Crypto
import "../../js/fiat.js" as Fiat
import ".."

Item {
	id: configExchanges

	Layout.fillWidth: true

	property alias cfg_exchanges: serializedExchanges.text

	Text {
		id: serializedExchanges
		visible: false
		onTextChanged: {
			exchangesModel.clear()
			try {
				JSON.parse(serializedExchanges.text).forEach(function (ex) {
					// Normalize every row to the FULL role set before append.
					// ListModel infers roles from appended rows; rows without
					// a role added by an earlier row would leave delegates
					// (already bound) seeing undefined — the listview then
					// rendered FX entries as crypto ones.
					exchangesModel.append({
						'enabled': ex.enabled !== undefined ? ex.enabled : true,
						'type': ex.type || 'crypto',
						'exchange': ex.exchange || '',
						'crypto': ex.crypto || '',
						'fxBase': ex.fxBase || '',
						'fxQuote': ex.fxQuote || '',
						'fxDecimals': ex.fxDecimals !== undefined ? ex.fxDecimals : 0,
						'fxHideSymbol': ex.fxHideSymbol !== undefined ? ex.fxHideSymbol : false,
						'hideCryptoLogo': ex.hideCryptoLogo !== undefined ? ex.hideCryptoLogo : false,
						'pair': ex.pair || '',
						'refreshRate': ex.refreshRate !== undefined ? ex.refreshRate : 5,
						'hidePriceDecimals': ex.hidePriceDecimals !== undefined ? ex.hidePriceDecimals : false,
						'useCustomLocale': ex.useCustomLocale !== undefined ? ex.useCustomLocale : false,
						'customLocaleName': ex.customLocaleName || '',
						'showPriceChangeMarker': ex.showPriceChangeMarker !== undefined ? ex.showPriceChangeMarker : true,
						'showTrendingMarker': ex.showTrendingMarker !== undefined ? ex.showTrendingMarker : true,
						'trendingTimeSpan': ex.trendingTimeSpan !== undefined ? ex.trendingTimeSpan : 60,
						'flashOnPriceRaise': ex.flashOnPriceRaise !== undefined ? ex.flashOnPriceRaise : true,
						'flashOnPriceRaiseColor': ex.flashOnPriceRaiseColor || '#78c625',
						'flashOnPriceDrop': ex.flashOnPriceDrop !== undefined ? ex.flashOnPriceDrop : true,
						'flashOnPriceDropColor': ex.flashOnPriceDropColor || '#ff006e',
						'markerColorPriceRaise': ex.markerColorPriceRaise || '#78c625',
						'markerColorPriceDrop': ex.markerColorPriceDrop || '#ff006e',
					})
				})
			} catch (error) {
				// Corrupt stored config must not kill the settings dialog.
				console.error('Exchanges: failed to parse config JSON:', error)
			}
		}
	}

	ExchangeModel {
		id: exchangesModel
	}

	RowLayout {
		anchors.fill: parent

		Layout.alignment: Qt.AlignTop | Qt.AlignRight

		// ListView replacement for deprecated TableView
		Rectangle {
			Layout.fillWidth: true
			Layout.fillHeight: true
			color: Kirigami.Theme.backgroundColor
			border.color: Kirigami.Theme.disabledTextColor
			border.width: 1

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 1
				spacing: 0

				// Header row
				Rectangle {
					Layout.fillWidth: true
					height: 30
					color: Kirigami.Theme.alternateBackgroundColor

					RowLayout {
						anchors.fill: parent
						anchors.leftMargin: 10
						anchors.rightMargin: 10
						spacing: 10

						PlasmaComponents.Label {
							Layout.preferredWidth: parent.width * 0.4
							text: i18n("Exchange")
							font.bold: true
						}
						PlasmaComponents.Label {
							Layout.preferredWidth: parent.width * 0.3
							text: i18n("Crypto")
							font.bold: true
						}
						PlasmaComponents.Label {
							Layout.fillWidth: true
							text: i18n("Pair")
							font.bold: true
						}
					}
				}

				// List view
				ListView {
					id: exchangesList
					Layout.fillWidth: true
					Layout.fillHeight: true
					clip: true
					model: exchangesModel
					currentIndex: -1

					delegate: Rectangle {
						width: exchangesList.width
						height: 35
						color: ListView.isCurrentItem ? Kirigami.Theme.highlightColor : (index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor)

						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: 10
							anchors.rightMargin: 10
							spacing: 10

							PlasmaComponents.Label {
								Layout.preferredWidth: parent.width * 0.4
								text: {
									var res = model.enabled ? '' : '(L) '
									if (model.type === 'fx') {
										return res + i18n('Fiat FX (fawazahmed0)')
									}
									return res + Crypto.getExchangeName(model.exchange)
								}
								color: ListView.isCurrentItem ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
							}
							PlasmaComponents.Label {
								Layout.preferredWidth: parent.width * 0.3
								text: model.type === 'fx'
										? Fiat.getName(model.fxBase)
										: Crypto.getCryptoName(model.crypto)
								color: ListView.isCurrentItem ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
							}
							PlasmaComponents.Label {
								Layout.fillWidth: true
								text: model.type === 'fx'
										? model.fxQuote + ' (' + Fiat.getName(model.fxQuote) + ')'
										: Crypto.getCurrencyName(model.pair)
								color: ListView.isCurrentItem ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
							}
						}

						MouseArea {
							anchors.fill: parent
							onClicked: exchangesList.currentIndex = index
							onDoubleClicked: {
								exchangesList.currentIndex = index
								editExchange(index)
							}
						}
					}

					PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar { }
				}
			}
		}

		ColumnLayout {
			id: tableActionButtons
			Layout.alignment: Qt.AlignTop
			Layout.fillWidth: false

			PlasmaComponents.Button {
				Layout.preferredWidth: Kirigami.Units.gridUnit * 8
				text: i18n("Add")
				icon.name: "list-add"
				onClicked: addExchange()
			}

			PlasmaComponents.Button {
				Layout.preferredWidth: Kirigami.Units.gridUnit * 8
				text: i18n("Add FX pair")
				icon.name: "list-add"
				onClicked: addExchange(true)
			}

			PlasmaComponents.Button {
				Layout.preferredWidth: Kirigami.Units.gridUnit * 8
				text: i18n("Edit")
				icon.name: "edit-entry"
				onClicked: editExchange(exchangesList.currentIndex)
				enabled: {
					var idx = exchangesList.currentIndex
					return (idx !== -1) && (idx < exchangesModel.count)
				}
			}

			PlasmaComponents.Button {
				Layout.preferredWidth: Kirigami.Units.gridUnit * 8
				text: i18n("Remove")
				icon.name: "list-remove"
				onClicked: removeExchange(exchangesList.currentIndex)
				enabled: {
					var idx = exchangesList.currentIndex
					return (idx !== -1) && (idx < exchangesModel.count)
				}
			}

			PlasmaComponents.Button {
				Layout.preferredWidth: Kirigami.Units.gridUnit * 8
				text: i18n("Move Up")
				icon.name: "arrow-up"
				onClicked: {
					var from = exchangesList.currentIndex
					var to = from - 1
					exchangesModel.move(from, to, 1)
					exchangesList.currentIndex = to
					saveExchanges()
				}
				enabled: {
					var idx = exchangesList.currentIndex
					return (idx > 0) && (idx < exchangesModel.count)
				}
			}

			PlasmaComponents.Button {
				Layout.preferredWidth: Kirigami.Units.gridUnit * 8
				text: i18n("Move Down")
				icon.name: "arrow-down"
				onClicked: {
					var from = exchangesList.currentIndex
					var to = from + 1
					exchangesModel.move(from, to, 1)
					exchangesList.currentIndex = to
					saveExchanges()
				}
				enabled: {
					var idx = exchangesList.currentIndex
					return (idx !== -1) && ((idx + 1) < exchangesModel.count)
				}
			}


		} // ColumnLayout
	} // RowLayout

	// ------------------------------------------------------------------------------------------------------------------------

	property int selectedRow: -1

	function saveExchanges() {
		var exchanges = []
		for(var i=0; i<exchangesModel.count; i++) {
			exchanges.push(exchangesModel.get(i))
		}
		serializedExchanges.text = JSON.stringify(exchanges)
	}

	function addExchange(asFx) {
		exchange.init(asFx)
		selectedRow = -1
		exchangeEditDialog.visible = true
	}

	function editExchange(idx) {
		if (idx === -1) return

		if ((idx+1) > exchangesModel.count) return

		exchange.fromJson(exchangesModel.get(idx))

		selectedRow = idx
		exchangeEditDialog.visible = true
	}

	function removeExchange(idx) {
		if (idx === -1) return

		if ((idx+1) > exchangesModel.count) return

		exchangesModel.remove(idx)
		saveExchanges()
	}

	// ------------------------------------------------------------------------------------------------------------------------

	Dialog {
		id: exchangeEditDialog
		visible: false
		title: i18n("Exchange")
		standardButtons: Dialog.Save | Dialog.Cancel

		width: Kirigami.Units.gridUnit * 28
		height: Kirigami.Units.gridUnit * 36

		onAccepted: {
			var ex = exchange.toJson()
			if (selectedRow === -1) {
				exchangesModel.append(ex)
			} else {
				exchangesModel.set(selectedRow, ex)
			}
			saveExchanges();
		}

		contentItem: PlasmaComponents.ScrollView {
			PlasmaComponents.ScrollBar.horizontal.policy: PlasmaComponents.ScrollBar.AlwaysOff

			ExchangeConfig {
				id: exchange
				width: parent.width
			}
		}
	}

} // Item
