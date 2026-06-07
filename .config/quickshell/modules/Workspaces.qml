import QtQuick
import QtQuick.Layouts

import "../config"
import "../tools"

Section {
    Layout.alignment: Qt.AlignHCenter

    Repeater {
        model: Mango.workspaces

        delegate: BarButton {
            id: workspace

            required property var modelData

            icon: Mango.currentWorkspace == modelData
                ? ""
                : ""
            active: Mango.currentWorkspace == modelData

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: Mango.switchWorkspace(workspace.modelData)
                onEntered: workspace.hovered = true
                onExited: workspace.hovered = false
            }
        }
    }
}
