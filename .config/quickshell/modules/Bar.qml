import QtQuick
import QtQuick.Layouts
import Quickshell

import "../tools"
import "../config"

PanelWindow {
    anchors.left: true
    anchors.top: true
    anchors.bottom: true
    implicitWidth: Constants.barWidth
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        anchors.margins: Constants.margins
        radius: Constants.radius

        color: Qt.alpha(QuickshellColors.surface, 0.88)
        border.color: Qt.alpha(QuickshellColors.outline, 0.22)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Constants.margins
            spacing: Constants.spacing

            Workspaces {}

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color:  Qt.alpha(QuickshellColors.outline_variant, 0.35)
            }

            Media {}

            Clock {}

            Item {
                Layout.fillHeight: true
            }

            System {}

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color:  Qt.alpha(QuickshellColors.outline_variant, 0.35)
            }

            Power {}

            Item {
                Layout.preferredHeight: 2
            }
        }
    }
}
