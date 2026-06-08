import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../tools"
import "../tools/tray"
import "../config"

PanelWindow {
    id: bar
    anchors.left: true
    anchors.top: true
    anchors.bottom: true
    color: "transparent"
    exclusiveZone: Constants.barWidth

    Component.onCompleted: {
        if (WlrLayershell != null) {
            WlrLayershell.layer = WlrLayer.Top
            WlrLayershell.namespace = "qs-bar"
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
        }
    }

    property string openTray: ""

    property real openTrayIconCenterY: 0
    property real openTrayIconHeight: 42
    property bool showLockScreen: false

    Timer {
        id: closeTimer
        interval: 260
        repeat: false
        onTriggered: bar.openTray = ""
    }

    function cancelClose() {
        closeTimer.stop()
    }

    function startClose() {
        closeTimer.restart()
    }

    property real currentTrayHeight: {
        if (openTray === "system")
            return system.implicitHeight
        if (openTray === "datetime")
            return datetime.implicitHeight
        if (openTray === "media")
            return media.implicitHeight
        if (openTray === "bluetooth")
            return bluetooth.implicitHeight
        if (openTray === "battery")
            return battery.implicitHeight
        if (openTray === "power")
            return power.implicitHeight
        if (openTray === "notifications")
            return notifications.implicitHeight
        return 0
    }

    property real computedTrayY: {
        var iconCenterY = openTrayIconCenterY
        var iconTop = iconCenterY - openTrayIconHeight / 2
        var iconBot = iconCenterY + openTrayIconHeight / 2
        var h = currentTrayHeight
        var margin = Constants.margins
        var barH = bar.height
        var y = (iconCenterY <= barH / 2)
            ? iconTop
            : (iconBot - h)
        return Math.max(margin, Math.min(barH - margin - h, y))
    }

    implicitWidth: openTray !== ""
        ? Constants.barWidth + Constants.popoutWidth + Constants.margins
        : Constants.barWidth

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Constants.animDurationSlow
            easing.type: Easing.OutCubic
        }
    }

    Process {
        id: lockPipeProc
        command: ["bash", "-c", "PIPE=\"$XDG_RUNTIME_DIR/qs-lock\"; " + "[ -p \"$PIPE\" ] || mkfifo \"$PIPE\"; " + "while true; do cat \"$PIPE\"; done"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.trim().length > 0)
                    bar.showLockScreen = true
            }
        }

        onExited: Qt.callLater(function() { lockPipeProc.running = true })
    }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.topMargin: Constants.margins
        anchors.bottomMargin: Constants.margins
        anchors.leftMargin: Constants.margins
        width: Constants.barWidth - Constants.margins * 2
        radius: Constants.radius
        clip: true
        color: Qt.alpha(QuickshellColors.surface, 0.75)
        border.width: 1
        border.color: Qt.alpha(QuickshellColors.outline, 0.22)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Constants.margins
            spacing: Constants.spacing

            BarTray {
                icon: "󱒔"
                tray: "system"
                bar: bar
            }

            BarTray {
                icon: "󰃰"
                tray: "datetime"
                bar: bar
            }

            BarTray {
                icon: "󰎇"
                tray: "media"
                bar: bar
            }

            BarTray {
                icon: bluetooth.powered
                    ? "󰂯"
                    : "󰂲"
                tray: "bluetooth"
                bar: bar
            }

            BarDivider {}

            Item {
                Layout.fillHeight: true
            }

            Workspaces {}

            Item {
                Layout.fillHeight: true
            }

            BarDivider {}

            BarTray {
                icon: Notifs.list.length > 0
                    ? "󱅫"
                    : "󰂚"
                tray: "notifications"
                bar: bar
                badge: Notifs.unreadCount
            }

            BarTray {
                icon: battery.batteryIcon
                tray: "battery"
                bar: bar
            }

            BarTray {
                icon: "󰐥"
                tray: "power"
                bar: bar
            }
        }
    }

    Rectangle {
        id: trayPanel
        x: Constants.barWidth + Constants.margins / 2
        y: bar.computedTrayY
        width: Constants.popoutWidth - Constants.margins
        height: Math.max(1, bar.currentTrayHeight)
        clip: true
        radius: Constants.radius
        color: Qt.alpha(QuickshellColors.surface, 0.75)
        border.width: 1
        border.color: Qt.alpha(QuickshellColors.outline, 0.22)
        opacity: bar.openTray !== ""
            ? 1
            : 0
        enabled: bar.openTray !== ""

        Behavior on y {
            NumberAnimation {
                duration: Constants.animDurationSlow
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Constants.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Constants.animDuration
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    bar.cancelClose()
                else
                    bar.startClose()
            }
        }

        System {
            id: system
            width: parent.width
            enabled: bar.openTray === "system"
            shown: bar.openTray === "system"
        }

        Datetime {
            id: datetime
            width: parent.width
            enabled: bar.openTray === "datetime"
            shown: bar.openTray === "datetime"
        }

        Media {
            id: media
            width: parent.width
            enabled: bar.openTray === "media"
            shown: bar.openTray === "media"
        }

        Bluetooth {
            id: bluetooth
            width: parent.width
            enabled: bar.openTray === "bluetooth"
            shown: bar.openTray === "bluetooth"
        }

        Notifications {
            id: notifications
            width: parent.width
            enabled: bar.openTray === "notifications"
            shown: bar.openTray === "notifications"
        }

        Battery {
            id: battery
            width: parent.width
            enabled: bar.openTray === "battery"
            shown: bar.openTray === "battery"
        }

        Power {
            id: power
            width: parent.width
            enabled: bar.openTray === "power"
            shown: bar.openTray === "power"
            bar: bar
        }
    }
}
