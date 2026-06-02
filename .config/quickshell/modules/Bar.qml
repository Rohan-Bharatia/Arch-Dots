import QtQuick
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

        color:
            Qt.alpha(
                QuickshellColors.surface,
                0.85
            )
        border.color:
            Qt.alpha(
                QuickshellColors.outline,
                0.25
            )

        Column {
            anchors.fill: parent
            anchors.margins: Constants.margins
            spacing: Constants.spacing

            Workspaces {}

            Item {
                width: 1
                height: Constants.spacing
            }

            Media {}

            Clock {}

            Item {
                anchors.verticalCenter: parent.verticalCenter
            }

            System {}

            Item {
                width: 1
                height: Constants.spacing
            }

            Power {}
        }
    }
}
