import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: homeP
    property real uiScale: 1.0

    title: "Homepage"
    background: Item {}
    visible: SwipeView.isCurrentItem

    // obsah „plave“, pozadí řeší App.qml
    contentItem: Item {
        anchors.fill: parent

        Row {
            anchors.centerIn: parent
            spacing: 48 * uiScale

            // Tlačítko "Teploty"
            Rectangle {
                width: 200 * uiScale; height: 200 * uiScale; radius: 24 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8 * uiScale
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            // bootstrap icons "thermometer"
                            item.code = "\uF5CD"
                            item.px = 140 * uiScale
                            item.iconColor = "#EDEFF2"
                        }
                    }
                    Text { 
                        text: "Temperaturen"
                        color: "#EDEFF2"
                        font.bold: true
                        font.pixelSize: 16 * uiScale
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width * 0.9
                    }
                }
                MouseArea {
                    anchors.fill: parent; onClicked: dock.dotClicked(1)
                    hoverEnabled: true
                    onEntered: parent.color = "#00000077"
                    onExited:  parent.color = "#00000055"
                }
            }

            // Tlačítko „Historie“
            Rectangle {
                width: 200 * uiScale; height: 200 * uiScale; radius: 24 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8 * uiScale
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            // bootstrap icons "journal-richtext"
                            item.code = "\uF292"
                            item.px = 140 * uiScale
                            item.iconColor = "#EDEFF2"
                        }
                    }
                    Text { 
                        text: "History"
                        color: "#EDEFF2"
                        font.bold: true
                        font.pixelSize: 16 * uiScale
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width * 0.9
                    }
                }
                MouseArea {
                    anchors.fill: parent; onClicked: dock.dotClicked(2)
                    hoverEnabled: true
                    onEntered: parent.color = "#00000077"
                    onExited:  parent.color = "#00000055"
                }
            }


            // Tlačítko "QR stránka"
            Rectangle {
                width: 200 * uiScale; height: 200 * uiScale; radius: 24 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8 * uiScale
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            item.code = "\uF6AE"
                            item.px = 140 * uiScale
                            item.iconColor = "#EDEFF2"
                        }
                    }
                    Text { 
                        text: "QR"
                        color: "#EDEFF2"
                        font.bold: true
                        font.pixelSize: 16 * uiScale
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width * 0.9
                    }
                }
                MouseArea {
                    anchors.fill: parent; onClicked: dock.dotClicked(3)
                    hoverEnabled: true
                    onEntered: parent.color = "#00000077"
                    onExited:  parent.color = "#00000055"
                }
            }
        }
        

    }

}