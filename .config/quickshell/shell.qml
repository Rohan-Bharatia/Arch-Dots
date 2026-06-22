import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "modules"
import "tools/lock"

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
