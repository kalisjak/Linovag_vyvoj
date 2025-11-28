import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    id: root
    title: "Nastavení teploty"
    background: Item {}
    visible: SwipeView.isCurrentItem

    // aktuální teplota = průměr ze dvou čidel
    readonly property double currentTemp: (backend.value1 + backend.value2) / 2.0
    readonly property double diff: Math.abs(currentTemp - backend.targetTemp)

    contentItem: Item {
        anchors.fill: parent
        anchors.margins: 32

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
                    text: Number(root.currentTemp).toLocaleString(Qt.locale(), "f", 1)
                    color: root.diff > 2.5 ? "orange" : "#00ff00"
                    font.pixelSize: 160
                    font.bold: true
                }

                Text {
                    text: "°C"
                    color: "#c6c5df"        // nemění barvu, neutrální
                    font.pixelSize: 60      // polovina velikosti
                    font.bold: true
                    // anchors.baseline: currentTempText.baseline
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
                spacing: 24

                // tlačítko +0.5 °C
                Rectangle {
                    id: upButton
                    width: 90
                    height: 90
                    radius: 24
                    color: upArea.pressed ? "#5a5a5ac4" : "#00000099"
                    border.color: "transparent"
                    border.width: 1

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: biIcon
                        onLoaded: {
                            // chevron-up (bootstrap-icons)
                            item.code = "\uF286"
                            item.px = 80
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
                    spacing: 4

                    Text {
                        id: targetTempText
                        text: Number(backend.targetTemp).toLocaleString(Qt.locale(), "f", 1)
                        color: "#EDEFF2"
                        font.pixelSize: 45
                        font.bold: true
                    }

                    Text {
                        text: "°C"
                        color: "#c6c5df"
                        font.pixelSize: 23
                        font.bold: true
                        // anchors.baseline: targetTempText.baseline
                    }
                }
                // Text {
                //     id: setTempLabel
                //     textFormat: Text.RichText
                //     text: Number(backend.targetTemp).toLocaleString(Qt.locale(), "f", 1)
                //           + " <span style='font-size:0.5em; vertical-align:super; color:#EDEFF2;font-weight:450; '>°C</span>"
                //     color: "#EDEFF2"
                //     font.pixelSize: 40
                //     font.bold: true
                //     horizontalAlignment: Text.AlignHCenter
                //     anchors.horizontalCenter: parent.horizontalCenter
                // }

                // tlačítko -0.5 °C
                Rectangle {
                    id: downButton
                    width: 90
                    height: 90
                    radius: 24
                    color: downArea.pressed ? "#5a5a5ac4" : "#00000099"
                    border.color: "transparent"
                    border.width: 1

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: biIcon
                        onLoaded: {
                            // chevron-down (bootstrap-icons)
                            item.code = "\uF282"
                            item.px = 80
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
