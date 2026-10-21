import QtQuick
import QtQuick.Layouts

import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: configGeneral

    readonly property string defaultIdleIcon: "preferences-desktop-notification-bell-symbolic"
    property string cfg_idleIcon: Plasmoid.configuration.idleIcon

    KIconThemes.IconDialog {
        id: iconDialog
        onIconNameChanged: iconName => configGeneral.cfg_idleIcon = iconName || configGeneral.defaultIdleIcon
    }

    Kirigami.FormLayout {
        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.FormData.label: i18n("Idle icon")

            PlasmaComponents.Button {
                icon.name: configGeneral.cfg_idleIcon || configGeneral.defaultIdleIcon
                text: i18n("Choose icon")
                onClicked: iconDialog.open()
            }

            PlasmaComponents.Button {
                icon.name: "edit-clear"
                text: i18n("Reset")
                enabled: configGeneral.cfg_idleIcon !== configGeneral.defaultIdleIcon
                onClicked: configGeneral.cfg_idleIcon = configGeneral.defaultIdleIcon
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("This icon is shown in the panel when there are no notifications.")
        }
    }
}
