import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "./../../config"

PanelWindow {
    id: bar

    required property ShellScreen targetScreen
    screen: targetScreen

    required property string direction

    property bool horizontal: direction === "top" || direction === "bottom"

    anchors.left:   direction !== "right"
    anchors.right:  direction !== "left"
    anchors.top:    direction !== "bottom"
    anchors.bottom: direction !== "top"

    implicitWidth:  !horizontal ? 50 : 0
    implicitHeight: horizontal  ? 50 : 0

    color: QuickshellColors.surface_container_highest

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "JARVIS"
    WlrLayershell.layer: WlrLayer.Overlay

    property var activeWs: Hyprland.activeWorkspace

    Item {
        anchors.fill: parent

        Rectangle {
            id: activeIndicator
            z: -1
            radius: 6
            color: "transparent"

            property Item targetItem: null

            x:      targetItem ? targetItem.x      : -100
            y:      targetItem ? targetItem.y      : -100
            width:  targetItem ? targetItem.width  : 0
            height: targetItem ? targetItem.height : 0

            Behavior on x      { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on y      { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Column {
            visible: direction === "left"
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Repeater {
                model: Hyprland.workspaces

                delegate: workspaceDelegate
            }
        }

        Column {
            visible: direction === "right"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Repeater {
                model: Hyprland.workspaces

                delegate: workspaceDelegate
            }
        }

        Row {
            visible: direction === "top"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: Hyprland.workspaces

                delegate: workspaceDelegate
            }
        }

        Row {
            visible: direction === "bottom"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: Hyprland.workspaces

                delegate: workspaceDelegate
            }
        }
    }

    Component {
        id: workspaceDelegate

        Rectangle {
            id: ws

            width: 30
            height: 30
            radius: 6

            property bool hovered: false
            property int wsId: modelData ? modelData.id : -1

            visible: modelData !== null

            property bool isActive: modelData ? modelData.active : false

            Component.onCompleted: {
                if (isActive) {
                    activeIndicator.targetItem = ws
                }
            }

            onIsActiveChanged: {
                if (isActive) {
                    activeIndicator.targetItem = ws
                }
            }

            color: isActive ? QuickshellColors.primary : hovered
                    ? QuickshellColors.surface_container_high
                    : QuickshellColors.surface_variant

            scale: isActive ? 1.12 : (hovered ? 1.05 : 1.0)

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: ws.wsId >= 0 ? ws.wsId : ""

                color: ws.isActive
                    ? QuickshellColors.on_primary
                    : QuickshellColors.on_surface
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: ws.hovered = true
                onExited: ws.hovered = false

                onClicked: {
                    if (ws.wsId >= 0)
                        Hyprland.dispatch(`workspace ${ws.wsId}`)
                }
            }
        }
    }
}
