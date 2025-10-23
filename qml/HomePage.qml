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

            // Tlačítko "Domů/TempPage"
            Rectangle {
                width: 160; height: 160; radius: 24
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8
                    // dům
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            item.code = "\uF5CD"
                            item.px = 80
                            item.iconColor = "#EDEFF2"
                        }
                    }
                    Text { text: "Teploty"; color: "#EDEFF2"; font.bold: true }
                }
                MouseArea {
                    anchors.fill: parent; onClicked: dock.dotClicked(1) // TempPage
                    hoverEnabled: true; onEntered: parent.color = "#00000077"; onExited: parent.color = "#00000055"
                }
            }

            // Tlačítko "QR stránka"
            Rectangle {
                width: 160; height: 160; radius: 24
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8
                    // QR
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
                    anchors.fill: parent; onClicked: dock.dotClicked(2) // QrPage
                    hoverEnabled: true; onEntered: parent.color = "#00000077"; onExited: parent.color = "#00000055"
                }
            }
        }
    }

}