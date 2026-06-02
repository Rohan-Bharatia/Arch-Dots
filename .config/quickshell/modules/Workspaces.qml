import QtQuick

import "../config"
import "../tools"

Column {
    spacing: Constants.spacing

    Repeater {
        model: Mango.workspaces

        delegate: BarButton {
            icon: modelData
            active: Mango.currentWorkspace == modelData

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    Mango.switchWorkspace(
                        modelData
                    )
                }
            }
        }
    }
}
