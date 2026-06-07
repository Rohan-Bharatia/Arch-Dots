import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import "../config"
import "../tools"
import "../tools/tray"

Item {
    id: battery
    required property bool shown

    implicitHeight: batCol.implicitHeight + Constants.trayPad * 2

    opacity: shown ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animDuration
            easing.type: Easing.OutCubic
        }
    }

    property string powerProfile: "balanced"
    property int  batteryPct: 100
    property bool batteryCharging: false
    property string batteryIcon: {
        if (batteryCharging)
            return "󰂄"
        if (batteryPct >= 90)
            return "󰁹"
        if (batteryPct >= 70)
            return "󰂀"
        if (batteryPct >= 50)
            return "󰁾"
        if (batteryPct >= 30)
            return "󰁼"
        if (batteryPct >= 15)
            return "󰁺"
        return "󰂃"
    }

    Process {
        id: batProc
        command: ["bash", "-c", "echo $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)" + ":$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                var p = line.trim().split(":")
                var pct = parseInt(p[0])
                if (!isNaN(pct))
                    battery.batteryPct = pct
                if (p.length > 1)
                    battery.batteryCharging = p[1].trim() === "Charging"
            }
        }

        onExited: running = false
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: batProc.running = true
    }

    Process {
        id: profileRead
        command: ["bash", "-c", "powerprofilesctl get 2>/dev/null || echo balanced"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => battery.powerProfile = line.trim()
        }

        onExited: running = false
    }

    Process {
        id: profileWrite

        onExited: {
            running = false
            profileRead.running = true
        }
    }

    function setProfile(p) {
        profileWrite.command = ["bash", "-c", "powerprofilesctl set " + p + " 2>/dev/null"]
        profileWrite.running = true
        powerProfile = p
    }

    Timer {
        interval: 10000
        repeat: true
        running: battery.shown
        triggeredOnStart: true
        onTriggered: profileRead.running = true
    }

    property color batColor: {
        if (battery.batteryCharging)
            return QuickshellColors.secondary
        if (battery.batteryPct >= 50)
            return QuickshellColors.secondary
        if (battery.batteryPct >= 20)
            return QuickshellColors.tertiary
        return QuickshellColors.error
    }

    ColumnLayout {
        id: batCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Constants.trayPad
        spacing: Constants.spacing * 2

        TrayHeader {
            label: "BATTERY"
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: batDisplay.implicitHeight + 32
            color: Qt.alpha(QuickshellColors.surface_container, 0.7)
            radius: Constants.radius - 2
            border.width: 1
            border.color: Qt.alpha(QuickshellColors.outline, 0.18)

            Column {
                id: batDisplay
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: battery.batteryIcon
                    font.pixelSize: 44
                    color: battery.batColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animDurationSlow
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: battery.batteryPct + "%"
                    font.pixelSize: Constants.fontSizeXl
                    font.weight: Font.Bold
                    color: battery.batColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animDurationSlow
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: battery.batteryCharging ? "Charging" : "Discharging"
                    font.pixelSize: Constants.fontSizeSm
                    color: QuickshellColors.on_surface_variant
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 120
                    height: 6
                    radius: 3
                    color: Qt.alpha(QuickshellColors.surface_variant, 0.6)

                    Rectangle {
                        width: Math.max(6, parent.width * battery.batteryPct / 100)
                        height: parent.height
                        radius: parent.radius
                        color: battery.batColor

                        Behavior on width {
                            NumberAnimation {
                                duration: Constants.animDurationSlow
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Constants.animDurationSlow
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: profCol.implicitHeight + 24
            color: Qt.alpha(QuickshellColors.surface_container, 0.7)
            radius: Constants.radius - 2
            border.width: 1
            border.color: Qt.alpha(QuickshellColors.outline, 0.18)

            Column {
                id: profCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                Text {
                    text: "Power Profile"
                    font.pixelSize: Constants.fontSizeXs
                    font.letterSpacing: 0.6
                    color: QuickshellColors.on_surface_variant
                }

                Row {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "performance", icon: "⚡", label: "Performance" },
                            { id: "balanced", icon: "⚖", label: "Balanced" },
                            { id: "power-saver", icon: "󱈑", label: "Saver" },
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            property bool isCurrent: battery.powerProfile === modelData.id

                            width: (parent.width - 12) / 3
                            height: 44
                            radius: Constants.radius - 4
                            color: isCurrent
                                ? Qt.alpha(QuickshellColors.primary_container, 0.9)
                                : Qt.alpha(QuickshellColors.surface_variant, 0.4)
                            border.width: isCurrent ? 1 : 0
                            border.color: Qt.alpha(QuickshellColors.primary, 0.5)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Constants.animDuration
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: parent.parent.modelData.icon
                                    font.pixelSize: 14
                                    color: parent.parent.isCurrent
                                        ? QuickshellColors.primary
                                        : QuickshellColors.on_surface_variant

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Constants.animDuration
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: parent.parent.modelData.label
                                    font.pixelSize: 8
                                    color: parent.parent.isCurrent
                                        ? QuickshellColors.primary
                                        : QuickshellColors.on_surface_variant

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Constants.animDuration
                                            }
                                        }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: battery.setProfile(parent.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
