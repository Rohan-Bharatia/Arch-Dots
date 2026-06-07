import QtQuick

import "../config"

Rectangle {
    id: root

    required property string icon
    property bool active: false
    property bool hovered: false
    property int badge: 0

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

    Rectangle {
        visible: root.badge > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 3
        anchors.rightMargin: 3
        width: root.badge > 9
            ? 17
            : 14
        height: 14
        radius: Constants.radius
        color: QuickshellColors.error

        Text {
            anchors.centerIn: parent
            text: root.badge > 99
                ? "99"
                : String(root.badge)
            font.pixelSize: 7
            font.weight: Font.Bold
            color: QuickshellColors.on_error
        }
    }
}
