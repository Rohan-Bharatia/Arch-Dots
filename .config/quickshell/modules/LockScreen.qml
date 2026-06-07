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

    property date now: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: lockScreen.active
        onTriggered: lockScreen.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("#0a0a12", 0.53)

        MouseArea {
            anchors.fill: parent
            onClicked: passInput.forceActiveFocus()
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(lockScreen.now, "HH:mm")
                font.pixelSize: 80
                font.weight: Font.Thin
                color: "#ffffff"
                opacity: 0.92
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(lockScreen.now, "dddd, d MMMM yyyy")
                font.pixelSize: 16
                color: "#ffffff"
                opacity: 0.55
            }

            Item {
                Layout.preferredHeight: 56
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 280
                height: 48
                radius: 24
                color: Qt.alpha("#ffffff", 0.08)
                border.width: 1
                border.color: Qt.alpha("#ffffff", passInput.activeFocus ? 0.5 : 0.18)

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
                        color: Qt.alpha("#ffffff", 0.5)
                    }

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 56
                        height: passInput.implicitHeight

                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            font.pixelSize: 15
                            color: "#ffffff"
                            echoMode: TextInput.Password
                            clip: true
                            focus: lockScreen.active
                            Keys.onReturnPressed: lockScreen.tryUnlock(text)
                            Keys.onEscapePressed: text = ""
                        }

                        Text {
                            anchors.fill: parent
                            text: "Enter password to unlock"
                            font: passInput.font
                            color: Qt.alpha("#ffffff", 0.35)
                            verticalAlignment: Text.AlignVCenter
                            visible: passInput.text.length === 0 && !passInput.activeFocus
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: passInput.forceActiveFocus()
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
                color: "#ff6b6b"
                opacity: text.length > 0 ? 1 : 0
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
                width: 140
                height: 40
                radius: 20
                color: unlockHover.containsMouse
                    ? Qt.alpha("#ffffff", 0.18)
                    : Qt.alpha("#ffffff", 0.10)
                border.width: 1
                border.color: Qt.alpha("#ffffff", 0.22)

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animDuration
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Unlock"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: "#ffffff"
                    opacity: 0.88
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
            passInput.forceActiveFocus()
        }
    }
}
