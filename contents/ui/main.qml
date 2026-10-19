import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.notificationmanager as NotificationManager

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation

    NotificationManager.Settings {
        id: notifSettings
    }

    NotificationManager.Notifications {
        id: notifModel
        showExpired: true
        showDismissed: false
        showJobs: false
        groupMode: NotificationManager.Notifications.GroupDisabled
        sortMode: NotificationManager.Notifications.SortByDate

        onCountChanged: rebuildTimer.restart()
        onRowsInserted: rebuildTimer.restart()
        onRowsRemoved: rebuildTimer.restart()
        onDataChanged: rebuildTimer.restart()
        onModelReset: rebuildTimer.restart()
    }

    Timer {
        id: rebuildTimer
        interval: 50
        repeat: false
        onTriggered: root.syncUniqueApps()
    }

    ListModel {
        id: uniqueAppsModel
    }

    function formatRelativeTime(dateVal) {
        if (!dateVal) return "";
        let now = new Date();
        let diffSec = Math.floor((now.getTime() - dateVal.getTime()) / 1000);
        if (isNaN(diffSec) || diffSec < 60) return "Just now";
        let diffMin = Math.floor(diffSec / 60);
        if (diffMin < 60) return diffMin + " min ago";
        let diffHr = Math.floor(diffMin / 60);
        if (diffHr < 24) return diffHr + " hr ago";
        return Qt.formatDateTime(dateVal, "dd MMM, hh:mm");
    }

    function syncUniqueApps() {
        uniqueAppsModel.clear();
        let groups = {};
        let order = [];

        for (let i = 0; i < notifModel.count; i++) {
            let idx = notifModel.index(i, 0);

            let isTransient = notifModel.data(idx, NotificationManager.Notifications.TransientRole);
            let isExpired = notifModel.data(idx, NotificationManager.Notifications.ExpiredRole);
            if (isTransient && isExpired) {
                continue;
            }

            let appName = notifModel.data(idx, NotificationManager.Notifications.AppNameRole) || "";
            let desktopEntry = notifModel.data(idx, NotificationManager.Notifications.DesktopEntryRole) || "";
            let iconName = notifModel.data(idx, NotificationManager.Notifications.IconNameRole) || "";
            let summary = notifModel.data(idx, NotificationManager.Notifications.SummaryRole) || "";

            let key = desktopEntry || appName || iconName || ("unknown_" + i);
            let resolvedIcon = iconName || desktopEntry || "preferences-desktop-notification";

            if (!groups[key]) {
                groups[key] = {
                    groupKey: key,
                    appName: appName || desktopEntry || "Notification",
                    iconSource: resolvedIcon,
                    summary: summary,
                    badgeCount: 1
                };
                order.push(key);
            } else {
                groups[key].badgeCount += 1;
            }
        }

        for (let k of order) {
            uniqueAppsModel.append(groups[k]);
        }
    }

    function closeSingleNotification(row) {
        let idx = notifModel.index(row, 0);
        let isExpired = notifModel.data(idx, NotificationManager.Notifications.ExpiredRole);
        notifModel.close(idx);
        if (isExpired) {
            rebuildTimer.restart();
        }
    }

    function clearAppGroup(targetKey) {
        for (let i = notifModel.count - 1; i >= 0; i--) {
            let idx = notifModel.index(i, 0);
            let appName = notifModel.data(idx, NotificationManager.Notifications.AppNameRole) || "";
            let desktopEntry = notifModel.data(idx, NotificationManager.Notifications.DesktopEntryRole) || "";
            let iconName = notifModel.data(idx, NotificationManager.Notifications.IconNameRole) || "";
            let key = desktopEntry || appName || iconName || ("unknown_" + i);

            if (key === targetKey) {
                notifModel.close(idx);
            }
        }
        rebuildTimer.restart();
    }

    function clearAllNotifications() {
        notifModel.clear(NotificationManager.Notifications.ClearExpired);
        for (let i = notifModel.count - 1; i >= 0; i--) {
            notifModel.close(notifModel.index(i, 0));
        }
        rebuildTimer.restart();
    }

    Component.onCompleted: rebuildTimer.restart()

    // COMPACT REPRESENTATION: Deduplicated Panel Icons with Left/Right Growth
    compactRepresentation: MouseArea {
        id: compactRoot

        readonly property real calculatedWidth: Math.max(layoutRow.implicitWidth + 10, 26)
        implicitWidth: calculatedWidth
        Layout.minimumWidth: calculatedWidth
        Layout.preferredWidth: calculatedWidth
        Layout.maximumWidth: calculatedWidth
        Layout.fillHeight: true

        readonly property bool isOnRightHalf: {
            let globalPos = compactRoot.mapToGlobal(0, 0);
            return globalPos.x > (Screen.width / 2);
        }

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.expanded = !root.expanded;
        }

        RowLayout {
            id: layoutRow
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: compactRoot.isOnRightHalf ? undefined : parent.left
            anchors.right: compactRoot.isOnRightHalf ? parent.right : undefined
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 6
            layoutDirection: compactRoot.isOnRightHalf ? Qt.RightToLeft : Qt.LeftToRight

            Kirigami.Icon {
                visible: uniqueAppsModel.count === 0
                source: "preferences-desktop-notification-bell-symbolic"
                opacity: compactRoot.containsMouse ? 0.9 : 0.55
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
            }

            Repeater {
                model: uniqueAppsModel

                delegate: Item {
                    required property string groupKey
                    required property string appName
                    required property string iconSource
                    required property string summary
                    required property int badgeCount

                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: 4
                        color: Kirigami.Theme.highlightColor
                        opacity: iconMouse.containsMouse ? 0.25 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Kirigami.Icon {
                        anchors.fill: parent
                        source: parent.iconSource
                        active: iconMouse.containsMouse
                    }

                    Rectangle {
                        visible: parent.badgeCount > 1
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -3
                        anchors.bottomMargin: -2
                        width: Math.max(badgeLabel.implicitWidth + 6, 14)
                        height: 14
                        radius: 7
                        color: Kirigami.Theme.highlightColor
                        border.width: 1
                        border.color: Kirigami.Theme.backgroundColor

                        PlasmaComponents.Label {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: parent.parent.badgeCount > 9 ? "9+" : parent.parent.badgeCount
                            font.pixelSize: 9
                            font.bold: true
                            color: Kirigami.Theme.highlightedTextColor
                        }
                    }

                    // Tooltip completely disabled
                    QQC2.ToolTip.visible: false

                    MouseArea {
                        id: iconMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.MiddleButton) {
                                root.clearAppGroup(groupKey);
                            } else {
                                root.expanded = !root.expanded;
                            }
                        }
                    }
                }
            }
        }
    }

    // FULL REPRESENTATION: Fully Interactive Popup Window
    fullRepresentation: PlasmaExtras.Representation {
        id: popupDialog
        implicitWidth: Kirigami.Units.gridUnit * 24
        implicitHeight: Math.min(
            Math.max(listView.contentHeight + headingItem.height + 40, Kirigami.Units.gridUnit * 10),
                                 Screen.height * 0.75
        )
        collapseMarginsHint: true

        header: PlasmaExtras.PlasmoidHeading {
            id: headingItem
            topPadding: Kirigami.Units.smallSpacing * 2
            bottomPadding: Kirigami.Units.smallSpacing * 2
            leftPadding: Kirigami.Units.largeSpacing
            rightPadding: Kirigami.Units.largeSpacing

            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing * 2

                    Kirigami.Heading {
                        level: 3
                        text: "Notifications"
                        Layout.fillWidth: true
                    }

                    PlasmaComponents.ToolButton {
                        icon.name: "edit-clear-history"
                        visible: notifModel.count > 0
                        onClicked: root.clearAllNotifications()
                        QQC2.ToolTip.text: "Clear all notifications"
                        QQC2.ToolTip.visible: hovered
                    }

                    PlasmaComponents.ToolButton {
                        icon.name: "configure"
                        onClicked: {
                            Qt.openUrlExternally("systemsettings://kcm_notifications");
                        }
                        QQC2.ToolTip.text: "Notification Settings"
                        QQC2.ToolTip.visible: hovered
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Switch {
                        id: dndSwitch
                        text: "Do not disturb"
                        checked: {
                            let now = new Date();
                            return (notifSettings.notificationsInhibitedUntil && notifSettings.notificationsInhibitedUntil > now)
                            || notifSettings.notificationsInhibitedByApplication;
                        }
                        onToggled: {
                            if (checked) {
                                let d = new Date();
                                d.setFullYear(d.getFullYear() + 1);
                                notifSettings.notificationsInhibitedUntil = d;
                            } else {
                                notifSettings.notificationsInhibitedUntil = new Date(0);
                            }
                            notifSettings.save();
                        }
                    }
                }
            }
        }

        contentItem: Item {
            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - (Kirigami.Units.largeSpacing * 4)
                visible: notifModel.count === 0
                iconName: dndSwitch.checked ? "notifications-disabled" : "preferences-desktop-notification-bell"
                text: dndSwitch.checked ? "Do Not Disturb is enabled" : "No unread notifications"
            }

            PlasmaComponents.ScrollView {
                anchors.fill: parent
                visible: notifModel.count > 0

                ListView {
                    id: listView
                    model: notifModel
                    clip: true
                    spacing: 0

                    delegate: ColumnLayout {
                        id: card
                        required property int index
                        required property var model

                        width: listView.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: mainCol.implicitHeight + (Kirigami.Units.largeSpacing * 2)
                            color: cardHover.hovered
                            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.08)
                            : "transparent"

                            HoverHandler {
                                id: cardHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                cursorShape: model.hasDefaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        root.closeSingleNotification(index);
                                    } else if (model.hasDefaultAction) {
                                        notifModel.invokeDefaultAction(notifModel.index(index, 0));
                                    }
                                }
                            }

                            ColumnLayout {
                                id: mainCol
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.largeSpacing
                                spacing: Kirigami.Units.smallSpacing * 1.5

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.smallSpacing * 1.5

                                    Kirigami.Icon {
                                        source: model.iconName || model.desktopEntry || "preferences-desktop-notification"
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    PlasmaComponents.Label {
                                        text: {
                                            let app = model.appName || "System";
                                            let origin = model.originName || "";
                                            return origin ? (app + " · " + origin) : app;
                                        }
                                        elide: Text.ElideMiddle
                                        opacity: 0.85
                                        Layout.fillWidth: true
                                    }

                                    PlasmaComponents.Label {
                                        text: root.formatRelativeTime(model.updated || model.created)
                                        opacity: 0.6
                                    }

                                    PlasmaComponents.ToolButton {
                                        visible: model.configurable || false
                                        icon.name: "configure"
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        onClicked: notifModel.configure(notifModel.index(index, 0))
                                        QQC2.ToolTip.text: "Configure Notification..."
                                        QQC2.ToolTip.visible: hovered
                                    }

                                    PlasmaComponents.ToolButton {
                                        icon.name: "window-close-symbolic"
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        onClicked: root.closeSingleNotification(index)
                                        QQC2.ToolTip.text: "Close"
                                        QQC2.ToolTip.visible: hovered
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.largeSpacing

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        PlasmaComponents.Label {
                                            visible: text !== ""
                                            text: model.summary || ""
                                            font.bold: true
                                            wrapMode: Text.Wrap
                                            Layout.fillWidth: true
                                        }

                                        PlasmaComponents.Label {
                                            visible: text !== ""
                                            text: model.body || ""
                                            textFormat: Text.RichText
                                            wrapMode: Text.Wrap
                                            Layout.fillWidth: true
                                            onLinkActivated: (link) => Qt.openUrlExternally(link)
                                        }
                                    }

                                    Kirigami.Icon {
                                        visible: model.image !== undefined && model.image !== null && model.image !== ""
                                        source: model.image
                                        Layout.preferredWidth: 48
                                        Layout.preferredHeight: 48
                                        Layout.alignment: Qt.AlignTop
                                    }
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignRight
                                    layoutDirection: Qt.RightToLeft
                                    spacing: Kirigami.Units.smallSpacing
                                    visible: (model.actionNames && model.actionNames.length > 0) || (model.hasReplyAction || false)

                                    Repeater {
                                        model: card.model.actionNames ? card.model.actionNames.length : 0

                                        delegate: PlasmaComponents.Button {
                                            required property int index
                                            text: card.model.actionLabels[index] || card.model.actionNames[index]
                                            onClicked: {
                                                let actionId = card.model.actionNames[index];
                                                notifModel.invokeAction(
                                                    notifModel.index(card.index, 0),
                                                                        actionId,
                                                                        NotificationManager.Notifications.None
                                                );
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: model.hasReplyAction || false
                                    spacing: Kirigami.Units.smallSpacing

                                    PlasmaComponents.TextField {
                                        id: replyField
                                        Layout.fillWidth: true
                                        placeholderText: model.replyPlaceholderText || "Type a reply..."
                                        onAccepted: replyBtn.clicked()
                                    }

                                    PlasmaComponents.Button {
                                        id: replyBtn
                                        icon.name: model.replySubmitButtonIconName || "document-send"
                                        text: model.replySubmitButtonText || "Send"
                                        enabled: replyField.text.length > 0
                                        onClicked: {
                                            notifModel.reply(
                                                notifModel.index(card.index, 0),
                                                             replyField.text,
                                                             NotificationManager.Notifications.None
                                            );
                                            replyField.text = "";
                                        }
                                    }
                                }
                            }
                        }

                        Kirigami.Separator {
                            Layout.fillWidth: true
                            opacity: 0.5
                        }
                    }
                }
            }
        }
    }
}
