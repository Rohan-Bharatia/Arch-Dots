import QtQuick
import Quickshell

import "../config"

Item {
    id: slider
    required property real value
    property color accentColor: QuickshellColors.primary

    signal moved(real v)

    height: 32

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 5
        radius: 3
        color: Qt.alpha(QuickshellColors.surface_variant, 0.8)

        Rectangle {
            width: Math.max(track.radius * 2, track.width * Math.max(0, Math.min(1, slider.value)))
            height: parent.height
            radius: parent.radius
            color: slider.accentColor

            Behavior on width {
                NumberAnimation {
                    duration: 40
                }
            }
        }
    }

    Rectangle {
        id: thumb
        anchors.verticalCenter: parent.verticalCenter
        x: (slider.width - width) * Math.max(0, Math.min(1, slider.value))
        width: 16
        height: 16
        radius: 8
        color: slider.accentColor
        scale: dragArea.pressed
            ? 1.25
            : 1

        Behavior on x {
            enabled: !dragArea.pressed

            NumberAnimation {
                duration: 40
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 40
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: -Constants.margins
        cursorShape: Qt.SizeHorCursor
        preventStealing: true

        function compute(mx) {
            return Math.max(0, Math.min(slider.width, mx)) / slider.width
        }

        onPressed: mouse => slider.moved(compute(mouse.x))
        onPositionChanged: mouse => { if (pressed) slider.moved(compute(mouse.x)) }
    }
}
