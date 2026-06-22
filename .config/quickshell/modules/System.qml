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

    property real brightness: 0.5
    property var selectedAp: null
    property bool connecting: false
    property string connectStatus: ""
    property bool wifiExpanded: false

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

    Timer {
        id: statusClearTimer
        interval: 3000
        onTriggered: system.connectStatus = ""
    }

    Connections {
        target: Nmcli
        function onConnectFinished(success, message) {
            system.connecting = false
            system.connectStatus = message
            if (success)
                system.wifiExpanded = false
            statusClearTimer.restart()
        }
    }

    function scanNetworks() {
        Nmcli.scan()
    }

    function connectTo(ap, password) {
        if (!ap)
            return

        system.connecting = true
        system.connectStatus = "Connecting…"
        Nmcli.connectTo(ap.ssid, password)
    }

    Timer {
        interval: 5000
        repeat: true
        running: system.shown
        triggeredOnStart: true
        onTriggered: brightRead.running = true
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
                    text: Audio.muted
                        ? "󰝟"
                        : Audio.volume < 0.4
                            ? "󰕿"
                            : Audio.volume < 0.75
                                ? "󰖀"
                                : "󰕾"
                    font.pixelSize: Constants.iconSize
                    color: Audio.muted
                        ? QuickshellColors.on_surface_variant
                        : QuickshellColors.primary

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animDuration
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.toggleMute()
                    }
                }

                Slider {
                    width: parent.width - 34
                    value: Audio.volume
                    onMoved: v => Audio.setVolume(v)
                    opacity: Audio.muted
                        ? 0.4
                        : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Constants.animDuration
                        }
                    }
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
                        text: Nmcli.wifiEnabled
                            ? (Nmcli.activeSsid.length > 0
                                ? "󰤨"
                                : "󰤫")
                            : "󰤭"
                        font.pixelSize: Constants.iconSize
                        color: Nmcli.wifiEnabled && Nmcli.activeSsid.length > 0
                            ? QuickshellColors.secondary
                            : QuickshellColors.on_surface_variant

                        Behavior on color {
                            ColorAnimation {
                                duration: Constants.animDuration
                            }
                        }
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 68

                        Text {
                            text: !Nmcli.wifiHardwareEnabled
                                ? "Airplane Mode"
                                : !Nmcli.wifiEnabled
                                    ? "Wi-Fi Off"
                                    : (Nmcli.activeSsid.length > 0 ? Nmcli.activeSsid : "Not connected")
                            font.pixelSize: Constants.fontSizeSm
                            font.weight: Font.Medium
                            color: QuickshellColors.on_surface
                        }

                        Text {
                            text: "Networking"
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.on_surface_variant
                            visible: Nmcli.wifiHardwareEnabled && Nmcli.wifiEnabled
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
                        visible: Nmcli.wifiHardwareEnabled && Nmcli.wifiEnabled

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

                Row {
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        width: (parent.width - 6) / 2
                        height: 30
                        radius: 8
                        color: Nmcli.wifiEnabled
                            ? Qt.alpha(QuickshellColors.secondary_container, 0.85)
                            : Qt.alpha(QuickshellColors.surface_variant, 0.5)
                        border.width: 1
                        border.color: Nmcli.wifiEnabled
                            ? Qt.alpha(QuickshellColors.secondary, 0.4)
                            : Qt.alpha(QuickshellColors.outline, 0.25)

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰤨"
                                font.pixelSize: 11
                                color: Nmcli.wifiEnabled
                                    ? QuickshellColors.on_secondary_container
                                    : QuickshellColors.on_surface_variant
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Wi-Fi"
                                font.pixelSize: Constants.fontSizeXs
                                font.weight: Font.Medium
                                color: Nmcli.wifiEnabled
                                    ? QuickshellColors.on_secondary_container
                                    : QuickshellColors.on_surface_variant
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: Nmcli.wifiHardwareEnabled
                            onClicked: Nmcli.setWifiEnabled(!Nmcli.wifiEnabled)
                        }
                    }

                    Rectangle {
                        width: (parent.width - 6) / 2
                        height: 30
                        radius: 8
                        color: !Nmcli.wifiHardwareEnabled
                            ? Qt.alpha(QuickshellColors.error_container, 0.85)
                            : Qt.alpha(QuickshellColors.surface_variant, 0.5)
                        border.width: 1
                        border.color: !Nmcli.wifiHardwareEnabled
                            ? Qt.alpha(QuickshellColors.error, 0.4)
                            : Qt.alpha(QuickshellColors.outline, 0.25)

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰀝"
                                font.pixelSize: 11
                                color: !Nmcli.wifiHardwareEnabled
                                    ? QuickshellColors.on_error_container
                                    : QuickshellColors.on_surface_variant
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Airplane"
                                font.pixelSize: Constants.fontSizeXs
                                font.weight: Font.Medium
                                color: !Nmcli.wifiHardwareEnabled
                                    ? QuickshellColors.on_error_container
                                    : QuickshellColors.on_surface_variant
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Nmcli.setAirplaneMode(Nmcli.wifiHardwareEnabled)
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    visible: system.wifiExpanded && Nmcli.wifiHardwareEnabled && Nmcli.wifiEnabled
                    height: visible
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

                        Text {
                            width: parent.width
                            text: Nmcli.scanning
                                ? "Scanning…"
                                : Nmcli.accessPoints.length === 0
                                    ? "No networks found"
                                    : Nmcli.accessPoints.length + " network(s) found"
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.on_surface_variant
                        }

                        Repeater {
                            model: Nmcli.accessPoints

                            delegate: Rectangle {
                                required property var modelData
                                width: wifiDropContent.width
                                height: 34
                                radius: 8
                                color: system.selectedAp?.ssid === modelData.ssid
                                    ? Qt.alpha(QuickshellColors.secondary_container, 0.8)
                                    : modelData.ssid === Nmcli.activeSsid
                                        ? Qt.alpha(QuickshellColors.tertiary_container, 0.5)
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
                                        text: modelData.strength >= 75
                                            ? "󰤨"
                                            : modelData.strength >= 50
                                                ? "󰤥"
                                                : modelData.strength >= 25
                                                    ? "󰤢"
                                                    : "󰤟"
                                        font.pixelSize: 12
                                        color: system.selectedAp?.ssid === modelData.ssid
                                            ? QuickshellColors.on_secondary_container
                                            : QuickshellColors.on_surface_variant
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.ssid
                                        font.pixelSize: Constants.fontSizeXs
                                        font.weight: Font.Medium
                                        color: system.selectedAp?.ssid === modelData.ssid
                                            ? QuickshellColors.on_secondary_container
                                            : QuickshellColors.on_surface
                                        elide: Text.ElideRight
                                        width: parent.width - 40
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: system.selectedAp = modelData
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 6
                            visible: system.selectedAp !== null
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

                                            Keys.onReturnPressed: system.connectTo(system.selectedAp, text)
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
                                        : "Connect to " + (system.selectedAp?.ssid ?? "")
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
                                    onClicked: system.connectTo(system.selectedAp, passInput.text)
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
                                text: Nmcli.scanning ? "󰑐  Scanning…" : "󰑐  Refresh"
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
