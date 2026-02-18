import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: page
    property real uiScale: 1.0

    title: "Test"
    background: Item {}
    visible: SwipeView.isCurrentItem

    readonly property real step: 0.5

    // helper lists (live/forced) per mode
    readonly property bool is22: backend.softwareType === 22

    function liveModel() {
        if (!is22) {
            return [
                { label: "VANA", val: backend.value1 },
                { label: "VYPAR", val: backend.value3 },
                { label: "KOND", val: backend.value5 },
                { label: "NAS",  val: backend.value6 },
                { label: "VLHK", val: backend.humidity }
            ]
        }
        return [
            { label: "VANA1", val: backend.value1 },
            { label: "VANA2", val: backend.value2 },
            { label: "VYP1",  val: backend.value3 },
            { label: "VYP2",  val: backend.value4 },
            { label: "KOND",  val: backend.value5 },
            { label: "NAS",   val: backend.value6 },
            { label: "VLHK",  val: backend.humidity }
        ]
    }

    function forcedModel() {
        if (!is22) {
            return [
                { idx: 1, label: "VANA", val: backend.forcedTemp1},
                { idx: 3, label: "VYPAR", val: backend.forcedTemp3 },
                { idx: 5, label: "KOND", val: backend.forcedTemp5 }
            ]
        }
        return [
            { idx: 1, label: "VANA1", val: backend.forcedTemp1 },
            { idx: 2, label: "VANA2", val: backend.forcedTemp2 },
            { idx: 3, label: "VYP1",  val: backend.forcedTemp3 },
            { idx: 4, label: "VYP2",  val: backend.forcedTemp4 },
            { idx: 5, label: "KOND",  val: backend.forcedTemp5 }
        ]
    }

    // selected forced index (1..5, but in v-3 we use 1,3,5)
    property int selectedIndex: is22 ? 1 : 1

    function selectIdx(i) {
        if (!backend.forcedSensors) return
        selectedIndex = i
    }

    function adjust(delta) {
        if (!backend.forcedSensors) return

        switch (selectedIndex) {
        case 1: backend.forcedTemp1 = backend.forcedTemp1 + delta; break
        case 2: backend.forcedTemp2 = backend.forcedTemp2 + delta; break
        case 3: backend.forcedTemp3 = backend.forcedTemp3 + delta; break
        case 4: backend.forcedTemp4 = backend.forcedTemp4 + delta; break
        case 5: backend.forcedTemp5 = backend.forcedTemp5 + delta; break
        }
    }

    contentItem: Item {
        anchors.fill: parent

        Row {
            anchors.fill: parent
            anchors.margins: 18 * uiScale
            spacing: 18 * uiScale

            // LEFT: LIVE / FORCED
            Rectangle {
                id: leftPane
                width: parent.width * 0.52
                height: parent.height
                radius: 20 * uiScale
                color: "transparent"
                border.width: 1 * uiScale
                border.color: "#c6c5df"

                Row {
                    anchors.fill: parent
                    anchors.margins: 14 * uiScale
                    spacing: 14 * uiScale

                    // LIVE
                    Rectangle {
                        width: parent.width * 0.50
                        height: parent.height
                        radius: 18 * uiScale
                        color: "#bb2e2e2e"
                        border.width: 1 * uiScale
                        border.color: "#c6c5df"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12 * uiScale
                            spacing: 10 * uiScale

                            Text {
                                text: "LIVE"
                                color: "#EDEFF2"
                                font.pixelSize: 24 * uiScale
                                font.bold: true
                            }

                            Repeater {
                                model: page.liveModel()

                                delegate: Rectangle {
                                    width: parent.width
                                    height: 57 * uiScale
                                    radius: 16 * uiScale
                                    color: "#1d1f24"
                                    border.width: 1 * uiScale
                                    border.color: "#c6c5df"

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 8 * uiScale
                                        spacing: 10 * uiScale

                                        Text {
                                            width: 120 * uiScale
                                            text: modelData.label
                                            color: "#EDEFF2"
                                            font.pixelSize: 22 * uiScale
                                            font.bold: true
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Text {
                                            text: Number(modelData.val).toFixed(1) + (modelData.label === "VLHK" ? "%" : "°C")
                                            color: "#EDEFF2"
                                            font.pixelSize: 28 * uiScale
                                            font.bold: true
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // FORCED
                    Rectangle {
                        width: parent.width - (parent.width * 0.50) - (14 * uiScale)
                        height: parent.height
                        radius: 18 * uiScale
                        color: "#bb2e2e2e"
                        border.width: 1 * uiScale
                        border.color: "#c6c5df"
                        opacity: backend.forcedSensors ? 1.0 : 0.5

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12 * uiScale
                            spacing: 10 * uiScale

                            Row {
                                spacing: 10 * uiScale
                                Text {
                                    text: "FORCED"
                                    color: backend.forcedSensors ? "orange" : "#c6c5df"
                                    font.pixelSize: 24 * uiScale
                                    font.bold: true
                                }
                                Text {
                                    text: backend.forcedSensors ? "ON" : "OFF"
                                    color: backend.forcedSensors ? "orange" : "#c6c5df"
                                    font.pixelSize: 24 * uiScale
                                    font.bold: true
                                }
                            }

                            Repeater {
                                model: page.forcedModel()
                                delegate: Rectangle {
                                    readonly property int idx: modelData.idx
                                    readonly property bool isSelected: backend.forcedSensors && (page.selectedIndex === idx)

                                    width: parent.width
                                    height: 70 * uiScale
                                    radius: 16 * uiScale
                                    color: isSelected ? "#5a5a5ac4" : "#1d1f24"
                                    border.width: 2 * uiScale
                                    border.color: isSelected ? "orange" : "#c6c5df"
                                    opacity: backend.forcedSensors ? 1.0 : 0.5

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: backend.forcedSensors
                                        onClicked: page.selectIdx(idx)
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 12 * uiScale
                                        spacing: 10 * uiScale

                                        Text {
                                            width: 120 * uiScale
                                            text: modelData.label
                                            color: "#EDEFF2"
                                            font.pixelSize: 22 * uiScale
                                            font.bold: true
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Text {
                                            text: Number(modelData.val).toFixed(1) + "°C"
                                            color: "#EDEFF2"
                                            font.pixelSize: 28 * uiScale
                                            font.bold: true
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Item { width: 1; Layout.fillWidth: true }
                                        Text {
                                            text: isSelected ? "EDIT" : ""
                                            color: "orange"
                                            font.pixelSize: 16 * uiScale
                                            font.bold: true
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: "Click on the temperature (FORCED) and adjust it using the arrow keys. Step" + Number(page.step).toFixed(1) + "°C. Outside of FORCED everything is locked."
                                color: "#c6c5df"
                                font.pixelSize: 14 * uiScale
                            }
                        }
                    }
                }
            }

            // MIDDLE: šipky
            Rectangle {
                id: midPane
                width: parent.width * 0.18
                height: parent.height
                radius: 20 * uiScale
                color: "#bb2e2e2e"
                border.width: 1 * uiScale
                border.color: "#c6c5df"
                opacity: backend.forcedSensors ? 1.0 : 0.5

                Column {
                    anchors.centerIn: parent
                    spacing: 18 * uiScale

                    Rectangle {
                        width: 120 * uiScale
                        height: 120 * uiScale
                        radius: 26 * uiScale
                        color: upArea.pressed ? "#5a5a5ac4" : "#88000000"
                        opacity: backend.forcedSensors ? 1.0 : 0.35
                        border.width: 2 * uiScale
                        border.color: "#c6c5df"

                        Text { anchors.centerIn: parent; text: "▲"; color: "#EDEFF2"; font.pixelSize: 60 * uiScale; font.bold: true }

                        MouseArea { id: upArea; anchors.fill: parent; enabled: backend.forcedSensors; onClicked: page.adjust(+page.step) }
                    }

                    Text {
                        text: backend.forcedSensors ? ("krok " + Number(page.step).toFixed(1) + "°C") : "FORCED OFF"
                        color: backend.forcedSensors ? "#c6c5df" : "#666666"
                        font.pixelSize: 18 * uiScale
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    Rectangle {
                        width: 120 * uiScale
                        height: 120 * uiScale
                        radius: 26 * uiScale
                        color: downArea.pressed ? "#5a5a5ac4" : "#88000000"
                        opacity: backend.forcedSensors ? 1.0 : 0.35
                        border.width: 2 * uiScale
                        border.color: "#c6c5df"

                        Text { anchors.centerIn: parent; text: "▼"; color: "#EDEFF2"; font.pixelSize: 60 * uiScale; font.bold: true }

                        MouseArea { id: downArea; anchors.fill: parent; enabled: backend.forcedSensors; onClicked: page.adjust(-page.step) }
                    }
                }
            }

            // RIGHT: tlačítka
            Rectangle {
                id: rightPane
                width: parent.width - leftPane.width - midPane.width - 2 * (18 * uiScale)
                height: parent.height
                radius: 20 * uiScale
                color: "#bb2e2e2e"
                border.width: 1 * uiScale
                border.color: "#c6c5df"

                Column {
                    anchors.centerIn: parent
                    spacing: 16 * uiScale

                    // 1) soft type
                    Rectangle {
                        width: 280 * uiScale
                        height: 120 * uiScale
                        radius: 22 * uiScale
                        color: softArea.pressed ? "#5a5a5ac4" : "#66000000"
                        border.width: 2 * uiScale
                        border.color: "#c6c5df"

                        Text {
                            anchors.centerIn: parent
                            text: backend.softwareType == 22 ? "SOFT: TYP 2+2" : "SOFT: TYP 3"
                            color: "#EDEFF2"
                            font.pixelSize: 24 * uiScale
                            font.bold: true
                        }

                        MouseArea { id: softArea; anchors.fill: parent; onClicked: backend.softwareType = (backend.softwareType == 22 ? 3 : 22) }
                    }

                    // 2) forced teploty
                    Rectangle {
                        width: 280 * uiScale
                        height: 120 * uiScale
                        radius: 22 * uiScale
                        color: forcedArea.pressed ? "#5a5a5ac4" : (backend.forcedSensors ? "#1d1f24" : "#1d1f24")
                        border.width: 2 * uiScale
                        border.color: backend.forcedSensors ? "orange" : "#c6c5df"

                        Text {
                            anchors.centerIn: parent
                            text: backend.forcedSensors ? "FORCED TEPLOTY ON" : "FORCED TEPLOTY OFF"
                            color: backend.forcedSensors ? "orange" : "#EDEFF2"
                            font.pixelSize: 22 * uiScale
                            font.bold: true
                        }

                        MouseArea { id: forcedArea; anchors.fill: parent; onClicked: backend.forcedSensors = !backend.forcedSensors }
                    }

                    
                }
            }
        }
    }
}
