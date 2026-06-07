import QtQuick
import Quickshell

import "../../config"

Rectangle {
    id: powerBtn
    required property string icon
    required property string label
    required property color accent
    signal activated

    implicitHeight: 52
    radius: Constants.radius - 2
    color: powerBtn.hovered
        ? Qt.alpha(accent, 0.15)
        : Qt.alpha(QuickshellColors.surface_container, 0.7)
    border.width: 1
    border.color: powerBtn.hovered
        ? Qt.alpha(accent, 0.4)
        : Qt.alpha(QuickshellColors.outline, 0.18)

    property bool hovered: false

    Behavior on color {
        ColorAnimation {
            duration: Constants.animDuration
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: Constants.animDuration
        }
    }

    scale: mouseArea.pressed ? 0.96 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 80
            easing.type: Easing.OutCubic
        }
    }

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        spacing: 14

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: powerBtn.icon
            font.pixelSize: Constants.iconSize
            color: powerBtn.hovered
                ? powerBtn.accent
                : QuickshellColors.on_surface_variant

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animDuration
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: powerBtn.label
            font.pixelSize: Constants.fontSizeSm
            font.weight: Font.Medium
            color: powerBtn.hovered
                ? powerBtn.accent
                : QuickshellColors.on_surface

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animDuration
                    }
                }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: powerBtn.hovered = true
        onExited: powerBtn.hovered = false
        onClicked: powerBtn.activated()
    }
}
