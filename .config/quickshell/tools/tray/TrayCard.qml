import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../config"

Rectangle {
    color: Qt.alpha(QuickshellColors.surface_container, 0.7)
    radius: Constants.radius - 2
    border.width: 1
    border.color: Qt.alpha(QuickshellColors.outline, 0.18)
    Layout.fillWidth: true
    implicitHeight: cardCol.implicitHeight + 20
    default property alias content: cardCol.data

    Column {
        id: cardCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8
    }
}
