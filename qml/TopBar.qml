import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: bar
    property real uiScale: 1.0

    implicitHeight: 54 * uiScale
    height: implicitHeight

    color: "transparent"
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
        anchors.leftMargin: 15
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Vlevo výrobní číslo (z backendu)
        Label {
            id: sn
            text: (typeof backend !== "undefined" && backend.serialNumber && backend.serialNumber.length > 0)
                  ? backend.serialNumber : "SN-000000"
            color: "#E0E0E0"
            font.pixelSize: 20 * uiScale
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.fillWidth: true
        }

        // Uprostřed volitelné ikony (placeholdery)
        // Row {
        //     Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        //     Layout.fillWidth: true
        //     spacing: 8 * uiScale

        //     // Sem později přidáme např. Bootstrap/Fontello ikonky
        //     // Zatím placeholdery:
        //     ToolButton { text: "★";  onClicked: console.log("mid icon 1") }
        //     ToolButton { text: "☆";  onClicked: console.log("mid icon 2") }
        //     ToolButton { text: "☆";  onClicked: console.log("mid icon 2") }
        //     ToolButton { text: "☆";  onClicked: console.log("mid icon 2") }
        // }

        // Vpravo Wi-Fi / Nastavení / Přihlášení
        Row {
            spacing: 15 * uiScale
            // Layout.fillWidth: true

            ToolButton {
                onClicked: bar.openWifi()
                contentItem: biIcon.createObject(this, { "code": "\uF61C", "px": 34 * uiScale, "iconColor": "#EDEFF2" })
                background: Rectangle {
                    radius: 6 * uiScale
                    color: "#00000033"
                    implicitWidth: 40 * uiScale
                    implicitHeight: 36 * uiScale
                }
            }
            ToolButton {
                onClicked: bar.openSettings()
                contentItem: biIcon.createObject(this, { "code": "\uF3E5", "px": 34 * uiScale, "iconColor": "#EDEFF2" })
                background: Rectangle {
                    radius: 6 * uiScale
                    color: "#00000033"
                    implicitWidth: 40 * uiScale
                    implicitHeight: 36 * uiScale
                }
            }
            ToolButton {
                onClicked: bar.openLogin()
                contentItem: biIcon.createObject(this, { "code": "\uF4E1", "px": 34 * uiScale, "iconColor": "#EDEFF2" })
                background: Rectangle {
                    radius: 6 * uiScale
                    color: "#00000033"
                    implicitWidth: 40 * uiScale
                    implicitHeight: 36 * uiScale
                }
            }
            // Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
        }
    }
}
