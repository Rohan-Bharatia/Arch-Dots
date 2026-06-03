import QtQuick
import Quickshell.Io

import "../tools"
import "../config"

Section {
    BarButton {
        id: lock
        icon: "󰍁"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered: lock.hovered = true
            onExited: lock.hovered = false
            onClicked: lockProc.running = true
        }

        Process {
            id: lockProc
            command: Settings.lockCmd.split(" ")
            onExited: running = false
        }
    }

    BarButton {
        id: reboot
        icon: "󰜉"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered: reboot.hovered = true
            onExited: reboot.hovered = false
            onClicked: rebootProc.running = true
        }

        Process {
            id: rebootProc
            command: Settings.rebootCmd.split(" ")
            onExited: running = false
        }
    }

    BarButton {
        id: shutdown
        icon: "󰐥"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered: shutdown.hovered = true
            onExited: shutdown.hovered = false
            onClicked: shutdownProc.running = true
        }

        Process {
            id: shutdownProc
            command: Settings.shutdownCmd.split(" ")
            onExited: running = false
        }
    }
}
