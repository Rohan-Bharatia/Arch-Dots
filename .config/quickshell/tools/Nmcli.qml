pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config"

Singleton {
    id: nmcli

    property bool wifiEnabled: false
    property bool wifiHardwareEnabled: true
    property string activeSsid: ""
    property var accessPoints: []
    property bool scanning: false
    property var rawAps: []

    Process {
        id: radioProc
        command: ["bash", "-c", "nmcli -t -f WIFI,WIFI-HW radio 2>/dev/null | head -1"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                var parts = line.trim().split(":")
                if (parts.length >= 2) {
                    nmcli.wifiEnabled = parts[0] === "enabled"
                    nmcli.wifiHardwareEnabled = parts[1] === "enabled"
                }
            }
        }

        onExited: running = false
    }

    Process {
        id: activeProc
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | sed 's/^yes://' | head -1"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                nmcli.activeSsid = line.trim().replace(/\\:/g, ":")
            }
        }

        onExited: running = false
    }
    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            radioProc.running = true
            activeProc.running = true
        }
    }

    Process {
        id: scanProc
        command: ["bash", "-c", "nmcli -t -f SSID,SIGNAL dev wifi list 2>/dev/null"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                line = line.trim()
                if (!line)
                    return

                var lastColon = line.lastIndexOf(":")
                if (lastColon < 0)
                    return

                var signalStr = line.substring(lastColon + 1)
                var ssidEscaped = line.substring(0, lastColon)
                var ssid = ssidEscaped.replace(/\\:/g, ":")
                var signal = parseInt(signalStr)
                if (!ssid || isNaN(signal))
                    return

                nmcli.rawAps.push({
                    ssid: ssid,
                    strength: signal
                })
            }
        }

        onExited: {
            var seen = {}
            var unique = []
            for (var i = 0; i < nmcli.rawAps.length; i++) {
                var ap = nmcli.rawAps[i]
                if (!seen[ap.ssid]) {
                    seen[ap.ssid] = true
                    unique.push(ap)
                }
            }

            unique.sort((a, b) => b.strength - a.strength)
            nmcli.accessPoints = unique
            nmcli.rawAps = []
            nmcli.scanning = false
            running = false
        }
    }

    function scan() {
        if (nmcli.scanning)
            return

        nmcli.rawAps = []
        nmcli.scanning = true
        scanProc.running = true
    }

    signal connectFinished(bool success, string message)

    Process {
        id: connectProc
        property bool succeeded: false
        property string errLine: ""

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                var l = line.trim()
                if (!l)
                    return
                if (l.toLowerCase().includes("successfully activated") || l.toLowerCase().includes("successfully connected"))
                    connectProc._succeeded = true
                else if (l.startsWith("Error:"))
                    connectProc.errLine = l.replace(/^Error:\s*/, "")
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                var l = line.trim()
                if (l.startsWith("Error:") && !connectProc.errLine)
                    connectProc.errLine = l.replace(/^Error:\s*/, "")
            }
        }

        onExited: (code) => {
            running = false
            var ok = code === 0 || connectProc.succeeded
            var msg = ok
                ? "Connected!"
                : connectProc.errLine.length > 0
                    ? connectProc.errLine
                    : "Failed — check password"
            connectProc.succeeded = false
            connectProc.errLine = ""
            activeProc.running = true
            nmcli.connectFinished(ok, msg)
        }
    }

    function connectTo(ssid, password) {
        connectProc.succeeded = false
        connectProc.errLine = ""
        if (password.length > 0)
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password]
        else
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid]
        connectProc.running = true
    }

    Process {
        id: wifiToggleProc

        onExited: {
            running = false
            radioProc.running = true
            activeProc.running = true
        }
    }

    function setWifiEnabled(on) {
        wifiToggleProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"]
        wifiToggleProc.running = true
    }

    Process {
        id: airplaneProc

        onExited: {
            running = false
            radioProc.running = true
        }
    }

    function setAirplaneMode(on) {
        airplaneProc.command = ["nmcli", "radio", "all", on ? "off" : "on"]
        airplaneProc.running = true
    }
}
