import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    id: setTP
    property real uiScale: 1.0

    title: "Nastavení teploty"
    background: Item {}
    visible: SwipeView.isCurrentItem

    // aktuální teplota = průměr ze dvou čidel
    readonly property double currentTemp: (backend.value1 + backend.value2) / 2.0
    readonly property double diff: Math.abs(currentTemp - backend.targetTemp)

    contentItem: Item {
        anchors.fill: parent
        anchors.margins: 32 * uiScale

        // levá část – velké číslo s aktuální teplotou
        Rectangle {
            id: leftPane
            
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * 0.66
            color: "transparent"

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    id: currentTempText
                    // text: Number(setTP.currentTemp).toLocaleString(Qt.locale(), "f", 1)
                    text: Number(setTP.currentTemp).toFixed(1)
                    color: setTP.diff > 2.5 ? "orange" : "#00ff00"
                    font.pixelSize: 290 * uiScale
                    font.bold: true
                }

                Text {
                    text: "°C"
                    color: "#c6c5df"        // nemění barvu, neutrální
                    font.pixelSize: 110 * uiScale     // polovina velikosti
                    font.bold: true
                }
            }
        }

        // svislá čára cca ve 2/3 šířky
        Rectangle {
            id: divider
            anchors.left: leftPane.right
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: parent.height * 0.7
            color: "#b9b9b9ff"
        }

        // pravá část – nastavení požadované teploty
        Rectangle {
            id: rightPane
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: divider.right
                right: parent.right
            }
            color: "transparent"

            Column {
                anchors.centerIn: parent
                spacing: 24 * uiScale

                // tlačítko +0.5 °C
                Rectangle {
                    id: upButton
                    width: 160 * uiScale
                    height: 130 * uiScale
                    radius: 24 * uiScale
                    color: upArea.pressed ? "#5a5a5ac4" : "#00000099"
                    border.color: "transparent"
                    border.width: 0

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: biIcon
                        onLoaded: {
                            // bootstrap-icons - chevron-up
                            item.code = "\uF286"
                            item.px = 130 * uiScale
                            item.iconColor = "#EDEFF2"
                        }
                    }

                    MouseArea {
                        id: upArea
                        anchors.fill: parent
                        onClicked: backend.targetTemp = backend.targetTemp + 0.5
                    }
                }

                // zvolená teplota (požadovaná)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4 * uiScale

                    Text {
                        id: targetTempText
                        text: Number(backend.targetTemp).toFixed(1)
                        color: "#EDEFF2"
                        font.pixelSize: 100 * uiScale
                        font.bold: true
                    }

                    Text {
                        text: "°C"
                        color: "#c6c5df"
                        font.pixelSize: 50  * uiScale
                        font.bold: true
                    }
                }

                // tlačítko -0.5 °C
                Rectangle {
                    id: downButton
                    width: 160 * uiScale
                    height: 130 * uiScale
                    radius: 24 * uiScale
                    color: downArea.pressed ? "#5a5a5ac4" : "#00000099"
                    border.color: "transparent"
                    border.width: 0

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: biIcon
                        onLoaded: {
                            // chevron-down (bootstrap-icons)
                            item.code = "\uF282"
                            item.px = 130 * uiScale
                            item.iconColor = "#EDEFF2"
                        }
                    }

                    MouseArea {
                        id: downArea
                        anchors.fill: parent
                        onClicked: backend.targetTemp = backend.targetTemp - 0.5
                    }
                }
            }
        }
    }
}
