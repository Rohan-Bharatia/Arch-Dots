import QtQuick

import "../config"

MaterialCard {
    id: stat
    width: 42
    height: 54

    required property string icon
    required property int usage
    required property color accentColor

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: stat.icon
            font.pixelSize: Constants.iconSize
            color: stat.accentColor

            Behavior on color {
                ColorAnimation { duration: 500 }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 26
            height: 3
            radius: 2
            color: Qt.alpha(QuickshellColors.surface_variant, 0.5)

            Rectangle {
                width: Math.max(2, parent.width * (stat.usage / 100))
                height: parent.height
                radius: parent.radius
                color: stat.accentColor

                Behavior on width {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 500 }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: stat.usage + "%"
            font.pixelSize: Constants.fontSizeXs
            color: Qt.alpha(stat.accentColor, 0.85)

            Behavior on color {
                ColorAnimation { duration: 500 }
            }
        }
    }
}
