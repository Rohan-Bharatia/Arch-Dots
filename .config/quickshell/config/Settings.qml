pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string logoutCmd: "loginctl terminate-session self"
    readonly property string rebootCmd: "systemctl reboot"
    readonly property string shutdownCmd: "systemctl poweroff"
    readonly property string lockCmd: "~/.local/share/scripts/show_lock_screen.sh"

    readonly property int workspaceCount: 9
}
