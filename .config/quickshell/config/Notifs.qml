pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property int unreadCount: 0

    signal newNotification(var notif)

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: false
        imageSupported: true

        onNotification: notif => {
            root.unreadCount++
            root.newNotification(notif)
        }
    }

    readonly property var list: server.trackedNotifications.values.slice()

    function dismiss(notif) {
        notif.dismiss()
        if (root.unreadCount > 0)
            root.unreadCount--
    }

    function dismissAll() {
        for (var i = root.list.length - 1; i >= 0; i--)
            root.list[i].dismiss()
        root.unreadCount = 0
    }

    function clearUnread() {
        root.unreadCount = 0
    }
}
