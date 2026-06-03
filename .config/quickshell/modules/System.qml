import QtQuick
import Quickshell.Io

import "../config"
import "../tools"

Section {
    id: system

    property int cpuUsage: 0
    property int ramUsage: 0
    property var prevCpuActive: 0
    property var prevCpuTotal: 1

    function cpuColor(pct) {
        if (pct >= 80)
            return QuickshellColors.error
        if (pct >= 50)
            return QuickshellColors.tertiary
        return QuickshellColors.secondary
    }

    function ramColor(pct) {
        if (pct >= 85)
            return QuickshellColors.error
        if (pct >= 60)
            return QuickshellColors.tertiary
        return QuickshellColors.secondary
    }

    Process {
        id: cpuProc
        command: ["bash", "-c", "grep '^cpu ' /proc/stat | awk '{print $2, $3, $4, $5, $6, $7, $8, $9}'"]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                var p = line.trim().split(" ")
                if (p.length < 8)
                    return

                var user = parseInt(p[0])
                var nice = parseInt(p[1])
                var system = parseInt(p[2])
                var idle = parseInt(p[3])
                var iowait  = parseInt(p[4])
                var irq = parseInt(p[5])
                var softirq = parseInt(p[6])
                var steal = parseInt(p[7]) || 0
                var active = user + nice + system + irq + softirq + steal
                var total = active + idle + iowait

                var da = active - system.prevCpuActive
                var dt = total - system.prevCpuTotal
                if (dt > 0)
                    system.cpuUsage = Math.max(0, Math.min(100, Math.round(da / dt * 100)))

                system.prevCpuActive = active
                system.prevCpuTotal = total
            }
        }

        onExited: running = false
    }
    Process {
        id: ramProc
        command: ["bash", "-c", "awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf \"%.0f\",100-(a/t*100)}' /proc/meminfo"]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                var v = parseInt(line.trim())
                if (!isNaN(v))
                    system.ramUsage = Math.max(0, Math.min(100, v))
            }
        }

        onExited: running = false
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            cpuProc.running = true
            ramProc.running = true
        }
    }

    StatCard {
        icon: "󰍛"
        usage: system.cpuUsage
        accentColor: system.cpuColor(system.cpuUsage)
    }

    StatCard {
        icon: "󰾆"
        usage: system.ramUsage
        accentColor: system.ramColor(system.ramUsage)
    }
}
