import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: background

    required property ShellScreen targetScreen
    screen: targetScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "black"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None;
    WlrLayershell.namespace: "JARVIS"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore

    Image {
        anchors.fill: parent
        source: Quickshell.env("HOME") + "/.cache/current_wallpaper"

        fillMode: Image.PreserveAspectCrop

        smooth: true
        asynchronous: true

        visible: status == Image.Ready
    }
}
