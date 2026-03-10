import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "I18n.js" as I18n

Page {
    id: page
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"
    title: I18n.t(lang, "sensor.title")
    background: Rectangle { color: "transparent" }

    // POUŽIJU PŘÍMO globální uiScale z projektu.
    // Pokud ho nemáš, dej si sem "property real s: 1.0"
    readonly property real s: uiScale

    readonly property bool is22: backend.softwareType === 22
    readonly property real step: 0.1

    property string selectedAddr: ""
    property int selectedOffsetKey: -1   // 1..6
    property bool assignUnlocked: false

    readonly property bool canAdjust: selectedOffsetKey > 0

    function sensorRows() {
        if (is22) {
            return [
                { key: 1, label: "VANA 1", idProp: "sensor1Id" },
                { key: 2, label: "VANA 2", idProp: "sensor2Id" },
                { key: 3, label: "VÝPARNÍK 1", idProp: "sensor3Id" },
                { key: 4, label: "VÝPARNÍK 2", idProp: "sensor4Id" },
                { key: 5, label: "KONDENZÁTOR", idProp: "sensor5Id" },
                { key: 6, label: "NASÁVÁNÍ", idProp: "sensor6Id" }
            ]
        }
        return [
            { key: 1, label: "VANA", idProp: "sensor1Id" },
            { key: 3, label: "VÝPARNÍK", idProp: "sensor3Id" },
            { key: 5, label: "KONDENZÁTOR", idProp: "sensor5Id" },
            { key: 6, label: "NASÁVÁNÍ", idProp: "sensor6Id" }
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

    function adjust(delta) {
        if (!canAdjust) return
        setOff(selectedOffsetKey, getOff(selectedOffsetKey) + delta)
    }

    // ---------- GEOMETRIE (anchors, žádný RowLayout) ----------
    readonly property real pad: 14 * s
    readonly property real gap: 14 * s

    readonly property real leftW: Math.round((width - 2*pad - 2*gap) * 0.30)
    readonly property real rightW: Math.round((width - 2*pad - 2*gap) * 0.18)
    readonly property real midW: (width - 2*pad - 2*gap) - leftW - rightW

    // ============ LEFT ============
    Rectangle {
        id: leftPane
        x: pad
        y: pad
        width: leftW
        height: parent.height - 2*pad
        radius: 20 * s
        color: page.assignUnlocked ? "#bb2e2e2e" : "#772e2e2e"
        border.width: 1 * s
        border.color: page.assignUnlocked ? "#c6c5df" : "#77c6c5df"

        Column {
            anchors.fill: parent
            anchors.margins: 14 * s
            spacing: 12 * s

            Row {
                width: parent.width
                height: 36 * s
                spacing: 10 * s

                Text {
                    text: I18n.t(page.lang, "sensor.visible")
                    color: page.assignUnlocked ? "#c6c5df" : "#77c6c5df"
                    font.pixelSize: 18 * s
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1; height: 1; anchors.horizontalCenter: undefined }

                Rectangle {
                    width: 60 * s
                    height: 50 * s
                    radius: 10 * s
                    color: refreshArea.pressed ? "#5a5a5ac4" : "#00000099"
                    border.width: 1 * s
                    border.color: "#88c6c5df"
                    anchors.verticalCenter: parent.verticalCenter

                    Text { anchors.centerIn: parent; text: "↻"; color: "#EDEFF2"; font.pixelSize: 30 * s; font.bold: true; opacity: page.assignUnlocked ? 1.0 : 0.6 }
                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        onClicked: backend.refreshVisibleOneWireIds()
                    }
                }
                Rectangle {
                    width: 60 * s
                    height: 50 * s
                    radius: 10 * s
                    color: unlockArea.pressed ? "#5a5a5ac4" : "#00000099"
                    border.width: 1 * s
                    border.color: "#88c6c5df"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: page.assignUnlocked ? "\uF600" : "\uF47B"
                        color: "#EDEFF2"
                        font.pixelSize: 28 * s
                        font.bold: true
                    }

                    MouseArea {
                        id: unlockArea
                        anchors.fill: parent
                        onClicked: page.assignUnlocked = !page.assignUnlocked
                    }
                }

            }

            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

            ListView {
                id: addrList
                width: parent.width
                height: parent.height - (36*s + 12*s + 1*s + 12*s + 50*s)
                clip: true
                model: backend.visibleOneWireIds
                spacing: 10 * s

                delegate: Rectangle {
                    width: addrList.width
                    height: 58 * s
                    radius: 18 * s
                    color: (modelData === selectedAddr & page.assignUnlocked) ? "#2f6fed" : "#1d1f24"
                    border.width: 1 * s
                    border.color: "#c6c5df"
                    opacity: page.assignUnlocked ? 0.95 : 0.5

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: "#EDEFF2"
                        font.pixelSize: 22 * s
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: selectedAddr = modelData
                    }
                }
            }

            Text {
                width: parent.width
                text: selectedAddr === "" ? I18n.t(page.lang, "sensor.select_hint") : (I18n.t(page.lang, "sensor.selected_prefix") + selectedAddr)
                color: selectedAddr === "" ? "#666666" : "#c6c5df"
                font.pixelSize: 16 * s
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    // ============ MIDDLE ============
    Rectangle {
        id: midPane
        x: leftPane.x + leftPane.width + gap
        y: pad
        width: midW
        height: parent.height - 2*pad
        radius: 20 * s
        color: "#bb2e2e2e"
        border.width: 1 * s
        border.color: "#c6c5df"

        Column {
            anchors.fill: parent
            anchors.margins: 14 * s
            spacing: 12 * s

            Text {
                width: parent.width
                text: is22 ? I18n.t(page.lang, "sensor.assign22") : I18n.t(page.lang, "sensor.assign3")
                color: "white"
                font.pixelSize: 18 * s
                font.bold: true
            }

            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

            Grid {
                id: grid
                width: parent.width
                height: parent.height - (24*s + 12*s + 1*s + 12*s)
                columns: 2
                spacing: 12 * s

                Repeater {
                    model: sensorRows()

                    delegate: Rectangle {
                        width: (grid.width - grid.spacing) / 2
                        height: 150 * s
                        radius: 22 * s
                        color: (selectedOffsetKey === modelData.key) ? "#2158c7" : "#1d1f24"
                        border.width: 2 * s
                        border.color: (selectedOffsetKey === modelData.key) ? "orange" : "#757485"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14 * s
                            spacing: 8 * s

                            Text {
                                text: modelData.label
                                color: "#EDEFF2"
                                font.pixelSize: 20 * s
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: backend[modelData.idProp]
                                color: "white"
                                font.pixelSize: 18 * s
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: parent.width
                                height: 50 * s
                                radius: 16 * s
                                color: "#00000077"
                                border.width: 1 * s
                                border.color: "#c6c5df"

                                Text {
                                    anchors.centerIn: parent
                                    text: (getOff(modelData.key) >= 0 ? "+" : "") + getOff(modelData.key).toFixed(1) + " °C"
                                    color: "#EDEFF2"
                                    font.pixelSize: 24 * s
                                    font.bold: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                selectedOffsetKey = modelData.key
                                if (page.assignUnlocked && selectedAddr !== "") setId(modelData.key, selectedAddr)
                            }
                        }
                    }
                }
            }
        }
    }

    // ============ RIGHT (arrows like TestPage) ============
    Rectangle {
        id: rightPane
        x: midPane.x + midPane.width + gap
        y: pad
        width: rightW
        height: parent.height - 2*pad
        radius: 20 * s
        color: "#bb2e2e2e"
        border.width: 1 * s
        border.color: "#c6c5df"
        opacity: page.canAdjust ? 1.0 : 0.6

        Column {
            anchors.centerIn: parent
            spacing: 18 * s

            Rectangle {
                width: 120 * s
                height: 120 * s
                radius: 26 * s
                color: upArea.pressed ? "#5a5a5ac4" : "#00000099"
                opacity: page.canAdjust ? 1.0 : 0.35
                border.width: 2 * s
                border.color: "#c6c5df"

                Text { anchors.centerIn: parent; text: "▲"; color: "#EDEFF2"; font.pixelSize: 60 * s; font.bold: true }
                MouseArea { id: upArea; anchors.fill: parent; enabled: page.canAdjust; onClicked: page.adjust(+page.step) }
            }

            Text {
                text: page.canAdjust ? I18n.format(page.lang, "sensor.step", Number(page.step).toFixed(1)) : I18n.t(page.lang, "sensor.select_sensor")
                color: page.canAdjust ? "#c6c5df" : "#666666"
                font.pixelSize: 18 * s
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Rectangle {
                width: 120 * s
                height: 120 * s
                radius: 26 * s
                color: downArea.pressed ? "#5a5a5ac4" : "#00000099"
                opacity: page.canAdjust ? 1.0 : 0.35
                border.width: 2 * s
                border.color: "#c6c5df"

                Text { anchors.centerIn: parent; text: "▼"; color: "#EDEFF2"; font.pixelSize: 60 * s; font.bold: true }
                MouseArea { id: downArea; anchors.fill: parent; enabled: page.canAdjust; onClicked: page.adjust(-page.step) }
            }

            // ZERO (nulování offsetu)
            Rectangle {
                width: 120 * s
                height: 64 * s
                radius: 22 * s
                color: zeroArea.pressed ? "#5a5a5ac4" : "#00000099"
                opacity: page.canAdjust ? 1.0 : 0.35
                border.width: 2 * s
                border.color: "#c6c5df"

                Text { anchors.centerIn: parent; text: "0.0"; color: "#EDEFF2"; font.pixelSize: 26 * s; font.bold: true }
                MouseArea { id: zeroArea; anchors.fill: parent; enabled: page.canAdjust; onClicked: page.setOff(page.selectedOffsetKey, 0.0) }
            }
        }
    }
}
