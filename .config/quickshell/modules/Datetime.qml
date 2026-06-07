import QtQuick
import QtQuick.Layouts

import "../config"
import "../tools"
import "../tools/tray"

Item {
    id: datetime
    required property bool shown

    implicitHeight: dtCol.implicitHeight + Constants.trayPad * 2

    opacity: shown ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animDuration
            easing.type: Easing.OutCubic
        }
    }

    property date now: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: datetime.now = new Date()
    }

    property int calYear: now.getFullYear()
    property int calMonth: now.getMonth()

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayHeaders: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    function ordinalSuffix(d) {
        if (d >= 11 && d <= 13)
            return "th"

        switch (d % 10) {
            case 1:
                return "st"
            case 2:
                return "nd"
            case 3:
                return "rd"
            default:
                return "th"
        }
    }

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }

    function firstDow(y, m) {
        return (new Date(y, m, 1).getDay() + 6) % 7
    }

    function buildCalendar() {
        var offset = firstDow(calYear, calMonth)
        var total = daysInMonth(calYear, calMonth)
        var today = now.getDate()
        var isThisMonth = calYear === now.getFullYear() && calMonth === now.getMonth()
        var cells = []

        for (var i = 0; i < 42; i++) {
            var d = i - offset + 1
            cells.push({
                day: (d >= 1 && d <= total)
                    ? d
                    : 0,
                isToday: isThisMonth && d === today
            })
        }

        while (cells.length >= 7 && cells[cells.length - 7].day === 0)
            cells.splice(cells.length - 7, 7)

        return cells
    }

    property var calCells: buildCalendar()
    onCalYearChanged: calCells = buildCalendar()
    onCalMonthChanged: calCells = buildCalendar()
    onNowChanged: calCells = buildCalendar()

    ColumnLayout {
        id: dtCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Constants.trayPad
        spacing: Constants.spacing * 2

        TrayHeader {
            label: "DATETIME"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(datetime.now, "HH:mm")
            font.pixelSize: Constants.fontSizeXl
            font.weight: Font.Bold
            color: QuickshellColors.primary
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            textFormat: Text.RichText
            text: Qt.formatDateTime(datetime.now, "dddd, MMMM d") +
                  "<sup>" + datetime.ordinalSuffix(datetime.now.getDate()) + "</sup>, " +
                  Qt.formatDateTime(datetime.now, "yyyy")
            font.pixelSize: Constants.fontSizeMd
            color: QuickshellColors.on_surface_variant
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: calInner.implicitHeight + 20
            color: Qt.alpha(QuickshellColors.surface_container, 0.7)
            radius: Constants.radius - 2
            border.width: 1
            border.color: Qt.alpha(QuickshellColors.outline, 0.18)

            Column {
                id: calInner
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                Item {
                    width: parent.width
                    height: 20

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅁"
                        font.pixelSize: 14
                        color: QuickshellColors.on_surface_variant

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (datetime.calMonth === 0) {
                                    datetime.calMonth = 11; datetime.calYear--
                                } else {
                                    datetime.calMonth--
                                }
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        text: datetime.monthNames[datetime.calMonth] + " " + datetime.calYear
                        font.pixelSize: Constants.fontSizeSm
                        font.weight: Font.Medium
                        color: QuickshellColors.on_surface
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅂"
                        font.pixelSize: 14
                        color: QuickshellColors.on_surface_variant

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (datetime.calMonth === 11) {
                                    datetime.calMonth = 0; datetime.calYear++
                                } else {
                                    datetime.calMonth++
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width

                    Repeater {
                        model: datetime.dayHeaders

                        delegate: Text {
                            required property var modelData
                            width: calInner.width / 7
                            text: modelData
                            font.pixelSize: Constants.fontSizeXs
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            color: QuickshellColors.on_surface_variant
                        }
                    }
                }

                Grid {
                    columns: 7
                    width: parent.width
                    columnSpacing: 0
                    rowSpacing: 2

                    Repeater {
                        model: datetime.calCells

                        delegate: Item {
                            required property var modelData
                            width: calInner.width / 7
                            height: width
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 4; height: width; radius: width / 2
                                color: modelData.isToday
                                    ? QuickshellColors.primary
                                    : "transparent"
                                visible: modelData.day > 0
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day > 0
                                    ? String(modelData.day)
                                    : ""
                                font.pixelSize: Constants.fontSizeXs
                                font.weight: modelData.isToday ? Font.Bold : Font.Normal
                                color: modelData.isToday ? QuickshellColors.on_primary : QuickshellColors.on_surface
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
