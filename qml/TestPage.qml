import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    id: stp
    property real uiScale: 1.0

    title: "Test vstupů senzorů"
    background: Item {}
    visible: SwipeView.isCurrentItem

    // pro levý velký výpis (stejně jako SetTempPage)
    readonly property double avgTemp: (backend.value1 + backend.value2) / 2.0

    contentItem: Item {
        anchors.fill: parent

        // LEVÁ ČÁST (cca 1/3)
        Rectangle {
            id: leftPane
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.34
            color: "transparent"

            Column {
                anchors.centerIn: parent
                spacing: 18 * uiScale

                Text {
                    text: "VSTUPY"
                    color: "#EDEFF2"
                    font.pixelSize: 38 * uiScale
                    font.bold: true
                }

                Text {
                    text: backend.forcedSensors ? "FORCED" : "SENZORY"
                    color: backend.forcedSensors ? "orange" : "#00ff00"
                    font.pixelSize: 36 * uiScale
                    font.bold: true
                }

                Row {
                    spacing: 6 * uiScale
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: Number(stp.avgTemp).toFixed(1)
                        color: "#EDEFF2"
                        font.pixelSize: 120 * uiScale
                        font.bold: true
                    }
                    Text {
                        text: "°C"
                        color: "#c6c5df"
                        font.pixelSize: 60 * uiScale
                        font.bold: true
                    }
                }

                Text {
                    text: "Průměr (T1+T2)/2"
                    color: "#c6c5df"
                    font.pixelSize: 18 * uiScale
                }
            }
        }

        // Svislá čára (stejně jako SetTempPage)
        Rectangle {
            id: divider
            x: parent.width * 0.34
            width: 2 * uiScale
            height: parent.height * 0.82
            anchors.verticalCenter: parent.verticalCenter
            color: "#c6c5df"
            opacity: 0.65
        }

        // PRAVÁ ČÁST (cca 2/3)
        Rectangle {
            id: rightPane
            anchors.left: divider.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: "transparent"

            Column {
                anchors.centerIn: parent
                spacing: 22 * uiScale
                width: parent.width * 0.92

                // HORNÍ ŘÁDEK: Forced toggle vlevo + tři teploty vpravo
                Row {
                    width: parent.width
                    spacing: 16 * uiScale

                    // Forced toggle
                    Rectangle {
                        id: forcedBtn
                        width: 220 * uiScale
                        height: 74 * uiScale
                        radius: 20 * uiScale
                        color: forcedArea.pressed
                               ? "#5a5a5ac4"
                               : (backend.forcedSensors ? "#000000cc" : "#00000099")
                        border.width: 2 * uiScale
                        border.color: backend.forcedSensors ? "orange" : "#c6c5df"

                        Text {
                            anchors.centerIn: parent
                            text: "FORCED"
                            color: backend.forcedSensors ? "orange" : "#EDEFF2"
                            font.pixelSize: 26 * uiScale
                            font.bold: true
                        }

                        MouseArea {
                            id: forcedArea
                            anchors.fill: parent
                            onClicked: backend.forcedSensors = !backend.forcedSensors
                        }
                    }

                    // tři teploty aktuálně vstupující do aplikace (už přepnuté forced/senzory)
                    Rectangle {
                        width: parent.width - forcedBtn.width - (16 * uiScale)
                        height: forcedBtn.height
                        radius: 20 * uiScale
                        color: "#00000066"
                        border.width: 1 * uiScale
                        border.color: "#c6c5df"
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: 18 * uiScale
                    
                            Text {
                                text: "T1: " + Number(backend.value1).toFixed(1) + "°C"
                                color: "#EDEFF2"
                                font.pixelSize: 22 * uiScale
                                font.bold: true
                            }
                            Text {
                                text: "T2: " + Number(backend.value2).toFixed(1) + "°C"
                                color: "#EDEFF2"
                                font.pixelSize: 22 * uiScale
                                font.bold: true
                            }
                            Text {
                                text: "T3: " + Number(backend.value3).toFixed(1) + "°C"
                                color: "#EDEFF2"
                                font.pixelSize: 22 * uiScale
                                font.bold: true
                            }
                        }
                    }
                }

                // 3 nastavováky (po 1°C)
                Column {
                    width: parent.width
                    spacing: 14 * uiScale

                    // Pomocný “řádek nastavováku”
                    function makeLabel(name) { return name }

                    // T1
                    Rectangle {
                        width: parent.width
                        height: 92 * uiScale
                        radius: 22 * uiScale
                        color: "#00000066"
                        border.width: 1 * uiScale
                        border.color: "#c6c5df"
                        opacity: backend.forcedSensors ? 1.0 : 0.55

                        Row {
                            anchors.fill: parent
                            anchors.margins: 14 * uiScale
                            spacing: 16 * uiScale

                            Text {
                                text: "FORCED T1"
                                width: 170 * uiScale
                                color: "#EDEFF2"
                                font.pixelSize: 22 * uiScale
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                width: 90 * uiScale; height: 64 * uiScale
                                radius: 18 * uiScale
                                color: minus1.pressed ? "#5a5a5ac4" : "#00000099"
                                Text { anchors.centerIn: parent; text: "-1"; color: "#EDEFF2"; font.pixelSize: 22 * uiScale; font.bold: true }
                                MouseArea { id: minus1; anchors.fill: parent; onClicked: backend.forcedTemp1 = backend.forcedTemp1 - 1.0 }
                            }

                            Text {
                                text: Number(backend.forcedTemp1).toFixed(0) + "°C"
                                color: "#EDEFF2"
                                font.pixelSize: 34 * uiScale
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                width: 90 * uiScale; height: 64 * uiScale
                                radius: 18 * uiScale
                                color: plus1.pressed ? "#5a5a5ac4" : "#00000099"
                                Text { anchors.centerIn: parent; text: "+1"; color: "#EDEFF2"; font.pixelSize: 22 * uiScale; font.bold: true }
                                MouseArea { id: plus1; anchors.fill: parent; onClicked: backend.forcedTemp1 = backend.forcedTemp1 + 1.0 }
                            }
                        }
                    }

                    // T2
                    Rectangle {
                        width: parent.width
                        height: 92 * uiScale
                        radius: 22 * uiScale
                        color: "#00000066"
                        border.width: 1 * uiScale
                        border.color: "#c6c5df"
                        opacity: backend.forcedSensors ? 1.0 : 0.55

                        Row {
                            anchors.fill: parent
                            anchors.margins: 14 * uiScale
                            spacing: 16 * uiScale

                            Text {
                                text: "FORCED T2"
                                width: 170 * uiScale
                                color: "#EDEFF2"
                                font.pixelSize: 22 * uiScale
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                width: 90 * uiScale; height: 64 * uiScale
                                radius: 18 * uiScale
                                color: minus2.pressed ? "#5a5a5ac4" : "#00000099"
                                Text { anchors.centerIn: parent; text: "-1"; color: "#EDEFF2"; font.pixelSize: 22 * uiScale; font.bold: true }
                                MouseArea { id: minus2; anchors.fill: parent; onClicked: backend.forcedTemp2 = backend.forcedTemp2 - 1.0 }
                            }

                            Text {
                                text: Number(backend.forcedTemp2).toFixed(0) + "°C"
                                color: "#EDEFF2"
                                font.pixelSize: 34 * uiScale
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                width: 90 * uiScale; height: 64 * uiScale
                                radius: 18 * uiScale
                                color: plus2.pressed ? "#5a5a5ac4" : "#00000099"
                                Text { anchors.centerIn: parent; text: "+1"; color: "#EDEFF2"; font.pixelSize: 22 * uiScale; font.bold: true }
                                MouseArea { id: plus2; anchors.fill: parent; onClicked: backend.forcedTemp2 = backend.forcedTemp2 + 1.0 }
                            }
                        }
                    }

                    // T3
                    Rectangle {
                        width: parent.width
                        height: 92 * uiScale
                        radius: 22 * uiScale
                        color: "#00000066"
                        border.width: 1 * uiScale
                        border.color: "#c6c5df"
                        opacity: backend.forcedSensors ? 1.0 : 0.55

                        Row {
                            anchors.fill: parent
                            anchors.margins: 14 * uiScale
                            spacing: 16 * uiScale

                            Text {
                                text: "FORCED T3"
                                width: 170 * uiScale
                                color: "#EDEFF2"
                                font.pixelSize: 22 * uiScale
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                width: 90 * uiScale; height: 64 * uiScale
                                radius: 18 * uiScale
                                color: minus3.pressed ? "#5a5a5ac4" : "#00000099"
                                Text { anchors.centerIn: parent; text: "-1"; color: "#EDEFF2"; font.pixelSize: 22 * uiScale; font.bold: true }
                                MouseArea { id: minus3; anchors.fill: parent; onClicked: backend.forcedTemp3 = backend.forcedTemp3 - 1.0 }
                            }

                            Text {
                                text: Number(backend.forcedTemp3).toFixed(0) + "°C"
                                color: "#EDEFF2"
                                font.pixelSize: 34 * uiScale
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                width: 90 * uiScale; height: 64 * uiScale
                                radius: 18 * uiScale
                                color: plus3.pressed ? "#5a5a5ac4" : "#00000099"
                                Text { anchors.centerIn: parent; text: "+1"; color: "#EDEFF2"; font.pixelSize: 22 * uiScale; font.bold: true }
                                MouseArea { id: plus3; anchors.fill: parent; onClicked: backend.forcedTemp3 = backend.forcedTemp3 + 1.0 }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Když je FORCED zapnutý, SensorWorker místo čtení DS18B20 posílá do aplikace tyto ručně nastavené hodnoty."
                    color: "#c6c5df"
                    font.pixelSize: 16 * uiScale
                }
            }
        }
    }
}
