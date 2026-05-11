import QtQuick
import Quickshell
import "./modules"

ShellRoot {
    id: root

    Background {
        targetScreen: root.screen
    }
    Frame {
        targetScreen: root.screen
        direction: "left"
    }
}
