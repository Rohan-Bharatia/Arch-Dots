import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../config"

PanelWindow {
    id: lockScreen

    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true

    property bool active: false
    visible: active

    signal unlocked

    color: "transparent"
    exclusiveZone: -1

    Component.onCompleted: {
        if (WlrLayershell != null) {
            WlrLayershell.layer = WlrLayer.Top
            WlrLayershell.namespace = "qs-lockscreen"
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
        }
    }

    function ordinalSuffix(d) {
        if (d >= 11 && d <= 13)
            return "th"

        switch (d % 10) {
            case 1:
                return "st"
            case 2:
                return "nd"
            case 3:
                return "rd"
            default:
                return "th"
        }
    }

    property date now: new Date()
    property bool showPass: false

    Timer {
        interval: 1000
        repeat: true
        running: lockScreen.active
        onTriggered: lockScreen.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(QuickshellColors.surface, 0.35)

        MouseArea {
            anchors.fill: parent
            onClicked: passInput.forceActiveFocus()
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(QuickshellColors.primary_active, 0.08)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(lockScreen.now, "HH:mm")
                font.pixelSize: 80
                font.weight: Font.Thin
                color: QuickshellColors.on_surface
                opacity: 0.92
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                textFormat: Text.RichText
                text: Qt.formatDateTime(lockScreen.now, "dddd, MMMM d") +
                    "<sup>" + lockScreen.ordinalSuffix(lockScreen.now.getDate()) + "</sup>, " +
                    Qt.formatDateTime(lockScreen.now, "yyyy")
                font.pixelSize: 16
                color: QuickshellColors.on_surface_variant
                opacity: 0.75
            }

            Item {
                Layout.preferredHeight: 56
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 300
                height: 50
                radius: Constants.radius
                color: Qt.alpha(QuickshellColors.surface_variant, 0.08)
                border.width: 1
                border.color: passInput.activeFocus
                    ? Qt.alpha(QuickshellColors.primary, 0.7)
                    : Qt.alpha(QuickshellColors.outline, 0.35)

                Behavior on border.color {
                    ColorAnimation {
                        duration: Constants.animDuration
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰌾"
                        font.pixelSize: 16
                        color: passInput.activeFocus
                            ? QuickshellColors.primary
                            : QuickshellColors.on_surface_variant

                        Behavior on color {
                            ColorAnimation {
                                duration: Constants.animDuration
                            }
                        }
                    }

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 72
                        height: passInput.implicitHeight

                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            font.pixelSize: 15
                            color: QuickshellColors.on_surface
                            echoMode: lockScreen.showPass
                                ? TextInput.Normal
                                : TextInput.Password
                            clip: true
                            focus: lockScreen.active
                            Keys.onReturnPressed: lockScreen.tryUnlock(text)
                            Keys.onEscapePressed: text = ""
                        }

                        Text {
                            anchors.fill: parent
                            text: "Enter password to unlock"
                            font: passInput.font
                            color: QuickshellColors.on_surface_variant
                            verticalAlignment: Text.AlignVCenter
                            visible: passInput.text.length === 0 && !passInput.activeFocus
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: lockScreen.showPass
                            ? "󰺸"
                            : "󰤨"
                        font.pixelSize: 14
                        color: QuickshellColors.on_surface_variant
                        opacity: passInput.text.length > 0
                            ? 1
                            : 0.35

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Constants.animDuration
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: lockScreen.showPass = !lockScreen.showPass
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: passInput.forceActiveFocus()
                    propagateComposedEvents: true
                }
            }

            Item {
                Layout.preferredHeight: 14
            }

            Text {
                id: feedbackText
                Layout.alignment: Qt.AlignHCenter
                text: ""
                font.pixelSize: 12
                color: QuickshellColors.error
                opacity: text.length > 0
                    ? 1
                    : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animDuration
                    }
                }
            }

            Item {
                Layout.preferredHeight: 28
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 160
                height: 44
                radius: 22
                color: unlockHover.containsMouse
                    ? Qt.alpha(QuickshellColors.primary, 0.22)
                    : Qt.alpha(QuickshellColors.primary_active, 0.55)
                border.width: 1
                border.color: Qt.alpha(QuickshellColors.primary, 0.22)

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animDuration
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Constants.spacing

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍁"
                        font.pixelSize: 14
                        color: QuickshellColors.on_primary_container
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Unlock"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: QuickshellColors.on_primary_container
                    }
                }

                MouseArea {
                    id: unlockHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: lockScreen.tryUnlock(passInput.text)
                }
            }
        }
    }

    Process {
        id: unlockCheck

        onExited: code => {
            running = false
            if (code === 0) {
                passInput.text = ""
                feedbackText.text = ""
                lockScreen.showPass = false
                lockScreen.unlocked()
            } else {
                feedbackText.text = "Incorrect password"
                passInput.text = ""
                shakeAnim.restart()
            }
        }
    }

    SequentialAnimation {
        id: shakeAnim

        NumberAnimation {
            target: passInput
            property: "x"
            to: -10
            duration: 45
        }

        NumberAnimation {
            target: passInput
            property: "x"
            to: 10
            duration: 45
        }

        NumberAnimation {
            target: passInput
            property: "x"
            to: -7
            duration: 40
        }

        NumberAnimation {
            target: passInput
            property: "x"
            to: 7
            duration: 40
        }

        NumberAnimation {
            target: passInput
            property: "x"
            to: 0
            duration: 40
        }
    }

    function tryUnlock(password) {
        if (password.length === 0) {
            feedbackText.text = "Please enter your password"
            return
        }

        unlockCheck.command = ["bash", "-c", "echo " + JSON.stringify(password) + " | su -c '' -s /bin/bash \"$USER\" 2>/dev/null && exit 0 || exit 1"]
        unlockCheck.running = true
    }

    onActiveChanged: {
        if (active) {
            passInput.text = ""
            feedbackText.text = ""
            passInput.showPass = false
            passInput.forceActiveFocus()
        }
    }
}
