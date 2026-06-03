pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string logoutCmd: "loginctl terminate-session self"
    readonly property string rebootCmd: "systemctl reboot"
    readonly property string shutdownCmd: "systemctl poweroff"
    readonly property string lockCmd: "loginctl lock-session"

    readonly property int workspaceCount: 9
}
