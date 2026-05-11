pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property string image: "{{image}}"

    <* for name, value in colors *>
    property string {{name}}: "#ff{{value.default.hex_stripped}}"
    <* endfor *>
}
