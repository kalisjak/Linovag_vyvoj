import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "I18n.js" as I18n

    
Page {
    id: homeP
    property real uiScale: 1.0
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"
    signal serviceRequested()

    title: I18n.t(lang, "home.title")
    background: Item {}
    visible: SwipeView.isCurrentItem

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
                        text: I18n.t(homeP.lang, "home.temp")
                        color: "#EDEFF2"
                        font.bold: true
                        font.pixelSize: 20 * uiScale
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
                        text: I18n.t(homeP.lang, "home.history")
                        color: "#EDEFF2"
                        font.bold: true
                        font.pixelSize: 20 * uiScale
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
                        text: I18n.t(homeP.lang, "home.qr")
                        color: "#EDEFF2"
                        font.bold: true
                        font.pixelSize: 20 * uiScale
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
                        text: I18n.t(homeP.lang, "home.reclaim")
                        color: "#EDEFF2"
                        font.bold: true
                        font.pixelSize: 20 * uiScale
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

                        // bar.openWifi()
                        console.log("HomePage WiFi icon clicked")
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

            // Repair
            Rectangle {
                width: 110 * uiScale; height: 110 * uiScale; radius: 20 * uiScale
                color: "#00000055"; border.color: "#FFFFFF33"; border.width: 0

                Loader {
                    anchors.centerIn: parent
                    sourceComponent: biIcon
                    onLoaded: {
                        item.code = "\uF5DB"
                        item.px = 70 * uiScale
                        item.iconColor = "#EDEFF2"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        homeP.serviceRequested()
                        console.log("HomePage repair icon clicked")
                    }
                }
            }
        }


    }

}
