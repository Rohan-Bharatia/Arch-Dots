import QtQuick

import "../config"
import "../tools"

MaterialCard {
    id: clock
    width: 42
    height: 92

    property string hourStr: Qt.formatDateTime(new Date(), "hh")
    property string minStr: Qt.formatDateTime(new Date(), "mm")
    property string dayStr: Qt.formatDateTime(new Date(), "ddd")
    property string dateStr: Qt.formatDateTime(new Date(), "dd")

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            var now = new Date()
            clock.hourStr = Qt.formatDateTime(now, "hh")
            clock.minStr = Qt.formatDateTime(now, "mm")
            clock.dayStr = Qt.formatDateTime(now, "ddd")
            clock.dateStr = Qt.formatDateTime(now, "dd")
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.hourStr
            font.pixelSize: Constants.fontSizeLg
            font.weight: Font.Bold
            color: QuickshellColors.primary
            lineHeight: 1
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 22
            height: 1
            color: Qt.alpha(QuickshellColors.outline_variant, 0.6)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.minStr
            font.pixelSize: Constants.fontSizeLg
            font.weight: Font.Bold
            color: QuickshellColors.on_surface
            lineHeight: 1
        }

        Item {
            width: 1
            height: 2
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.dayStr.toUpperCase()
            font.pixelSize: Constants.fontSizeXs
            font.letterSpacing: 0.8
            color: QuickshellColors.on_surface_variant
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.dateStr
            font.pixelSize: Constants.fontSizeXs
            font.weight: Font.Medium
            color: QuickshellColors.on_surface_variant
        }
    }
}
