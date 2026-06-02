import QtQuick

import "../config"

Rectangle {
    color: QuickshellColors.surface_container
    radius: Constants.radius
    border.width: 1
    border.color: Qt.alpha(
        QuickshellColors.outline,
        0.35
    )
}
