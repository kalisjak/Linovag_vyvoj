import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: bar
    height: 48
    color: "#12121288"          // <<< poloprůhledná (AA–99–88 zkuste dle chuti)
    anchors.left: parent.left
    anchors.right: parent.right

    // dělící linka dole
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#c7c7c7bd"      // tenká jemná linka
    }

    signal openWifi()
    signal openSettings()
    signal openLogin()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Vlevo výrobní číslo (z backendu)
        Label {
            id: sn
            text: (typeof backend !== "undefined" && backend.serialNumber && backend.serialNumber.length > 0)
                  ? backend.serialNumber : "SN-000000"
            color: "#E0E0E0"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
        }

        // Uprostřed volitelné ikony (placeholdery)
        Row {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 12

            // Sem později přidáme např. Bootstrap/Fontello ikonky
            // Zatím placeholdery:
            ToolButton { text: "★";  onClicked: console.log("mid icon 1") }
            ToolButton { text: "☆";  onClicked: console.log("mid icon 2") }
        }

        // Vpravo Wi-Fi / Nastavení / Přihlášení
        Row {
            spacing: 10

            ToolButton {
                onClicked: bar.openWifi()
                contentItem: biIcon.createObject(this, { "code": "\uF61C", "px": 22, "iconColor": "#EDEFF2" })
                background: Rectangle { radius: 6; color: "#00000033"; implicitWidth: 36; implicitHeight: 32 }
            }
            ToolButton {
                onClicked: bar.openSettings()
                contentItem: biIcon.createObject(this, { "code": "\uF3E5", "px": 22, "iconColor": "#EDEFF2" })
                background: Rectangle { radius: 6; color: "#00000033"; implicitWidth: 36; implicitHeight: 32 }
            }
            ToolButton {
                onClicked: bar.openLogin()
                contentItem: biIcon.createObject(this, { "code": "\uF4E1", "px": 22, "iconColor": "#EDEFF2" })
                background: Rectangle { radius: 6; color: "#00000033"; implicitWidth: 36; implicitHeight: 32 }
            }
        }
    }
}
