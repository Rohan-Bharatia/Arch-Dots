import QtQuick
import Quickshell
import Quickshell.Wayland
import "./../../config"

PanelWindow {
    id: borderBar

    required property ShellScreen targetScreen
    screen: targetScreen

    required property string direction

    anchors.left:   direction !==  "right"
    anchors.right:  direction !==   "left"
    anchors.top:    direction !== "bottom"
    anchors.bottom: direction !==    "top"

    implicitWidth:  (direction === "left" || direction === "right")  ? 10 : 0
    implicitHeight: (direction === "top"  || direction === "bottom") ? 10 : 0

    color: QuickshellColors.surface_container_highest

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None;
    WlrLayershell.namespace: "JARVIS"
    WlrLayershell.layer: WlrLayer.Overlay
}
