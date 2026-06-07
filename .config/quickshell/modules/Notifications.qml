import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications

import "../config"
import "../tools"
import "../tools/tray"

Item {
    id: notifications
    required property bool shown

    implicitHeight: notifCol.implicitHeight + Constants.trayPad * 2

    opacity: shown
        ? 1
        : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animDuration
            easing.type: Easing.OutCubic
        }
    }

    onShownChanged: {
        if (shown)
            Notifs.clearUnread()
    }

    ColumnLayout {
        id: notifCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Constants.trayPad
        spacing: Constants.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            TrayHeader {
                Layout.fillWidth: true
                label: "NOTIFICATIONS"
            }

            Rectangle {
                visible: Notifs.list.length > 0

                width: 68
                height: 22
                radius: 11
                color: Qt.alpha(QuickshellColors.surface_variant, 0.65)
                border.width: 1
                border.color: Qt.alpha(QuickshellColors.outline, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: "Clear all"
                    font.pixelSize: 9
                    font.letterSpacing: 0.3
                    color: QuickshellColors.on_surface_variant
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.dismissAll()
                }
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: 4
            visible: Notifs.list.length === 0

            Text {
                width: parent.width
                text: "󰂚"
                font.pixelSize: 26
                color: Qt.alpha(QuickshellColors.on_surface_variant, 0.35)
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: "No notifications"
                font.pixelSize: Constants.fontSizeXs
                color: Qt.alpha(QuickshellColors.on_surface_variant, 0.45)
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Repeater {
            model: Notifs.list

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: cardContent.implicitHeight + 18
                radius: Constants.radius - 4
                color: modelData.urgency === NotificationUrgency.Critical
                    ? Qt.alpha(QuickshellColors.error_container, 0.82)
                    : Qt.alpha(QuickshellColors.surface_container, 0.88)
                border.width: 1
                border.color: modelData.urgency === NotificationUrgency.Critical
                    ? Qt.alpha(QuickshellColors.error, 0.32)
                    : Qt.alpha(QuickshellColors.outline, 0.2)

                Column {
                    id: cardContent
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 9
                    anchors.leftMargin: 12
                    anchors.rightMargin: 38
                    spacing: 3

                    Text {
                        width: parent.width
                        text: modelData.appName || "Notification"
                        font.pixelSize: 9
                        font.letterSpacing: 0.5
                        font.capitalization: Font.AllUppercase
                        color: modelData.urgency === NotificationUrgency.Critical
                            ? Qt.alpha(QuickshellColors.on_error_container, 0.75)
                            : QuickshellColors.on_surface_variant
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: modelData.summary || ""
                        font.pixelSize: Constants.fontSizeXs
                        font.weight: Font.Medium
                        color: modelData.urgency === NotificationUrgency.Critical
                            ? QuickshellColors.on_error_container
                            : QuickshellColors.on_surface
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }

                    Text {
                        width: parent.width
                        text: modelData.body || ""
                        font.pixelSize: 10
                        color: modelData.urgency === NotificationUrgency.Critical
                            ? Qt.alpha(QuickshellColors.on_error_container, 0.82)
                            : QuickshellColors.on_surface_variant
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 7
                    text: "󰅖"
                    font.pixelSize: 13
                    color: Qt.alpha(QuickshellColors.on_surface_variant, 0.55)

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dismiss(modelData)
                    }
                }
            }
        }
    }
}
