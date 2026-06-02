import QtQuick

import "../config"

Rectangle {
    id: root

    required property string icon
    property bool active: false

    width: 42
    height: 42
    radius: Constants.radius
    color: active
        ? QuickshellColors.primary_container
        : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 180
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: Constants.iconSize
        color: active
            ? QuickshellColors.primary
            : QuickshellColors.on_surface
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            if (!root.active)
                root.color = Qt.alpha(
                    QuickshellColors.surface_container_high,
                    0.9
                )
        }

        onExited: {
            if (!root.active)
                root.color = "transparent"
        }
    }
}
