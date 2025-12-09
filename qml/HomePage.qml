import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

    
Page {
    id: homeP
    property real uiScale: 1.0

    title: "Homepage"
    background: Item {}
    visible: SwipeView.isCurrentItem

    // Component {
    //     id: historyDownloadIcon

    //     Item {
    //         id: root
    //         property real px: 120 * uiScale        // celková velikost ikony
    //         width: px
    //         height: px

    //         // Základ – ikona „history“
    //         Loader {
    //             anchors.centerIn: parent
    //             sourceComponent: biIcon
    //             onLoaded: {
    //                 // sem si dej svůj kód pro history
    //                 // třeba: item.code = "\uF2DA"
    //                 item.code = "\uF41F"
    //                 item.px = root.px
    //                 item.iconColor = "#EDEFF2"
    //             }
    //         }

    //         // Malá download šipka v rohu
    //         Loader {
    //             anchors.right: parent.right
    //             anchors.bottom: parent.bottom
    //             anchors.margins: 1
    //             sourceComponent: biIcon
    //             onLoaded: {
    //                 // sem dej kód pro download
    //                 // např. item.code = "\uF30A"
    //                 item.code = "\uF30A"
    //                 item.px = root.px * 0.45
    //                 item.iconColor = "#EDEFF2"
    //             }
    //         }
    //     }
    // }

    // obsah „plave“, pozadí řeší App.qml
    contentItem: Item {
        anchors.fill: parent

        Row {
            id: mainRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 140 * uiScale // odsazení od shora

            spacing: 80 * uiScale

            // Tlačítko "Teploty"
            Rectangle {
                width: 160 * uiScale; height: 160 * uiScale; radius: 15 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8 * uiScale
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            // bootstrap icons "thermometer"
                            item.code = "\uF5CD"
                            item.px = 120 * uiScale
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

            // Rectangle {
            //     width: 160 * uiScale
            //     height: 160 * uiScale
            //     radius: 15 * uiScale
            //     color: "transparent"

            //     Column {
            //         anchors.centerIn: parent; spacing: 8 * uiScale
            //         Loader {
            //             id: histDownloadLoader
            //             anchors.centerIn: parent
            //             sourceComponent: historyDownloadIcon
            //             onLoaded: {
            //                 item.px = 120 * uiScale   // tady nastavíš velikost
            //                 // item.iconColor = "#EDEFF2"
            //             }
            //         }

            //         Text { 
            //             text: "History"
            //             color: "#EDEFF2"
            //             font.bold: true
            //             font.pixelSize: 16 * uiScale
            //             horizontalAlignment: Text.AlignHCenter
            //             wrapMode: Text.WordWrap
            //             width: parent.width * 0.9
            //         }
            //     }

            //     MouseArea {
            //         anchors.fill: parent
            //         onClicked: dock.dotClicked(2)
            //         hoverEnabled: true
            //     }
            // }


            // Tlačítko „Historie“
            Rectangle {
                width: 160 * uiScale; height: 160 * uiScale; radius: 15 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8 * uiScale
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            // bootstrap icons "journal-richtext"
                            item.code = "\uF41F"
                            item.px = 120 * uiScale
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
                width: 160 * uiScale; height: 160 * uiScale; radius: 15 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8 * uiScale
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            item.code = "\uF6AE"
                            item.px = 120 * uiScale
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

            // Tlačítko "Reklamace"
            Rectangle {
                width: 160 * uiScale; height: 160 * uiScale; radius: 15 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Column {
                    anchors.centerIn: parent; spacing: 8 * uiScale
                    Loader {
                        sourceComponent: biIcon
                        onLoaded: {
                            item.code = "\uF84C"
                            item.px = 120 * uiScale
                            item.iconColor = "#EDEFF2"
                        }
                    }
                    Text { 
                        text: "Reklamační žádost"
                        color: "#EDEFF2"
                        font.bold: true
                        font.pixelSize: 16 * uiScale
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width * 0.9
                    }
                }
                MouseArea {
                    anchors.fill: parent; onClicked: dock.dotClicked(4)
                    hoverEnabled: true
                    onEntered: parent.color = "#00000077"
                    onExited:  parent.color = "#00000055"
                }
            }
        }
        
        Row {
            id: quickRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: mainRow.bottom
            anchors.topMargin: 60 * uiScale
            spacing: 32 * uiScale

            // Wi-Fi
            Rectangle {
                width: 110 * uiScale; height: 110 * uiScale; radius: 20 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Loader {
                    anchors.centerIn: parent
                    sourceComponent: biIcon
                    onLoaded: {
                        item.code = "\uF61C"      // wifi
                        item.px = 70 * uiScale
                        item.iconColor = "#EDEFF2"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // TODO: později volat něco jako bar.openWifi()
                        console.log("HomePage WiFi icon clicked")
                    }
                }
            }

            // Gear (nastavení)
            Rectangle {
                width: 110 * uiScale; height: 110 * uiScale; radius: 20 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Loader {
                    anchors.centerIn: parent
                    sourceComponent: biIcon
                    onLoaded: {
                        item.code = "\uF3E5"
                        item.px = 70 * uiScale
                        item.iconColor = "#EDEFF2"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // TODO: bar.openSettings()
                        console.log("HomePage settings icon clicked")
                    }
                }
            }

            // Person (uživatel / login)
            Rectangle {
                width: 110 * uiScale; height: 110 * uiScale; radius: 20 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Loader {
                    anchors.centerIn: parent
                    sourceComponent: biIcon
                    onLoaded: {
                        item.code = "\uF4E1"
                        item.px = 70 * uiScale
                        item.iconColor = "#EDEFF2"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // TODO: bar.openLogin()
                        console.log("HomePage person icon clicked")
                    }
                }
            }

            // Warning
            Rectangle {
                width: 110 * uiScale; height: 110 * uiScale; radius: 20 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Loader {
                    anchors.centerIn: parent
                    sourceComponent: biIcon
                    onLoaded: {
                        item.code = "\uF33B"
                        item.px = 70 * uiScale
                        item.iconColor = "#EDEFF2"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // TODO: později třeba otevřít stránku logů / alarmů
                        console.log("HomePage warning icon clicked")
                    }
                }
            }
        }


    }

}