import QtQuick

import "../config"
import "../tools"

MaterialCard {
    width: 42
    height: 80

    Text {
        anchors.centerIn: parent
        color: QuickshellColors.on_surface
        text: Qt.formatDateTime(
            new Date(),
            "hh\nmm"
        )
        horizontalAlignment: Text.AlignHCenter
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
    }
}
