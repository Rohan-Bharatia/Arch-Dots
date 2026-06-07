import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

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

    property MprisPlayer activePlayer: {
        for (var i = 0; i < Mpris.players.length; i++) {
            if (Mpris.players[i].playbackState === MprisPlaybackState.Playing)
                return Mpris.players[i]
        }

        return Mpris.players.length > 0 ? Mpris.players[0] : null
    }

    property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing

    property real trackProgress: {
        if (activePlayer === null || activePlayer.length <= 0)
            return 0

        return Math.max(0, Math.min(1, activePlayer.position / activePlayer.length))
    }

    function fmtTime(us) {
        var s = Math.floor(us / 1000000)
        var m = Math.floor(s / 60)
        s = s % 60
        return m + ":" + (s < 10 ? "0" : "") + s
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

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            implicitHeight: width
            radius: Constants.radius
            color: Qt.alpha(QuickshellColors.primary_container, 0.7)
            clip: true
            border.width: 1
            border.color: Qt.alpha(QuickshellColors.outline, 0.20)

            Image {
                anchors.fill: parent
                source: media.activePlayer !== null
                    ? (media.activePlayer.trackArtUrl ?? "")
                    : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: "♫"
                font.pixelSize: 52
                color: Qt.alpha(QuickshellColors.on_primary_container, 0.5)
                visible: media.activePlayer === null || (media.activePlayer.trackArtUrl ?? "").length === 0
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(QuickshellColors.surface, media.isPlaying ? 0 : 0.32)

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animDuration
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "⏸"
                    font.pixelSize: 32
                    color: QuickshellColors.on_surface
                    opacity: media.isPlaying ? 0 : 0.7

                    Behavior on opacity
                    {
                        NumberAnimation {
                            duration: Constants.animDuration
                       }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (media.activePlayer !== null)
                        media.activePlayer.togglePlaying()
                }
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: 3

            Text {
                width: parent.width
                text: media.activePlayer !== null
                    ? (media.activePlayer.trackTitle || "Unknown Track")
                    : "No media playing"
                font.pixelSize: Constants.fontSizeMd
                font.weight: Font.Bold
                color: QuickshellColors.on_surface
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Text {
                width: parent.width
                text: media.activePlayer !== null
                    ? (media.activePlayer.trackArtist || "")
                    : ""
                font.pixelSize: Constants.fontSizeSm
                color: QuickshellColors.primary
                elide: Text.ElideRight
                visible: text.length > 0
            }

            Text {
                width: parent.width
                text: media.activePlayer !== null
                    ? (media.activePlayer.trackAlbum || "")
                    : ""
                font.pixelSize: Constants.fontSizeXs
                color: QuickshellColors.on_surface_variant
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: 4
            visible: media.activePlayer !== null && (media.activePlayer.length ?? 0) > 0

            Rectangle {
                width: parent.width
                height: 3
                radius: 2
                color: Qt.alpha(QuickshellColors.surface_variant, 0.8)

                Rectangle {
                    width: Math.max(radius * 2, parent.width * media.trackProgress)
                    height: parent.height
                    radius: parent.radius
                    color: QuickshellColors.primary

                    Behavior on width {
                        NumberAnimation {
                            duration: Constants.animDurationSlow
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: posTime.implicitHeight

                Text {
                    id: posTime
                    anchors.left: parent.left
                    text: media.activePlayer !== null
                        ? media.fmtTime(media.activePlayer.position)
                        : "0:00"
                    font.pixelSize: Constants.fontSizeXs
                    color: QuickshellColors.on_surface_variant
                }

                Text {
                    anchors.right: parent.right
                    text: media.activePlayer !== null
                        ? media.fmtTime(media.activePlayer.length)
                        : "0:00"
                    font.pixelSize: Constants.fontSizeXs
                    color: QuickshellColors.on_surface_variant
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 28

            Repeater {
                model: 3

                delegate: Text {
                    required property int index

                    text: {
                        if (index === 0)
                            return "󰒮"
                        if (index === 1)
                            return media.isPlaying ? "󰏤" : "󰐊"
                        return "󰒭"
                    }
                    font.pixelSize: index === 1 ? 30 : 22

                    property bool btnEnabled: {
                        if (media.activePlayer === null)
                            return false
                        if (index === 0)
                            return media.activePlayer.canGoPrevious
                        if (index === 1)
                            return true
                        return media.activePlayer.canGoNext
                    }

                    color: btnEnabled
                        ? (index === 1
                            ? QuickshellColors.primary
                            : QuickshellColors.on_surface)
                        : Qt.alpha(QuickshellColors.on_surface_variant, 0.28)

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animDuration
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (!parent.btnEnabled || media.activePlayer === null)
                                return
                            switch (parent.index) {
                                case 0:
                                    media.activePlayer.previous()
                                    break
                                case 1:
                                    media.activePlayer.togglePlaying()
                                    break
                                case 2:
                                    media.activePlayer.next()
                                    break
                            }
                        }
                    }
                }
            }
        }
    }
}
