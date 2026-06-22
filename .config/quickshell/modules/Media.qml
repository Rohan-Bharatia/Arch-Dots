import QtQuick
import QtQuick.Layouts
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
    property var nowPlayingNode: {
        for (var i = 0; i < streamNodes.length; i++) {
            var n = streamNodes[i]
            var title = n.properties?.["media.title"] ?? ""
            var name  = n.properties?.["media.name"]  ?? ""
            if (title.length > 0 || name.length > 0)
                return n
        }

        return null
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
            visible: media.nowPlayingNode !== null

            TrayLabel {
                text: "Now Playing"
            }

            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 8
                        color: Qt.alpha(QuickshellColors.primary_container, 0.7)

                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            font.pixelSize: 18
                            color: QuickshellColors.on_primary_container
                        }
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 44

                        Text {
                            width: parent.width
                            text: {
                                if (!media.nowPlayingNode)
                                    return ""
                                var t = media.nowPlayingNode.properties?.["media.title"] ?? ""
                                return t.length > 0 ? t : (media.nowPlayingNode.properties?.["media.name"] ?? "Unknown")
                            }
                            font.pixelSize: Constants.fontSizeSm
                            font.weight: Font.Medium
                            color: QuickshellColors.on_surface
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: media.nowPlayingNode?.properties?.["media.artist"] ?? ""
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.primary
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }

                        Text {
                            width: parent.width
                            text: media.nowPlayingNode?.properties?.["application.name"] ?? ""
                            font.pixelSize: Constants.fontSizeXs
                            color: QuickshellColors.on_surface_variant
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                    }
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
