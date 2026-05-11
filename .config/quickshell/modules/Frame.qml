import QtQuick
import Quickshell
import "./bar"

Item {
    id: frame

    required property ShellScreen targetScreen

    required property string direction

    property bool horizontal: direction === "top" || direction === "bottom"

    Repeater {
        model: horizontal ? ["left", "right", "top", "bottom"] : ["top", "bottom", "left", "right"]

        delegate: Loader {
            required property string modelData

            sourceComponent: modelData === frame.direction ? barComponent : borderComponent
        }
    }

    Component {
        id: barComponent

        Bar {
            targetScreen: frame.targetScreen
            direction: modelData
        }
    }

    Component {
        id: borderComponent

        Border {
            targetScreen: frame.targetScreen
            direction: modelData
        }
    }
}
