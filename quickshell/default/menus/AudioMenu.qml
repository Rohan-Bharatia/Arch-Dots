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
	text: "Audio"
	horizontalAlignment: Text.AlignHCenter
	anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
	color: "#fcdeaf"
        text: "Speaker Volume"
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
        text: "Microphone Volume"
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
