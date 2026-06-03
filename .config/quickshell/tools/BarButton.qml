import QtQuick

import "../config"

Rectangle {
    id: root

    required property string icon
    property bool active: false
    property bool hovered: false

    width: 42
    height: 42
    radius: Constants.radius
    color: active
        ? QuickshellColors.primary_container
        : hovered
            ? Qt.alpha(QuickshellColors.surface_container_high, 0.85)
            : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Constants.animDuration
        }
    }

    property bool pressed: false
    scale: pressed ? 0.88 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: Constants.iconSize
        color: root.active
            ? QuickshellColors.primary
            : root.hovered
                ? QuickshellColors.on_surface
                : QuickshellColors.on_surface_variant

        Behavior on color {
            ColorAnimation {
                duration: Constants.animDuration
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered = true
        onExited: {
            root.hovered = false
            root.pressed = false
        }
        onPressed: root.pressed = true
        onReleased: root.pressed = false
    }
}
