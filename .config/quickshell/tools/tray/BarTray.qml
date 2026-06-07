import QtQuick
import QtQuick.Layouts
import Quickshell

import ".."

BarButton {
    id: barTray

    required property string tray
    required property var bar

    active: bar.openTray === tray
    Layout.fillWidth: true

    function getIconCenterY() {
        return mapToGlobal(0, height / 2).y
    }

    onHoveredChanged: {
        if (hovered) {
            bar.openTrayIconCenterY = getIconCenterY()
            bar.openTrayIconHeight = height
            bar.openTray = tray
            bar.cancelClose()
        } else if (bar.openTray == tray) {
            bar.startClose()
        }
    }
}
