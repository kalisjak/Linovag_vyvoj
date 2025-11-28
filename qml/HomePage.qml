import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    title: "Homepage"
    background: Item {}
    visible: SwipeView.isCurrentItem

    // obsah „plave“, pozadí řeší App.qml
    contentItem: Item {
        anchors.fill: parent

                Row {
            anchors.centerIn: parent
            spacing: 48

            // Tlačítko "Teploty" – nová SetTempPage s teploměrem
            Rectangle {
                width: 160; height: 160; radius: 24
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            // teploměr – bootstrap icons "thermometer"
                            item.code = "\uF5CD"
                            item.px = 80
                            item.iconColor = "#EDEFF2"
                        }
                    }
                    Text { text: "Temperaturen"; color: "#EDEFF2"; font.bold: true }
                }
                MouseArea {
                    anchors.fill: parent; onClicked: dock.dotClicked(1) // SetTempPage (index 1)
                    hoverEnabled: true
                    onEntered: parent.color = "#00000077"
                    onExited:  parent.color = "#00000055"
                }
            }

            // Tlačítko „Historie“ – nová HistPage
            Rectangle {
                width: 160; height: 160; radius: 24
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            // hodiny s historií – bootstrap icons "clock-history"
                            // Unicode: U+F292
                            item.code = "\uF292"
                            item.px = 80
                            item.iconColor = "#EDEFF2"
                        }
                    }
                    Text { text: "Geschichte"; color: "#EDEFF2"; font.bold: true }
                }
                MouseArea {
                    anchors.fill: parent; onClicked: dock.dotClicked(2) // HistPage – nově index 2
                    hoverEnabled: true
                    onEntered: parent.color = "#00000077"
                    onExited:  parent.color = "#00000055"
                }
            }


            // Tlačítko "QR stránka" (tohle už v souboru máš, jen zůstává jako je)
            Rectangle {
                width: 160; height: 160; radius: 24
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            item.code = "\uF6AE"
                            item.px = 80
                            item.iconColor = "#EDEFF2"
                        }
                    }
                    Text { text: "QR"; color: "#EDEFF2"; font.bold: true }
                }
                MouseArea {
                    anchors.fill: parent; onClicked: dock.dotClicked(3) // QrPage – nově index 3
                    hoverEnabled: true
                    onEntered: parent.color = "#00000077"
                    onExited:  parent.color = "#00000055"
                }
            }
        }

    }

}