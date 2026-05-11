pragma Singleton

import QtQuick
import Quickshell

Singleton {
    image = {{image}}
    <* for name, value in colors *>
    {{name}} = "ff{{value.default.hex_stripped}}"
    <* endfor *>
}
