import QtQuick
import Quickshell

import "modules"

ShellRoot {
    id: root

    Bar {
        id: bar
    }

    LockScreen {
        active: bar.showLockScreen
        onUnlocked: bar.showLockScreen = false
    }

    NotifPopup {}
}
