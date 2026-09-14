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
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "../../js/crypto.js" as Crypto
import ".."


Kirigami.FormLayout {
	Layout.fillWidth: true
	id: controlRoot

	property alias cfg_customContainerLayoutEnabled: customContainerLayoutEnabled.checked
	property alias cfg_containerLayoutRows: layoutRows.value
	property alias cfg_containerLayoutColumns: layoutColumns.value
	property alias cfg_containerLayoutTransparentBackgroundEnabled: transparentBackground.checked
	property alias cfg_monochromeIcons: monochromeIcons.checked
	property alias cfg_monochromeIconUseTextColor: monochromeIconUseTextColor.checked
	property alias cfg_monochromeIconColor: monochromeIconColor.color

	// ------------------------------------------------------------------------------------------------------------------------

	CheckBox {
		id: customContainerLayoutEnabled
		text: i18n("Use custom grid layout")
		checked: cfg_customContainerLayoutEnabled
	}

	PlasmaComponents.SpinBox {
		id: layoutRows
		editable: true
		from: 1
		to: 25
		stepSize: 1
		Kirigami.FormData.label: i18n("Rows")
		value: cfg_containerLayoutRows
		enabled: cfg_customContainerLayoutEnabled
	}
	PlasmaComponents.SpinBox {
		id: layoutColumns
		editable: true
		from: 1
		to: 25
		stepSize: 1
		Kirigami.FormData.label: i18n("Columns")
		value: cfg_containerLayoutColumns
		enabled: cfg_customContainerLayoutEnabled
	}

	CheckBox {
		id: transparentBackground
		text: i18n("Transparent background")
		checked: cfg_containerLayoutTransparentBackgroundEnabled

		// If ConfigurableBackground is set, the we most likely run on Plasma 5.19+ and if so,
		// we prefer using widget's background control features instead.
		visible: typeof PlasmaCore.Types.ConfigurableBackground === "undefined"
	}

	Item {
		Layout.fillWidth: true
		height: Kirigami.Units.smallSpacing
	}

	CheckBox {
		id: monochromeIcons
		text: i18n("Monochrome icons")
	}

	CheckBox {
		id: monochromeIconUseTextColor
		text: i18n("Follow panel text colour")
		enabled: monochromeIcons.checked
	}

	KQControls.ColorButton {
		id: monochromeIconColor
		enabled: monochromeIcons.checked && !monochromeIconUseTextColor.checked
		Kirigami.FormData.label: i18n("Custom icon colour")
		dialogTitle: i18n("Monochrome icon colour")
	}

	Item {
		Layout.fillWidth: true
		Layout.fillHeight: true
	}

}
