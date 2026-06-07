import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import "../config"
import "../tools"
import "../tools/tray"

Item {
    id: power
    required property bool shown
    required property var bar

    implicitHeight: powerCol.implicitHeight + Constants.trayPad * 2

    opacity: shown
        ? 1
        : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animDuration
            easing.type: Easing.OutCubic
        }
    }

    property string pendingAction: ""

    Process {
        id: logoutProc
        command: ["bash", "-c", Settings.logoutCmd]
        onExited: running = false
    }

    Process {
        id: rebootProc
        command: ["bash", "-c", Settings.rebootCmd]
        onExited: running = false
    }

    Process {
        id: shutdownProc
        command: ["bash", "-c", Settings.shutdownCmd]
        onExited: running = false
    }

    ColumnLayout {
        id: powerCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Constants.trayPad
        spacing: Constants.spacing

        TrayHeader {
            label: "POWER"
        }

        Item {
            Layout.preferredHeight: 4
        }

        Repeater {
            model: [
                { icon: "󰍁", label: "Lock Screen", color: QuickshellColors.on_surface, action: "lock" },
                { icon: "󰍃", label: "Log Out", color: QuickshellColors.tertiary, action: "logout"   },
                { icon: "󰜉", label: "Restart", color: QuickshellColors.secondary, action: "reboot" },
                { icon: "󰐥", label: "Shut Down", color: QuickshellColors.error, action: "shutdown" },
            ]

            delegate: PowerButton {
                required property var modelData
                Layout.fillWidth: true
                icon: modelData.icon
                label: modelData.label
                accent: modelData.color

                onActivated: {
                    if (modelData.action == "lock")
                        bar.showLockScreen = true
                    else {
                        power.pendingAction = modelData.action
                        confirmOverlay.visible = true
                    }
                }
            }
        }
    }

    Rectangle {
        id: confirmOverlay
        anchors.fill: parent
        visible: false
        color: Qt.alpha(QuickshellColors.surface, 0.92)
        radius: Constants.radius - 4

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Constants.trayPad * 2
            spacing: Constants.spacing * 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: power.pendingAction === "reboot"
                    ? "󰜉"
                    : power.pendingAction === "logout"
                        ? "󰍃"
                        : "󰐥"
                font.pixelSize: 36
                color: power.pendingAction === "reboot"
                    ? QuickshellColors.secondary
                    : power.pendingAction === "logout"
                        ? QuickshellColors.tertiary
                        : QuickshellColors.error
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: power.pendingAction === "reboot"
                    ? "Restart?"
                    : power.pendingAction === "logout"
                        ? "Log Out?"
                        : "Shut Down?"
                font.pixelSize: Constants.fontSizeMd
                font.weight: Font.Bold
                color: QuickshellColors.on_surface
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Are you sure?"
                font.pixelSize: Constants.fontSizeSm
                color: QuickshellColors.on_surface_variant
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.spacing

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Constants.radius - 4
                    color: Qt.alpha(QuickshellColors.surface_variant, 0.7)
                    border.width: 1
                    border.color: Qt.alpha(QuickshellColors.outline, 0.25)
                    property bool hov: false

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animDuration
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: Constants.fontSizeSm
                        font.weight: Font.Medium
                        color: QuickshellColors.on_surface
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: confirmOverlay.visible = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Constants.radius - 4
                    color: power.pendingAction === "reboot"
                        ? Qt.alpha(QuickshellColors.secondary_container, 0.9)
                        : power.pendingAction === "logout"
                            ? Qt.alpha(QuickshellColors.tertiary_container, 0.9)
                            : Qt.alpha(QuickshellColors.error_container, 0.9)
                    border.width: 1
                    border.color: power.pendingAction === "reboot"
                        ? Qt.alpha(QuickshellColors.secondary, 0.4)
                        : power.pendingAction === "logout"
                            ? Qt.alpha(QuickshellColors.tertiary, 0.4)
                            : Qt.alpha(QuickshellColors.error, 0.4)

                    Text {
                        anchors.centerIn: parent
                        text: power.pendingAction === "reboot"
                            ? "Restart"
                            : power.pendingAction === "logout"
                                ? "Log Out"
                                : "Shut Down"
                        font.pixelSize: Constants.fontSizeSm
                        font.weight: Font.Medium
                        color: power.pendingAction === "reboot"
                            ? QuickshellColors.on_secondary_container
                            : power.pendingAction === "logout"
                                ? QuickshellColors.on_tertiary_container
                                : QuickshellColors.on_error_container
                        }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            confirmOverlay.visible = false
                            if (power.pendingAction === "reboot")
                                rebootProc.running = true
                            else if (power.pendingAction === "logout")
                                logoutProc.running = true
                            else
                                shutdownProc.running = true
                        }
                    }
                }
            }
        }
    }
}
