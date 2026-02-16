import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: page
    title: "Senzory"
    background: Item {}
    visible: SwipeView.isCurrentItem

    readonly property bool is22: backend.softwareType === 22
    readonly property real step: 0.1

    // UI state
    property string selectedAddr: ""
    property int selectedOffsetKey: -1   // 1..6

    function sensorRows() {
        if (is22) {
            return [
                { key: 1, label: "VANA 1", idProp: "sensor1Id", offProp: "sensor1Offset" },
                { key: 2, label: "VANA 2", idProp: "sensor2Id", offProp: "sensor2Offset" },
                { key: 3, label: "VYPAR 1", idProp: "sensor3Id", offProp: "sensor3Offset" },
                { key: 4, label: "VYPAR 2", idProp: "sensor4Id", offProp: "sensor4Offset" },
                { key: 5, label: "KONDEN", idProp: "sensor5Id", offProp: "sensor5Offset" },
                { key: 6, label: "NASAV", idProp: "sensor6Id", offProp: "sensor6Offset" }
            ]
        }
        return [
            { key: 1, label: "VANA", idProp: "sensor1Id", offProp: "sensor1Offset" },
            { key: 3, label: "VYPAR", idProp: "sensor3Id", offProp: "sensor3Offset" },
            { key: 5, label: "KONDEN", idProp: "sensor5Id", offProp: "sensor5Offset" },
            { key: 6, label: "NASAV", idProp: "sensor6Id", offProp: "sensor6Offset" }
        ]
    }

    function getOff(key) {
        switch (key) {
        case 1: return backend.sensor1Offset
        case 2: return backend.sensor2Offset
        case 3: return backend.sensor3Offset
        case 4: return backend.sensor4Offset
        case 5: return backend.sensor5Offset
        case 6: return backend.sensor6Offset
        default: return 0
        }
    }

    function setOff(key, v) {
        // lehká ochrana rozsahu (ať se to neutrhne)
        v = Math.max(-50, Math.min(50, v))
        switch (key) {
        case 1: backend.sensor1Offset = v; break
        case 2: backend.sensor2Offset = v; break
        case 3: backend.sensor3Offset = v; break
        case 4: backend.sensor4Offset = v; break
        case 5: backend.sensor5Offset = v; break
        case 6: backend.sensor6Offset = v; break
        }
    }

    function setId(key, addr) {
        switch (key) {
        case 1: backend.sensor1Id = addr; break
        case 2: backend.sensor2Id = addr; break
        case 3: backend.sensor3Id = addr; break
        case 4: backend.sensor4Id = addr; break
        case 5: backend.sensor5Id = addr; break
        case 6: backend.sensor6Id = addr; break
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        // ============ LEFT: visible 1-wire addresses ============
        Rectangle {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            radius: 12
            color: "#1d1f24"
            border.color: "#2a2d34"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label { text: "VIDITELNÉ 1-WIRE"; color: "white"; font.pixelSize: 16; Layout.fillWidth: true }

                    Button {
                        text: "↻"
                        onClicked: backend.refreshVisibleOneWireIds()
                        width: 44
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: backend.visibleOneWireIds

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 44
                        radius: 10
                        color: (modelData === selectedAddr) ? "#2f6fed" : "#262a31"
                        border.color: "#2a2d34"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            text: modelData
                            color: "white"
                            font.pixelSize: 15
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: selectedAddr = modelData
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#2a2d34"
                }

                Label {
                    Layout.fillWidth: true
                    color: "#bfc6d1"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    text: selectedAddr === "" ?
                          "Tip: Klikni na adresu vlevo, potom klikni na roli čidla (vpravo uprostřed) pro přiřazení." :
                          ("Vybraná adresa: " + selectedAddr)
                }
            }
        }

        // ============ MIDDLE: mapping + offsets ============
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "#1d1f2425"
            border.color: "#c6c5df"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 5

                Label { text: is22 ? "PŘIŘAZENÍ + OFFSETY (2+2)" : "PŘIŘAZENÍ + OFFSETY (TYP-3)"; color: "white"; font.pixelSize: 16 }

                Repeater {
                    model: sensorRows()

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 80
                        radius: 12
                        color: (selectedOffsetKey === modelData.key) ? "#263451" : "#262a31"
                        border.width: 2
                        border.color: (selectedOffsetKey === modelData.key) ? "orange" : "#c6c5df"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // role + current id (kliknutím přiřadíš vybranou adresu)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text { text: modelData.label; color: "white"; font.pixelSize: 15 }
                                Text {
                                    text: backend[modelData.idProp]
                                    color: "#bfc6d1"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }

                            // offset display (kliknutím vybereš čidlo pro šipky)
                            Rectangle {
                                width: 110
                                height: 38
                                radius: 10
                                color: "#1d1f24"
                                border.color: "#3a3f49"

                                Text {
                                    anchors.centerIn: parent
                                    text: (getOff(modelData.key) >= 0 ? "+" : "") + getOff(modelData.key).toFixed(1) + " °C"
                                    color: "white"
                                    font.pixelSize: 14
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                selectedOffsetKey = modelData.key
                                if (selectedAddr !== "") {
                                    setId(modelData.key, selectedAddr)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ============ RIGHT: common arrows ============
        Rectangle {
            Layout.preferredWidth: 140
            Layout.fillHeight: true
            radius: 12
            color: "#1d1f24"
            border.color: "#2a2d34"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Label { text: "ŠIPKY"; color: "white"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#bfc6d1"
                    font.pixelSize: 13
                    text: selectedOffsetKey < 0 ? "Vyber čidlo uprostřed." : ("Krok: " + step.toFixed(1) + " °C")
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2d34" }

                Item { Layout.fillHeight: true }

                Button {
                    Layout.fillWidth: true
                    text: "▲"
                    enabled: selectedOffsetKey > 0
                    onClicked: setOff(selectedOffsetKey, getOff(selectedOffsetKey) + step)
                }

                Button {
                    Layout.fillWidth: true
                    text: "▼"
                    enabled: selectedOffsetKey > 0
                    onClicked: setOff(selectedOffsetKey, getOff(selectedOffsetKey) - step)
                }

                Button {
                    Layout.fillWidth: true
                    text: "0.0"
                    enabled: selectedOffsetKey > 0
                    onClicked: setOff(selectedOffsetKey, 0.0)
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
