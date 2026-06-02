pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property int currentWorkspace: 1
    property var workspaces: [1, 2, 3, 4, 5, 6, 7, 8, 9]
    property string focusedWindow: ""

    signal workspaceChanged(int id)

    function switchWorkspace(id) {
        // TODO: Hook into exposed MangoWM IPC layer for workspace changes
    }
}
