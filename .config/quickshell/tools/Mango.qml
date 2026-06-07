pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config"

Singleton {
    id: root

    property int currentWorkspace: 1
    property var workspaces: {
        var arr = []
        for (var i = 1; i <= Settings.workspaceCount; i++)
            arr.push(i)
        return arr
    }
    property string focusedWindow: ""

    signal workspaceChanged(int id)

    function switchWorkspace(id) {
        switchProc.command = ["mmsg", "dispatch", "view," + id]
        switchProc.running = true
    }

    function updateState(data) {
        const monitor = data.all_tags?.[0]
        if (!monitor)
            return

        const activeTag = monitor.tags.find(t => t.is_active)

        if (activeTag && activeTag.index !== currentWorkspace) {
            currentWorkspace = activeTag.index
            workspaceChanged(currentWorkspace)
        }
    }

    Process {
        id: switchProc
        onExited: running = false
    }

    Process {
        id: watchProc
        command: ["mmsg", "watch", "all-tags"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                try {
                    root.updateState(JSON.parse(line))
                } catch (e) {
                    console.log("mmsg parse error:", e)
                }
            }
        }

        onExited: restartTimer.start()
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: watchProc.running = true
    }

    Component.onCompleted: {
        initProc.running = true
    }

    Process {
        id: initProc
        command: ["mmsg", "get", "all-tags"]

        stdout: StdioCollector {
            onStreamFinished: output => {
                try {
                    root.updateState(JSON.parse(output))
                } catch (e) {
                    console.log("Initial mmsg parse error:", e)
                }
            }
        }

        onExited: running = false
    }
}
