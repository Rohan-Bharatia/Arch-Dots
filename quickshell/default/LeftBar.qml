import QtQuick
import Quickshell
import Quickshell.Hyprland
import "menus" as Menus;

PanelWindow {
  id: root
  anchors {
    top: true
    left: true
    bottom: true
  }

  color: "transparent"

  implicitWidth: 50
  implicitHeight: Screen.height
  
  focusable: false
  aboveWindows: true

  Column {
    id: bar
    anchors.fill: parent
    spacing: 5
    anchors.margins: 5

    Column {
      id: tray
      width: parent.width
      spacing: 5

      property var tray_items: [
        { icon: "⏻  ", name: "power" },
        { icon: "  ", name: "battery" },
	{ icon: "  ", name: "time" },
        { icon: "  ", name: "network" },
        { icon: "  ", name: "audio" }
      ]

      Repeater {
        model: tray.tray_items
        delegate: Item {
          width: parent.width
          height: 30

	  Menus.PowerMenu {
	    id: power_menu
	    anchor {
	      window: root
	      rect {
	        x: 60
		y: 5
	      }
            }
            implicitWidth: 100
	    implicitHeight: 160
	  }
	  Menus.BatteryMenu {
            id: battery_menu
            anchor {
              window: root
              rect {
                x: 60
                y: 40
              }
            }
            implicitWidth: 110
            implicitHeight: 110
          }
	  Menus.TimeMenu {
            id: time_menu
            anchor {
              window: root
              rect {
                x: 60
                y: 75
              }
            }
            implicitWidth: 70
            implicitHeight: 110
          }
          Menus.NetworkMenu {
            id: network_menu
            anchor {
              window: root
              rect {
                x: 60
                y: 110
              }
            }
            implicitWidth: 150
            implicitHeight: 135
          }
          Menus.AudioMenu {
            id: audio_menu
            anchor {
              window: root
              rect {
                x: 60
                y: 145
              }
            }
            implicitWidth: 150
            implicitHeight: 110
          }

          Rectangle {
            anchors.fill: parent
            color: "#221c24aa"
            border.color: "#fcdeaf"
            border.width: 2
            radius: 15
            anchors.margins: 2

            Text {
              id: tray_icon
              color: "#9ac6d2"
              anchors.centerIn: parent
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              text: modelData.icon
            }

            MouseArea {
              anchors.fill: parent
	      hoverEnabled: true
	      onClicked: {
		if (modelData.name === "power") power_menu.visible = !power_menu.visible
		if (modelData.name === "battery") battery_menu.visible = !battery_menu.visible
		if (modelData.name === "time") time_menu.visible = !time_menu.visible
		if (modelData.name === "network") network_menu.visible = !network_menu.visible
		if (modelData.name === "audio") audio_menu.visible = !audio_menu.visible
	      }
            }
          }
        }
      }
    }

    Item {
      id: spacer
      width: parent.width
      height: parent.height - (tray.height + workspaces.height + 10)
    }

    Item {
      id: workspaces
      width: parent.width
      height: workspace_bar.height

      Rectangle {
        anchors.fill: parent
        color: "#221c24aa"
        radius: 15

        Column {
          id: workspace_bar
          width: parent.width
          spacing: 5

          Repeater {
            model: Hyprland.workspaces
            delegate: Item {
              id: workspace
      	      width: parent.width
      	      height: 30

              Rectangle {
                anchors.fill: parent
      	        color: "#221c24aa"
      	        border.color: "#fcdeaf"
      	        border.width: modelData.active ? 4 : 2
      	        radius: 15
      	        anchors.margins: 2

      	        Text {
      	          id: workspace_id
      	          color: "#9ac6d2aa"
      	          anchors.centerIn: parent
      	          horizontalAlignment: Text.AlignHCenter
      	          verticalAlignment: Text.AlignVCenter
      	          text: modelData.id
      	        }

                MouseArea {
                  anchors.fill: parent
      	          onClicked: modelData.activate()
                }
              }
            }
          }
        }
      }
    }
  }
}
