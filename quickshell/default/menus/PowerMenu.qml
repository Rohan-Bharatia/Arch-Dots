import QtQuick
import QtQuick.Controls
import Quickshell

PopupWindow {
  id: power_menu
  visible: false
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: "#221c24aa"
    border.color: "#fcdeaf"
    border.width: 2
    radius: 15
    anchors.margins: 2

    Column {
      spacing: 14
      anchors.centerIn: parent
      anchors.horizontalCenter: parent.horizontalCenter

      Text {
        color: "#fcdeaf"
	text: "Power"
	horizontalAlignment: Text.AlignHCenter
	anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
	color: "#fcdeaf"
        text: "Shutdown"
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
	Button {
	  onClicked: Quickshell.execDetached([""])
	  implicitWidth: parent.implicitWidth
	  implicitHeight: parent.implicitHeight
	  background: Rectangle {
	    anchors.fill: parent
	    border.color: "#fcdeaf"
            border.width: 2
            radius: 15
            anchors.margins: -5
	    color: "transparent"
	  }
	}
      }
      Text {
        color: "#fcdeaf"
        text: "Reboot"
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
        Button {
          onClicked: Quickshell.execDetached([""])
          implicitWidth: parent.implicitWidth
          implicitHeight: parent.implicitHeight
          background: Rectangle {
            anchors.fill: parent
            border.color: "#fcdeaf"
            border.width: 2
            radius: 15
            anchors.margins: -5
            color: "transparent"
          }
        }
      }
      Text {
        color: "#fcdeaf"
        text: "Suspend"
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
        Button {
          onClicked: Quickshell.execDetached([""])
          implicitWidth: parent.implicitWidth
          implicitHeight: parent.implicitHeight
          background: Rectangle {
            anchors.fill: parent
            border.color: "#fcdeaf"
            border.width: 2
            radius: 15
            anchors.margins: -5
            color: "transparent"
          }
        }
      }
      Text {
        color: "#fcdeaf"
        text: "Hibernate"
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
        Button {
          onClicked: Quickshell.execDetached([""])
          implicitWidth: parent.implicitWidth
          implicitHeight: parent.implicitHeight
          background: Rectangle {
            anchors.fill: parent
            border.color: "#fcdeaf"
            border.width: 2
            radius: 15
            anchors.margins: -5
            color: "transparent"
          }
        }
      }
    }
  }
}
