import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: setTP
    property real uiScale: 1.0

    title: "Nastavení teploty"
    background: Item {}
    visible: SwipeView.isCurrentItem

    readonly property bool isDual: backend.softwareType === 22

    // type 3 (legacy): aktuální teplota
    readonly property double currentTemp: backend.value1
    readonly property double diff: Math.abs(currentTemp - backend.targetTemp)

    // type 22:
    readonly property double diff1: Math.abs(backend.value1 - backend.targetTemp)
    readonly property double diff2: Math.abs(backend.value2 - backend.targetTemp2)

    // 1 = target1, 2 = target2 (pouze pro type 22)
    property int activeTarget: 1
    property bool lockToggled: false

    function isBadNumber(v) {
        // JS NaN check that works in QML
        return v !== v || v === undefined || v === null
    }

    function tempText(v) {
        // show dashes when sensor value is NaN / invalid
        return isBadNumber(v) ? "- -" : Number(v).toFixed(1)
    }

    function tempPx(v, basePx) {
        // If the number gets wider (>= 10.0 or <= -10.0), shrink it a bit so it doesn't overlap arrows.
        if (isBadNumber(v))
            return basePx

        var a = Number(v)
        if (a <= -0.1)
            return basePx * 0.8
        if (a >= 10)
            return basePx * 0.8
        return basePx
    }

    contentItem: Loader {
        anchors.fill: parent
        sourceComponent: setTP.isDual ? dualContent : singleContent
    }

    Component {
        id: singleContent

        Item {
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
                        text: setTP.tempText(setTP.currentTemp)
                        color: setTP.isBadNumber(setTP.currentTemp) ? "#c6c5df" : (setTP.diff > 2.5 ? "orange" : "#00ff00")
                        font.pixelSize: setTP.tempPx(setTP.currentTemp, 290 * uiScale)
                        font.bold: true
                    }

                    Text {
                        text: "°C"
                        color: "#c6c5df"
                        font.pixelSize: 95 * uiScale
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

    Component {
        id: dualContent

        Item {
            anchors.fill: parent
            anchors.margins: 32 * uiScale

            Row {
                anchors.fill: parent
                spacing: 0

                // ---- LEFT (V1 + TARGET1)
                Item {
                    id: leftBlock
                    width: parent.width * 0.42
                    height: parent.height


                    // větší přepínací plocha pro Target1
                    MouseArea {
                        anchors.fill: parent
                        onClicked: setTP.activeTarget = 1
                        z: 0
                    }
// ==========
                    Column {
                        anchors.centerIn: parent
                        spacing: 40 * uiScale
                        z: 1

                        Item {
                            id: v1Wrap
                            width: target1Box.width
                            height: v1Row.implicitHeight

                            Row {
                                id: v1Row
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: setTP.tempText(backend.value1)
                                    color: setTP.isBadNumber(backend.value1) ? "#c6c5df" : (setTP.diff1 > 2.5 ? "orange" : "#00ff00")
                                    font.pixelSize: setTP.tempPx(backend.value1, 200 * uiScale)
                                    font.bold: true
                                }

                                Text {
                                    text: "°C"
                                    color: "#c6c5df"
                                    font.pixelSize: 80 * uiScale
                                    font.bold: true
                                }
                            }
                        }

                        // TARGET1 box + "edit" under it
                        Column {
                            id: target1Col
                            width: 220 * uiScale
                            spacing: 2 * uiScale
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                id: target1Box
                                width: parent.width
                                height: 90 * uiScale
                                radius: 18 * uiScale
                                color: "transparent"
                                border.width: 5
                                border.color: (setTP.activeTarget === 1) ? "orange" : "#c6c5df"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4 * uiScale

                                    Text {
                                        text: Number(backend.targetTemp).toFixed(1)
                                        color: "#EDEFF2"
                                        font.pixelSize: 56 * uiScale
                                        font.bold: true
                                    }

                                    Text {
                                        text: "°C"
                                        color: "#c6c5df"
                                        font.pixelSize: 34 * uiScale
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: setTP.activeTarget = 1
                                }
                            }

                            Text {
                                text: "edit"
                                visible: setTP.activeTarget === 1
                                color: "orange"
                                font.pixelSize: 20 * uiScale
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // divider
                Rectangle {
                    width: 2
                    height: parent.height * 0.78
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#b9b9b9ff"
                }

                // ---- MIDDLE (shared arrows + lock icon)
                Item {
                    id: middleBlock
                    width: parent.width * 0.16
                    height: parent.height

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 20 * uiScale
                        spacing: 18 * uiScale

                        // top 2/3 controls
                        Item {
                            width: parent.width
                            height: parent.height * 0.66

                            Column {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                spacing: 18 * uiScale

                                Rectangle {
                                    width: 130 * uiScale
                                    height: 120 * uiScale
                                    radius: 22 * uiScale
                                    color: upArea22.pressed ? "#5a5a5ac4" : "#00000099"

                                    Loader {
                                        anchors.centerIn: parent
                                        sourceComponent: biIcon
                                        onLoaded: {
                                            item.code = "\uF286"
                                            item.px = 120 * uiScale
                                            item.iconColor = "#EDEFF2"
                                        }
                                    }

                                    MouseArea {
                                        id: upArea22
                                        anchors.fill: parent
                                        onClicked: {
                                            if (setTP.activeTarget === 1) backend.targetTemp = backend.targetTemp + 0.5
                                            else backend.targetTemp2 = backend.targetTemp2 + 0.5
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 130 * uiScale
                                    height: 120 * uiScale
                                    radius: 22 * uiScale
                                    color: downArea22.pressed ? "#5a5a5ac4" : "#00000099"

                                    Loader {
                                        anchors.centerIn: parent
                                        sourceComponent: biIcon
                                        onLoaded: {
                                            item.code = "\uF282"
                                            item.px = 120 * uiScale
                                            item.iconColor = "#EDEFF2"
                                        }
                                    }

                                    MouseArea {
                                        id: downArea22
                                        anchors.fill: parent
                                        onClicked: {
                                            if (setTP.activeTarget === 1) backend.targetTemp = backend.targetTemp - 0.5
                                            else backend.targetTemp2 = backend.targetTemp2 - 0.5
                                        }
                                    }
                                }
                            }
                        }

                        // bottom (lock icon toggle only)
                        Rectangle {
                            id: lockButton
                            width: 130 * uiScale
                            height: 120 * uiScale
                            radius: 22 * uiScale
                            color: lockArea.pressed ? "#5a5a5ac4" : "#00000099"

                            Loader {
                                id: lockIcon
                                anchors.centerIn: parent
                                sourceComponent: biIcon
                                onLoaded: {
                                    item.code = setTP.lockToggled ? "\uF47B" : "\uF600"
                                    item.px = 100 * uiScale
                                    item.iconColor = "#EDEFF2"
                                }
                            }

                            MouseArea {
                                id: lockArea
                                anchors.fill: parent
                                onClicked: {
                                    setTP.lockToggled = !setTP.lockToggled
                                    if (lockIcon.item) lockIcon.item.code = setTP.lockToggled ? "\uF47B" : "\uF600"
                                }
                            }
                        }
                    }
                }

                // divider
                Rectangle {
                    width: 2
                    height: parent.height * 0.78
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#b9b9b9ff"
                }

                // ---- RIGHT (V2 + TARGET2)
                Item {
                    id: rightBlock
                    width: parent.width * 0.42
                    height: parent.height


                    // větší přepínací plocha pro Target2
                    MouseArea {
                        anchors.fill: parent
                        onClicked: setTP.activeTarget = 2
                        z: 0
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 40 * uiScale
                        z: 1

                        Item {
                            id: v2Wrap
                            width: target2Box.width
                            height: v2Row.implicitHeight

                            Row {
                                id: v2Row
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: setTP.tempText(backend.value2)
                                    color: setTP.isBadNumber(backend.value2) ? "#c6c5df" : (setTP.diff2 > 2.5 ? "orange" : "#00ff00")
                                    font.pixelSize: setTP.tempPx(backend.value2, 200 * uiScale)
                                    font.bold: true
                                }

                                Text {
                                    text: "°C"
                                    color: "#c6c5df"
                                    font.pixelSize: 80 * uiScale
                                    font.bold: true
                                }
                            }
                        }

                        Column {
                            id: target2Col
                            width: 220 * uiScale
                            spacing: 2 * uiScale
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                id: target2Box
                                width: parent.width
                                height: 90 * uiScale
                                radius: 18 * uiScale
                                color: "transparent"
                                border.width: 5
                                border.color: (setTP.activeTarget === 2) ? "orange" : "#c6c5df"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4 * uiScale

                                    Text {
                                        text: Number(backend.targetTemp2).toFixed(1)
                                        color: "#EDEFF2"
                                        font.pixelSize: 56 * uiScale
                                        font.bold: true
                                    }

                                    Text {
                                        text: "°C"
                                        color: "#c6c5df"
                                        font.pixelSize: 34 * uiScale
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: setTP.activeTarget = 2
                                }
                            }

                            Text {
                                text: "edit"
                                visible: setTP.activeTarget === 2
                                color: "orange"
                                font.pixelSize: 20 * uiScale
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
