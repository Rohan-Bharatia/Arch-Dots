import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

import "../config"
import "../tools"
import "../tools/tray"

Item {
    id: bluetooth
    required property bool shown

    implicitHeight: btCol.implicitHeight + Constants.trayPad * 2

    opacity: shown
        ? 1
        : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animDuration
            easing.type: Easing.OutCubic
        }
    }

    property bool powered: false

    Process {
        id: powerPollProc
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -i 'Powered:' | awk '{print $2}'"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                bluetooth.powered = line.trim() === "yes"
            }
        }

        onExited: running = false
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: powerPollProc.running = true
    }

    Process {
        id: powerSetProc

        onExited: {
            running = false
            powerPollProc.running = true
        }
    }

    function setPower(on) {
        powerSetProc.command = ["bluetoothctl", "power", on ? "on" : "off"]
        powerSetProc.running = true
    }

    property bool scanning: false

    Process {
        id: scanProc
        command: ["bash", "-c", "bluetoothctl scan on & sleep 15; bluetoothctl scan off; wait"]

        onExited: {
            bluetooth.scanning = false
            running = false
        }
    }

    function startScan() {
        if (bluetooth.scanning)
            return

        bluetooth.scanning = true
        scanProc.running = true
    }

    ColumnLayout {
        id: btCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Constants.trayPad
        spacing: Constants.spacing * 2

        TrayHeader {
            label: "BLUETOOTH"
        }

        TrayCard {
            TrayLabel {
                text: "Power"
            }

            Row {
                width: parent.width
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bluetooth.powered
                        ? "󰂯"
                        : "󰂲"
                    font.pixelSize: Constants.iconSize
                    color: bluetooth.powered
                        ? QuickshellColors.primary
                        : QuickshellColors.on_surface_variant

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animDuration
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: bluetooth.powered
                            ? "Enabled"
                            : "Disabled"
                        font.pixelSize: Constants.fontSizeSm
                        font.weight: Font.Medium
                        color: QuickshellColors.on_surface
                    }

                    Text {
                        text: bluetooth.scanning
                            ? "Scanning…"
                            : Bluetooth.defaultAdapter?.name ?? ""
                        font.pixelSize: Constants.fontSizeXs
                        color: QuickshellColors.on_surface_variant
                        visible: bluetooth.powered
                    }
                }

                Item {
                    Layout.fillWidth: true
                    width: 1
                    height: 1
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 24
                    radius: 12
                    color: bluetooth.powered
                        ? Qt.alpha(QuickshellColors.primary, 0.85)
                        : Qt.alpha(QuickshellColors.surface_variant, 0.7)
                    border.width: 1
                    border.color: bluetooth.powered
                        ? Qt.alpha(QuickshellColors.primary, 0.4)
                        : Qt.alpha(QuickshellColors.outline, 0.3)

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Rectangle {
                        x: bluetooth.powered
                            ? parent.width - width - 4
                            : 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: bluetooth.powered
                            ? QuickshellColors.on_primary
                            : QuickshellColors.on_surface_variant

                        Behavior on x {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bluetooth.setPower(!bluetooth.powered)
                    }
                }
            }
        }

        TrayCard {
            visible: bluetooth.powered

            TrayLabel {
                text: "Devices"
            }

            Column {
                width: parent.width
                spacing: 4

                Text {
                    width: parent.width
                    text: Bluetooth.devices.length === 0
                        ? "No known devices"
                        : Bluetooth.devices.length + " device(s)"
                    font.pixelSize: Constants.fontSizeXs
                    color: QuickshellColors.on_surface_variant
                }

                Repeater {
                    model: Bluetooth.devices

                    delegate: Rectangle {
                        required property BluetoothDevice modelData

                        width: parent.width
                        height: 38
                        radius: 8
                        color: modelData.connected
                            ? Qt.alpha(QuickshellColors.secondary_container, 0.8)
                            : Qt.alpha(QuickshellColors.surface_variant, 0.4)

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.connected ? "󰂱" : "󰂯"
                                font.pixelSize: 14
                                color: modelData.connected
                                    ? QuickshellColors.on_secondary_container
                                    : QuickshellColors.on_surface_variant
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: parent.width - 60

                                Text {
                                    text: modelData.name
                                    font.pixelSize: Constants.fontSizeXs
                                    font.weight: Font.Medium
                                    color: modelData.connected
                                        ? QuickshellColors.on_secondary_container
                                        : QuickshellColors.on_surface
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    visible: modelData.batteryAvailable
                                    text: "Battery: " + (modelData.battery ?? 0) + "%"
                                    font.pixelSize: 7
                                    color: modelData.connected
                                        ? Qt.alpha(QuickshellColors.on_secondary_container, 0.7)
                                        : QuickshellColors.on_surface_variant
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                width: 1
                                height: 1
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.connected ? "󰅁" : "󰅂"
                                font.pixelSize: 12
                                color: modelData.connected
                                    ? QuickshellColors.on_secondary_container
                                    : QuickshellColors.on_surface_variant

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.connected = !modelData.connected
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 8
                    color: bluetooth.scanning
                        ? Qt.alpha(QuickshellColors.primary_container, 0.6)
                        : Qt.alpha(QuickshellColors.surface_variant, 0.4)

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: bluetooth.scanning
                            ? "󰑐  Scanning…"
                            : "󰑐  Scan"
                        font.pixelSize: Constants.fontSizeXs
                        color: bluetooth.scanning
                            ? QuickshellColors.on_primary_container
                            : QuickshellColors.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bluetooth.startScan()
                    }
                }
            }
        }
    }
}
