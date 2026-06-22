import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../config"
import "../tools"

PanelWindow {
    id: popup

    anchors.right: true
    anchors.top: true

    Component.onCompleted: {
        if (WlrLayershell != null) {
            WlrLayershell.layer = WlrLayer.Top
            WlrLayershell.namespace = "qs-notification-popup"
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
        }
    }

    property var currentNotif: null
    property var nextNotif: null

    implicitWidth: 340
    implicitHeight: currentNotif !== null
        ? popupCard.implicitHeight + Constants.margins * 2
        : 1
    color: "transparent"

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Constants.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: dismissTimer

        onTriggered: {
            popup.currentNotif = null
            if (popup.nextNotif !== null) {
                popup.currentNotif = popup.nextNotif
                popup.nextNotif = null
                dismissTimer.interval = resolveTimeout(popup.currentNotif)
                dismissTimer.restart()
            }
        }
    }

    function resolveTimeout(notif) {
        if (!notif)
            return 5000
        return notif.timeout > 0
            ? notif.timeout
            : 5000
    }

    Connections {
        target: Notifs

        function onNewNotification(notif) {
            if (popup.currentNotif !== null)
                popup.nextNotif = notif
            else {
                popup.currentNotif = notif
                dismissTimer.interval = popup.resolveTimeout(notif)
                dismissTimer.restart()
            }
        }
    }

    Rectangle {
        id: popupCard
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Constants.margins
        implicitHeight: cardInner.implicitHeight + 18
        radius: Constants.radius
        color: Qt.alpha(QuickshellColors.surface_container, 0.96)
        border.width: 1
        border.color: Qt.alpha(QuickshellColors.outline, 0.28)
        visible: popup.currentNotif !== null

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 3
            radius: 2
            color: popup.currentNotif && popup.currentNotif.urgency === 2
                ? QuickshellColors.error
                : QuickshellColors.primary
        }

        Column {
            id: cardInner
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 9
            anchors.leftMargin: 16
            anchors.rightMargin: 38
            spacing: 3

            Text {
                width: parent.width
                text: popup.currentNotif
                    ? (popup.currentNotif.appName || "")
                    : ""
                font.pixelSize: 9
                font.letterSpacing: 0.5
                font.capitalization: Font.AllUppercase
                color: QuickshellColors.on_surface_variant
                elide: Text.ElideRight
                visible: text.length > 0
            }

            Text {
                width: parent.width
                text: popup.currentNotif
                    ? (popup.currentNotif.summary || "")
                    : ""
                font.pixelSize: Constants.fontSizeSm
                font.bold: true
                color: QuickshellColors.on_surface
                elide: Text.ElideRight
                visible: text.length > 0
            }

            Text {
                width: parent.width
                text: popup.currentNotif
                    ? (popup.currentNotif.body || "")
                    : ""
                font.pixelSize: Constants.fontSizeXs
                color: QuickshellColors.on_surface_variant
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }

        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            text: "󰅖"
            font.pixelSize: 13
            color: Qt.alpha(QuickshellColors.on_surface_variant, 0.55)

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    dismissTimer.stop()
                    popup.currentNotif = null
                    if (popup.nextNotif !== null) {
                        popup.currentNotif = popup.nextNotif
                        popup.nextNotif = null
                        dismissTimer.interval = popup.resolveTimeout(popup.currentNotif)
                        dismissTimer.restart()
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: dismissTimer.stop()
            onExited: {
                dismissTimer.interval = 2000
                dismissTimer.restart()
            }
        }
    }
}
