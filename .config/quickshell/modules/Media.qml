import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

import "../config"
import "../tools"
import "../tools/tray"

Item {
    id: media
    required property bool shown

    implicitHeight: mediaCol.implicitHeight + Constants.trayPad * 2

    opacity: shown
        ? 1
        : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animDuration
            easing.type: Easing.OutCubic
        }
    }

    PwObjectTracker {
        id: streamTracker
        objects: {
            var list = []
            if (Pipewire.defaultAudioSink)
                list.push(Pipewire.defaultAudioSink)

            var all = Pipewire.nodes.values ?? []
            for (var i = 0; i < all.length; i++) {
                if (all[i] && all[i].isStream && all[i].audio)
                    list.push(all[i])
            }

            return list
        }
    }
    property var streamNodes: {
        var result = []
        var all = Pipewire.nodes.values ?? []
        for (var i = 0; i < all.length; i++) {
            var n = all[i]
            if (n && n.isStream && n.audio)
                result.push(n)
        }

        return result
    }

    Repeater {
        id: mprisRepeater
        model: Mpris.players
        delegate: Item {
            required property var modelData
            property var player: modelData
        }
    }

    property var mprisPlayers: {
        var result = []
        for (var i = 0; i < mprisRepeater.count; i++)
            result.push(mprisRepeater.itemAt(i).player)
        return result
    }

    property var mprisActivePlayer: {
        var playing = null
        var first = null
        for (var i = 0; i < mprisPlayers.length; i++) {
            var p = mprisPlayers[i]
            if (!first)
                first = p
            if (p.isPlaying) {
                playing = p
                break
            }
        }
        return playing ?? first ?? null
    }

    property real currentPosition: 0
    property real totalLength: 0

    function formatTime(seconds) {
        if (!seconds || seconds < 0)
            return "0:00"

        var s = Math.floor(seconds)
        var m = Math.floor(s / 60)
        s = s % 60
        return m + ":" + (s < 10
            ? "0"
            : "") + s
    }

    Timer {
        id: positionTimer
        interval: 100
        repeat: true
        running: media.mprisActivePlayer !== null
                 && media.mprisActivePlayer.isPlaying
        onTriggered: {
            var p = media.mprisActivePlayer
            if (p) {
                media.currentPosition = p.position
                media.totalLength = p.length
            }
        }
    }

    ColumnLayout {
        id: mediaCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Constants.trayPad
        spacing: Constants.spacing * 2

        TrayHeader {
            label: "MEDIA"
        }

        TrayCard {
            visible: media.mprisActivePlayer !== null

            TrayLabel {
                text: "Now Playing"
            }

            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: 64
                        height: 64
                        radius: 12
                        color: Qt.alpha(QuickshellColors.primary_container, 0.5)
                        clip: true

                        Image {
                            id: artImage
                            anchors.fill: parent
                            source: media.mprisActivePlayer?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            font.pixelSize: 24
                            color: QuickshellColors.on_primary_container
                            visible: !artImage.visible
                        }
                    }

                    Column {
                        width: parent.width - 74
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: media.mprisActivePlayer?.trackTitle || "Unknown Title"
                            font.pixelSize: Constants.fontSizeSm
                            font.weight: Font.Medium
                            color: QuickshellColors.on_surface
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: media.mprisActivePlayer?.trackArtist || "Unknown Artist"
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.primary
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }

                        Text {
                            width: parent.width
                            text: media.mprisActivePlayer?.trackAlbum || ""
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.on_surface_variant
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }

                        Text {
                            width: parent.width
                            text: media.mprisActivePlayer?.identity ?? ""
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.outline
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Slider {
                        width: parent.width
                        value: media.totalLength > 0
                            ? media.currentPosition / media.totalLength
                            : 0
                        accentColor: QuickshellColors.primary
                        opacity: (media.mprisActivePlayer?.positionSupported ?? false) ? 1.0 : 0.35
                        onMoved: v => {
                            var p = media.mprisActivePlayer
                            if (p && p.canSeek && p.lengthSupported)
                                p.position = v * p.length
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Constants.animDuration
                            }
                        }
                    }

                    Row {
                        width: parent.width

                        Text {
                            id: timePos
                            text: media.formatTime(media.currentPosition)
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.on_surface_variant
                        }

                        Item {
                            width: parent.width - timePos.implicitWidth - timeLen.implicitWidth
                            height: 1
                        }

                        Text {
                            id: timeLen
                            text: "-" + media.formatTime(media.totalLength - media.currentPosition)
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.on_surface_variant
                        }
                    }
                }

                Row {
                    width: parent.width
                    layoutDirection: Qt.RightToLeft
                    spacing: 4
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: ["shuffle", "loop"]

                        Item {
                            width: 28
                            height: 28

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (modelData === "shuffle")
                                        return media.mprisActivePlayer?.shuffle
                                            ? "󰒟"
                                            : "󰒞"
                                    var ls = media.mprisActivePlayer?.loopState
                                    if (ls === undefined || ls === null)
                                        return "󰓦"
                                    if (ls === 2)
                                        return "󰓪"
                                    return "󰓦"
                                }
                                font.pixelSize: Constants.iconSize
                                color: {
                                    var supported = modelData === "shuffle"
                                        ? (media.mprisActivePlayer?.shuffleSupported ?? false)
                                        : (media.mprisActivePlayer?.loopSupported ?? false)
                                    if (!supported)
                                        return QuickshellColors.outline
                                    if (modelData === "shuffle")
                                        return (media.mprisActivePlayer?.shuffle ?? false)
                                            ? QuickshellColors.primary
                                            : QuickshellColors.on_surface_variant
                                    var ls = media.mprisActivePlayer?.loopState
                                    if (ls === undefined || ls === null)
                                        ls = 0
                                    return ls > 0
                                        ? QuickshellColors.primary
                                        : QuickshellColors.on_surface_variant
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var p = media.mprisActivePlayer
                                        if (!p)
                                            return
                                        if (modelData === "shuffle") {
                                            if (p.shuffleSupported)
                                                p.shuffle = !p.shuffle
                                        } else {
                                            if (p.loopSupported) {
                                                if (p.loopState === 0)
                                                    p.loopState = 1
                                                else if (p.loopState === 1)
                                                    p.loopState = 2
                                                else
                                                    p.loopState = 0
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: 1
                        height: 1
                        Layout.fillWidth: true
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰒮"
                            font.pixelSize: Constants.iconSize + 2
                            color: (media.mprisActivePlayer?.canGoPrevious ?? false)
                                ? QuickshellColors.on_surface
                                : QuickshellColors.outline

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: media.mprisActivePlayer?.canGoPrevious ?? false
                                    ? Qt.PointingHandCursor
                                    : Qt.ArrowCursor
                                onClicked: media.mprisActivePlayer?.previous()
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            height: 36
                            radius: 18
                            color: QuickshellColors.primary

                            Text {
                                anchors.centerIn: parent
                                text: (media.mprisActivePlayer?.isPlaying ?? false)
                                    ? "󰏤"
                                    : "󰐊"
                                font.pixelSize: Constants.iconSize + 4
                                color: QuickshellColors.on_primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: (media.mprisActivePlayer?.canTogglePlaying ?? false)
                                    ? Qt.PointingHandCursor
                                    : Qt.ArrowCursor
                                onClicked: media.mprisActivePlayer?.togglePlaying()
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Constants.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰒭"
                            font.pixelSize: Constants.iconSize + 2
                            color: (media.mprisActivePlayer?.canGoNext ?? false)
                                ? QuickshellColors.on_surface
                                : QuickshellColors.outline

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: media.mprisActivePlayer?.canGoNext ?? false
                                    ? Qt.PointingHandCursor
                                    : Qt.ArrowCursor
                                onClicked: media.mprisActivePlayer?.next()
                            }
                        }
                    }
                }
            }
        }

        TrayCard {
            TrayLabel {
                text: "Output"
            }

            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Audio.muted
                            ? "󰝟"
                            : Audio.volume < 0.35
                                ? "󰕿"
                                : Audio.volume < 0.7
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
                        width: parent.width - 32
                        value: Audio.volume
                        onMoved: v => Audio.setVolume(v)
                        opacity: Audio.muted ? 0.4 : 1.0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Constants.animDuration
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: Audio.sinkName.length > 0
                        ? "󰓃  " + Audio.sinkName
                        : "No output device"
                    font.pixelSize: Constants.fontSizeXs
                    color: QuickshellColors.on_surface_variant
                    elide: Text.ElideRight
                }
            }
        }

        TrayCard {
            TrayLabel {
                text: "Streams"
            }

            Column {
                width: parent.width
                spacing: 4

                Text {
                    width: parent.width
                    text: media.streamNodes.length === 0
                        ? "No active audio streams"
                        : media.streamNodes.length + " stream(s)"
                    font.pixelSize: Constants.fontSizeXs
                    color: QuickshellColors.on_surface_variant
                }

                Repeater {
                    model: media.streamNodes

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: streamRow.implicitHeight + 12
                        radius: 8
                        color: Qt.alpha(QuickshellColors.surface_variant, 0.35)

                        Column {
                            id: streamRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 4

                            Row {
                                width: parent.width
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰓃"
                                    font.pixelSize: 10
                                    color: QuickshellColors.on_surface_variant
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.properties?.["application.name"] ?? modelData.description ?? "Stream"
                                    font.pixelSize: Constants.fontSizeXs
                                    font.weight: Font.Medium
                                    color: QuickshellColors.on_surface
                                    elide: Text.ElideRight
                                    width: parent.width - 60

                                    MouseArea {
                                        anchors.fill: parent
                                    }
                                }

                                Item { width: 1; height: 1; Layout.fillWidth: true }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.audio?.muted ?? false
                                        ? "󰝟"
                                        : "󰕾"
                                    font.pixelSize: 10
                                    color: modelData.audio?.muted ?? false
                                        ? QuickshellColors.error
                                        : QuickshellColors.on_surface_variant

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.audio)
                                                modelData.audio.muted = !modelData.audio.muted
                                        }
                                    }
                                }
                            }

                            Slider {
                                width: parent.width
                                value: modelData.audio?.volume ?? 0
                                accentColor: QuickshellColors.secondary
                                opacity: modelData.audio?.muted ?? false ? 0.35 : 1.0
                                onMoved: v => {
                                    if (modelData.audio)
                                        modelData.audio.volume = v
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Constants.animDuration
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
