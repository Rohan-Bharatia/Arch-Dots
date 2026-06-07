import QtQuick
import QtQuick.Layouts

import "../../config"

Text {
    required property string label
    Layout.fillWidth: true
    text: label
    font.pixelSize: Constants.fontSizeXs
    font.letterSpacing: 1.2
    color: QuickshellColors.on_surface_variant
}
