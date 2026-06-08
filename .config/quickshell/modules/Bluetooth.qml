import QtQuick
import QtQuick.Layouts
import Quickshell.Io

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
    property bool scanning: false
    property var devices: []
    property string statusMsg: ""
    property string connectingAddr: ""

    Process {
        id: btPowerRead
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -i 'powered:' | awk '{print $2}'"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                bluetooth.powered = line.trim().toLowerCase() === "yes"
            }
        }

        onExited: running = false
    }

    Process {
        id: btPowerWrite
        onExited: running = false
    }

    function setPower(on) {
        btPowerWrite.command = ["bash", "-c", "bluetoothctl power " + (on ? "on" : "off") + " 2>/dev/null"]
        btPowerWrite.running = true
        Qt.callLater(function() { btPowerRead.running = true })
    }

    Process {
        id: btScanProc
        command: ["bash", "-c", "bluetoothctl devices 2>/dev/null | head -20"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                var trimmed = line.trim()
                if (trimmed.length === 0)
                    return

                var parts = trimmed.split(" ")
                if (parts.length < 3)
                    return

                var addr = parts[1]
                var name = parts.slice(2).join(" ")
                var devs = bluetooth.devices
                for (var i = 0; i < devs.length; i++) {
                    if (devs[i].addr === addr)
                        return
                }

                devs.push({ addr: addr, name: name, connected: false })
                bluetooth.devices = devs.slice()
            }
        }

        onExited: running = false
    }

    Process {
        id: btConnectedProc
        command: ["bash", "-c", "bluetoothctl devices Connected 2>/dev/null"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                var trimmed = line.trim()
                if (trimmed.length === 0)
                    return

                var parts = trimmed.split(" ")
                if (parts.length < 2)
                    return

                var addr = parts[1]
                var devs = bluetooth.devices
                for (var i = 0; i < devs.length; i++) {
                    if (devs[i].addr === addr)
                        devs[i] = { addr: devs[i].addr, name: devs[i].name, connected: true }
                }

                bluetooth.devices = devs.slice()
            }
        }

        onExited: running = false
    }

    Process {
        id: btActionProc
        onExited: code => {
            running = false
            bluetooth.connectingAddr = ""

            if (code === 0)
                bluetooth.statusMsg = "Done"
            else
                bluetooth.statusMsg = "Failed"

            statusClearTimer.restart()
            btConnectedProc.running = true
        }
    }

    Timer {
        id: statusClearTimer
        interval: 3000
        onTriggered: bluetooth.statusMsg = ""
    }

    function scanDevices() {
        bluetooth.devices = []
        bluetooth.scanning = true
        btScanProc.running = true
        btConnectedProc.running = true
        scanTimer.restart()
    }

    Timer {
        id: scanTimer
        interval: 1500
        onTriggered: bluetooth.scanning = false
    }

    function connectDevice(addr) {
        bluetooth.connectingAddr = addr
        bluetooth.statusMsg = "Connecting…"
        btActionProc.command = ["bash", "-c", "bluetoothctl connect " + addr + " 2>/dev/null"]
        btActionProc.running = true
    }

    function disconnectDevice(addr) {
        bluetooth.connectingAddr = addr
        bluetooth.statusMsg = "Disconnecting…"
        btActionProc.command = ["bash", "-c", "bluetoothctl disconnect " + addr + " 2>/dev/null"]
        btActionProc.running = true
    }

    Timer {
        interval: 8000
        repeat: true
        running: bluetooth.shown
        triggeredOnStart: true

        onTriggered: {
            btPowerRead.running = true
            if (bluetooth.powered) {
                btScanProc.running = true
                btConnectedProc.running = true
            }
        }
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
                    text: bluetooth.powered ? "󰂯" : "󰂲"
                    font.pixelSize: Constants.iconSize
                    color: bluetooth.powered
                        ? QuickshellColors.primary
                        : QuickshellColors.on_surface_variant
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bluetooth.powered ? "Enabled" : "Disabled"
                    font.pixelSize: Constants.fontSizeSm
                    font.weight: Font.Medium
                    color: QuickshellColors.on_surface
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
                        x: bluetooth.powered ? parent.width - width - 4 : 4
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
                    text: bluetooth.scanning
                        ? "Scanning…"
                        : bluetooth.devices.length === 0
                            ? "No paired devices"
                            : bluetooth.devices.length + " device(s)"
                    font.pixelSize: Constants.fontSizeXs
                    color: QuickshellColors.on_surface_variant
                }

                Repeater {
                    model: bluetooth.devices

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 36
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
                                text: modelData.connected
                                    ? "󰂱"
                                    : "󰂯"
                                font.pixelSize: 13
                                color: modelData.connected
                                    ? QuickshellColors.on_secondary_container
                                    : QuickshellColors.on_surface_variant
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                font.pixelSize: Constants.fontSizeXs
                                font.weight: Font.Medium
                                color: modelData.connected
                                    ? QuickshellColors.on_secondary_container
                                    : QuickshellColors.on_surface
                                elide: Text.ElideRight
                                width: parent.width - 80
                            }

                            Item {
                                Layout.fillWidth: true
                                width: 1
                                height: 1
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: bluetooth.connectingAddr === modelData.addr
                                    ? "…"
                                    : modelData.connected
                                        ? "󰅁"
                                        : "󰅂"
                                font.pixelSize: 11
                                color: QuickshellColors.on_surface_variant

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: bluetooth.connectingAddr === ""

                                    onClicked: {
                                        if (modelData.connected)
                                            bluetooth.disconnectDevice(modelData.addr)
                                        else
                                            bluetooth.connectDevice(modelData.addr)
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: bluetooth.statusMsg
                    font.pixelSize: Constants.fontSizeXs
                    color: bluetooth.statusMsg === "Done"
                        ? QuickshellColors.secondary
                        : bluetooth.statusMsg === ""
                            ? "transparent"
                            : QuickshellColors.error
                    horizontalAlignment: Text.AlignHCenter
                    visible: bluetooth.statusMsg.length > 0
                }

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 8
                    color: Qt.alpha(QuickshellColors.surface_variant, 0.4)

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐  Refresh"
                        font.pixelSize: Constants.fontSizeXs
                        color: QuickshellColors.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bluetooth.scanDevices()
                    }
                }
            }
        }
    }
}
