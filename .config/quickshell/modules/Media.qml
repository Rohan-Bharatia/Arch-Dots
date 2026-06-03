import QtQuick
import Quickshell.Services.Mpris

import "../config"
import "../tools"

MaterialCard {
    id: media
    width: 42
    height: 110

    property MprisPlayer activePlayer: {
        for (var i = 0; i < Mpris.players.length; i++) {
            var player = Mpris.players[i]
            if (player.playbackState == MprisPlaybackState.Playing)
                return player
        }
        return Mpris.players.length > 0 ? Mpris.players[0] : null
    }

    property bool isPlaying: activePlayer !== null && activePlayer.playbackState == MprisPlaybackState.Playing

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        Item {
            width: 1
            height: 2
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: media.isPlaying ? "󰎇" : "♫"
            font.pixelSize: 22
            color: media.isPlaying
                ? QuickshellColors.secondary
                : QuickshellColors.on_surface_variant

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animDuration
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

        Text {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            text: media.activePlayer !== null
                ? (media.activePlayer.trackTitle || "")
                : ""
            font.pixelSize: Constants.fontSizeXs
            color: QuickshellColors.on_surface
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            lineHeight: 1.1
            visible: text.length > 0
        }

        Item {
            width: 1
            height: 2
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            Text {
                text: "󰒮"
                font.pixelSize: 13
                color: media.activePlayer !== null && media.activePlayer.canGoPrevious
                    ? QuickshellColors.on_surface_variant
                    : Qt.alpha(QuickshellColors.on_surface_variant, 0.3)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (media.activePlayer !== null)
                            media.activePlayer.previous()
                    }
                }
            }

            Item {
                width: 4
                height: 1
            }

            Text {
                text: media.isPlaying ? "󰏤" : "󰐊"
                font.pixelSize: 15
                color: media.activePlayer !== null
                    ? QuickshellColors.primary
                    : Qt.alpha(QuickshellColors.on_surface_variant, 0.3)

                Behavior on color {
                    ColorAnimation { duration: Constants.animDuration }
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

            Item {
                width: 4
                height: 1
            }

            Text {
                text: "󰒭"
                font.pixelSize: 13
                color: media.activePlayer !== null && media.activePlayer.canGoNext
                    ? QuickshellColors.on_surface_variant
                    : Qt.alpha(QuickshellColors.on_surface_variant, 0.3)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (media.activePlayer !== null)
                            media.activePlayer.next()
                    }
                }
            }
        }
    }
}
