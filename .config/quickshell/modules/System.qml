import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import "../config"
import "../tools"
import "../tools/tray"

Item {
    id: system
    required property bool shown

    implicitHeight: systemCol.implicitHeight + Constants.trayPad * 2

    opacity: shown
        ? 1
        : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animDuration
            easing.type: Easing.OutCubic
        }
    }

    property real volume: 0.5
    property real brightness: 0.5
    property string ssid: "…"
    property string ipAddr: "…"
    property bool wifiExpanded: false
    property var networks: []
    property string selectedSsid: ""
    property bool connecting: false
    property string connectStatus: ""

    Process {
        id: volRead
        command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1"]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                var v = parseInt(line.trim())
                if (!isNaN(v))
                    system.volume = Math.max(0, Math.min(1, v / 100.0))
            }
        }

        onExited: running = false
    }

    Process {
        id: volWrite
        onExited: running = false
    }

    function setVolume(v) {
        volume = v
        volWrite.command = ["bash", "-c", "pactl set-sink-volume @DEFAULT_SINK@ " + Math.round(v * 100) + "%"]
        volWrite.running = true
    }

    Process {
        id: brightRead
        command: ["bash", "-c", "brightnessctl 2>/dev/null | grep -oP '\\d+(?=%)' | head -1 || echo 50"]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                var v = parseInt(line.trim())
                if (!isNaN(v))
                    system.brightness = Math.max(0, Math.min(1, v / 100.0))
            }
        }

        onExited: running = false
    }

    Process {
        id: brightWrite
        onExited: running = false
    }

    function setBrightness(v) {
        brightness = v
        brightWrite.command = ["bash", "-c", "brightnessctl set " + Math.round(v * 100) + "% 2>/dev/null"]
        brightWrite.running = true
    }

    Process {
        id: netProc
        command: ["bash", "-c", "echo \"$(iwgetid -r 2>/dev/null || nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 || echo 'No WiFi'):" + "$(hostname -I 2>/dev/null | awk '{print $1}')\""]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                var p = line.trim().split(":")
                system.ssid = p[0] || "Offline"
                system.ipAddr = p[1] || ""
            }
        }

        onExited: running = false
    }

    Process {
        id: scanProc
        command: ["bash", "-c", "nmcli -g SSID,SIGNAL dev wifi list 2>/dev/null | sort -t: -k2 -rn | head -15"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                var trimmed = line.trim()
                if (trimmed.length === 0)
                    return

                var lastColon = trimmed.lastIndexOf(":")
                if (lastColon < 0)
                    return

                var ssid = trimmed.slice(0, lastColon).replace(/\\:/g, ":")
                var signal = parseInt(trimmed.slice(lastColon + 1))
                if (ssid.length === 0)
                    return

                var nets = system.networks
                for (var i = 0; i < nets.length; i++) {
                    if (nets[i].ssid === ssid)
                        return
                }

                nets.push({ ssid: ssid, signal: isNaN(signal) ? 0 : signal })
                system.networks = nets.slice()
            }
        }

        onExited: running = false
    }
    Process {
        id: connectProc

        onExited: code => {
            running = false
            system.connecting = false
            if (code === 0) {
                system.connectStatus = "Connected!"
                system.wifiExpanded = false
                netProc.running = true
            } else
                system.connectStatus = "Failed — check password"

            statusClearTimer.restart()
        }
    }

    Timer {
        id: statusClearTimer
        interval: 3000
        onTriggered: system.connectStatus = ""
    }

    Timer {
        interval: 5000
        repeat: true
        running: system.shown
        triggeredOnStart: true

        onTriggered: {
            volRead.running = true
            brightRead.running = true
            netProc.running = true
        }
    }

        function scanNetworks() {
        system.networks = []
        scanProc.running = true
    }

    function connectTo(ssid, password) {
        system.connecting = true
        system.connectStatus = "Connecting…"
        var cmd = password.length > 0
            ? "nmcli dev wifi connect " + JSON.stringify(ssid) + " password " + JSON.stringify(password) + " 2>&1"
            : "nmcli dev wifi connect " + JSON.stringify(ssid) + " 2>&1"
        connectProc.command = ["bash", "-c", cmd]
        connectProc.running = true
    }

    ColumnLayout {
        id: systemCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Constants.trayPad
        spacing: Constants.spacing * 2

        TrayHeader {
            label: "SYSTEM"
        }

        TrayCard {
            TrayLabel {
                text: "Volume"
            }

            Row {
                spacing: 10
                width: parent.width

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: system.volume < 0.01
                        ? "󰝟"
                        : system.volume < 0.4
                            ? "󰕿"
                            : system.volume < 0.75
                                ? "󰖀"
                                : "󰕾"
                    font.pixelSize: Constants.iconSize
                    color: QuickshellColors.primary
                }

                Slider {
                    width: parent.width - 34
                    value: system.volume
                    onMoved: v => system.setVolume(v)
                }
            }
        }

        TrayCard {
            TrayLabel {
                text: "Brightness"
            }

            Row {
                spacing: 10
                width: parent.width

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: system.brightness < 0.3
                        ? "󰃞"
                        : system.brightness < 0.7
                            ? "󰃟"
                            : "󰃠"
                    font.pixelSize: Constants.iconSize
                    color: QuickshellColors.tertiary
                }

                Slider {
                    width: parent.width - 34
                    value: system.brightness
                    accentColor: QuickshellColors.tertiary
                    onMoved: v => system.setBrightness(v)
                }
            }
        }

        TrayCard {
            TrayLabel {
                text: "Network"
            }

            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰤨"
                        font.pixelSize: Constants.iconSize
                        color: QuickshellColors.secondary
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 34 - 24

                        Text {
                            text: system.ssid
                            font.pixelSize: Constants.fontSizeSm
                            font.weight: Font.Medium
                            color: QuickshellColors.on_surface
                        }

                        Text {
                            text: system.ipAddr
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.on_surface_variant
                            visible: system.ipAddr.length > 0
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        width: 1
                        height: 1
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: system.wifiExpanded
                            ? "󰅁"
                            : "󰅂"
                        font.pixelSize: 14
                        color: QuickshellColors.on_surface_variant

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                system.wifiExpanded = !system.wifiExpanded
                                if (system.wifiExpanded)
                                    system.scanNetworks()
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    visible: system.wifiExpanded
                    height: system.wifiExpanded
                        ? wifiDropContent.implicitHeight
                        : 0
                    color: "transparent"
                    clip: true

                    Behavior on height {
                        NumberAnimation {
                            duration: Constants.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Column {
                        id: wifiDropContent
                        width: parent.width
                        spacing: 4
                        visible: system.wifiExpanded

                        Text {
                            width: parent.width
                            text: system.networks.length === 0
                                ? "Scanning…"
                                : system.networks.length + " network(s) found"
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.on_surface_variant
                        }

                        Repeater {
                            model: system.networks

                            delegate: Rectangle {
                                required property var modelData
                                width: wifiDropContent.width
                                height: 34
                                radius: 8
                                color: system.selectedSsid === modelData.ssid
                                    ? Qt.alpha(QuickshellColors.secondary_container, 0.8)
                                    : Qt.alpha(QuickshellColors.surface_variant, 0.4)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.signal >= 75
                                            ? "󰤨"
                                            : modelData.signal >= 50
                                                ? "󰤥"
                                                : modelData.signal >= 25
                                                    ? "󰤢"
                                                    : "󰤟"
                                        font.pixelSize: 12
                                        color: system.selectedSsid === modelData.ssid
                                            ? QuickshellColors.on_secondary_container
                                            : QuickshellColors.on_surface_variant
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.ssid
                                        font.pixelSize: Constants.fontSizeXs
                                        font.weight: Font.Medium
                                        color: system.selectedSsid === modelData.ssid
                                            ? QuickshellColors.on_secondary_container
                                            : QuickshellColors.on_surface
                                        elide: Text.ElideRight
                                        width: parent.width - 40
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: system.selectedSsid = modelData.ssid
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 6
                            visible: system.selectedSsid.length > 0

                            property bool showPass: false

                            Rectangle {
                                width: parent.width
                                height: 34
                                radius: 8
                                color: Qt.alpha(QuickshellColors.surface_variant, 0.5)
                                border.width: 1
                                border.color: passInput.activeFocus
                                    ? Qt.alpha(QuickshellColors.primary, 0.5)
                                    : Qt.alpha(QuickshellColors.outline, 0.3)

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰌾"
                                        font.pixelSize: 12
                                        color: QuickshellColors.on_surface_variant
                                    }

                                    Item {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 56
                                        height: passInput.implicitHeight

                                        TextInput {
                                            id: passInput
                                            anchors.fill: parent
                                            font.pixelSize: Constants.fontSizeXs
                                            color: QuickshellColors.on_surface
                                            echoMode: parent.parent.parent.parent.showPass
                                                ? TextInput.Normal
                                                : TextInput.Password
                                            clip: true

                                            Text {
                                                anchors.fill: parent
                                                text: "Password"
                                                color: QuickshellColors.on_surface_variant
                                                font: parent.font
                                                verticalAlignment: Text.AlignVCenter
                                                visible: parent.text.length === 0 && !parent.activeFocus
                                            }

                                            Keys.onReturnPressed: system.connectTo(system.selectedSsid, text)
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: parent.parent.parent.showPass
                                            ? "󰤨"
                                            : "󰺸"
                                        font.pixelSize: 11
                                        color: QuickshellColors.on_surface_variant

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor

                                            onClicked: {
                                                var col = parent.parent.parent.parent
                                                col.showPass = !col.showPass
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 34
                                radius: 8
                                color: system.connecting
                                    ? Qt.alpha(QuickshellColors.surface_variant, 0.5)
                                    : Qt.alpha(QuickshellColors.secondary_container, 0.85)
                                border.width: 1
                                border.color: Qt.alpha(QuickshellColors.secondary, 0.3)

                                Text {
                                    anchors.centerIn: parent
                                    text: system.connecting
                                        ? "Connecting…"
                                        : "Connect to " + system.selectedSsid
                                    font.pixelSize: Constants.fontSizeXs
                                    font.weight: Font.Medium
                                    color: system.connecting
                                        ? QuickshellColors.on_surface_variant
                                        : QuickshellColors.on_secondary_container
                                    elide: Text.ElideRight
                                    width: parent.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: system.connecting ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !system.connecting
                                    onClicked: system.connectTo(system.selectedSsid, passInput.text)
                                }
                            }

                            Text {
                                width: parent.width
                                text: system.connectStatus
                                font.pixelSize: Constants.fontSizeXs
                                color: system.connectStatus.startsWith("Connected")
                                    ? QuickshellColors.secondary
                                    : QuickshellColors.error
                                horizontalAlignment: Text.AlignHCenter
                                visible: system.connectStatus.length > 0
                            }
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
                                onClicked: system.scanNetworks()
                            }
                        }
                    }
                }
            }
        }
    }
}
