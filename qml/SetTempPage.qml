import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "I18n.js" as I18n

Page {
    id: setTP
    property real uiScale: 1.0
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"
    signal userActivity()

    title: I18n.t(lang, "settemp.title")
    background: Item {}
    visible: SwipeView.isCurrentItem

    readonly property bool isDual: backend.softwareType === 22

    // type 3 (legacy): aktuální teplota
    readonly property double currentTemp: backend.value1
    readonly property double diff: Math.abs(currentTemp - backend.targetTemp)
    readonly property bool defrost1Active: backend.defrostActive

    // type 22:
    readonly property double diff1: Math.abs(backend.value1 - backend.targetTemp)
    readonly property double diff2: Math.abs(backend.value2 - backend.targetTemp2)
    readonly property bool defrost2Active: backend.defrost2Active

    // 1 = target1, 2 = target2 (pouze pro type 22)
    property int activeTarget: 1

    function noteActivity() {
        userActivity()
    }

    function isBadNumber(v) {
        // JS NaN check that works in QML
        return v !== v || v === undefined || v === null
    }

    function tempText(v, defr) {

        if (defr)
            return I18n.t(setTP.lang, "settemp.def")
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

    // small ON/OFF pill buttons used for bath enable
    Component {
        id: bathToggleRow

        Row {
            property bool enabledValue: true
            property var onChangedFn: function(v) {}

            spacing: 6 * setTP.uiScale

            Rectangle {
                width: 56 * setTP.uiScale
                height: 28 * setTP.uiScale
                radius: 14 * setTP.uiScale
                color: enabledValue ? "#00ff00" : "#00000066"
                border.width: 1
                border.color: "#c6c5df"

                Text {
                    anchors.centerIn: parent
                    text: I18n.t(setTP.lang, "settemp.on")
                    color: enabledValue ? "#000000" : "#c6c5df"
                    font.pixelSize: 14 * setTP.uiScale
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        setTP.noteActivity()
                        onChangedFn(true)
                    }
                }
            }

            Rectangle {
                width: 56 * setTP.uiScale
                height: 28 * setTP.uiScale
                radius: 14 * setTP.uiScale
                color: !enabledValue ? "orange" : "#00000066"
                border.width: 1
                border.color: "#c6c5df"

                Text {
                    anchors.centerIn: parent
                    text: I18n.t(setTP.lang, "settemp.off")
                    color: !enabledValue ? "#000000" : "#c6c5df"
                    font.pixelSize: 14 * setTP.uiScale
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        setTP.noteActivity()
                        onChangedFn(false)
                    }
                }
            }
        }
    }

    Component {
        id: singleContent

        Item {
            anchors.fill: parent
            anchors.margins: 32 * uiScale

            readonly property bool bathEnabled: backend.bath1Enabled

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
                opacity: bathEnabled ? 1.0 : 0.30

                Column {
                    anchors.centerIn: parent
                    spacing: 12 * uiScale

                    Rectangle {
                        width: 120 * uiScale
                        height: 110 * uiScale
                        radius: 22 * uiScale
                        color: singleLockArea.pressed ? "#5a5a5ac4" : "#00000099"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Loader {
                            anchors.centerIn: parent
                            sourceComponent: biIcon
                            onLoaded: {
                                item.code = Qt.binding(function() {
                                    return backend.customerScreenLocked ? "\uF47B" : "\uF600"
                                })
                                item.px = 92 * uiScale
                                item.iconColor = "#EDEFF2"
                            }
                        }

                        MouseArea {
                            id: singleLockArea
                            anchors.fill: parent
                            onClicked: {
                                setTP.noteActivity()
                                backend.lockCustomerScreen()
                            }
                        }
                    }

                    Row {
                        spacing: 8

                        Text {
                            id: currentTempText
                            text: setTP.tempText(setTP.currentTemp, defrost1Active)
                            color: (setTP.isBadNumber(setTP.currentTemp) || defrost1Active) ? "#c6c5df" : (setTP.diff > 5.0 ? "orange" : "#00ff00")
                            font.pixelSize: setTP.tempPx(setTP.currentTemp, 290 * uiScale)
                            font.bold: true
                        }

                        Text {
                            text: defrost1Active ? "" : "°C"
                            color: "#c6c5df"
                            font.pixelSize: 95 * uiScale
                            font.bold: true
                        }
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
                opacity: bathEnabled ? 1.0 : 0.30
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
                opacity: bathEnabled ? 1.0 : 0.30
                enabled: bathEnabled

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
                            enabled: bathEnabled
                            onClicked: {
                                setTP.noteActivity()
                                if (backend.targetTemp < 13.0) backend.targetTemp = backend.targetTemp + 0.5
                            }
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
                            enabled: bathEnabled
                            onClicked: {
                                setTP.noteActivity()
                                if (backend.targetTemp > 0.0) backend.targetTemp = backend.targetTemp - 0.5
                            }
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
                        onClicked: {
                            setTP.noteActivity()
                            setTP.activeTarget = 1
                        }
                        enabled: backend.bath1Enabled
                        z: 0
                    }
// ==========
                    Column {
                        anchors.centerIn: parent
                        spacing: 16 * uiScale
                        z: 1

                        // Bath 1 enable/disable
                        Loader {
                            sourceComponent: bathToggleRow
                            onLoaded: {
                                item.enabledValue = Qt.binding(function() { return backend.bath1Enabled })
                                item.onChangedFn = function(v) { backend.bath1Enabled = v }
                            }
                        }

                        Item {
                            width: 1
                            height: 1
                        }

                        // Content that becomes inactive when bath is OFF
                        Column {
                            id: bath1Content
                            spacing: 40 * uiScale
                            opacity: backend.bath1Enabled ? 1.0 : 0.30
                            enabled: backend.bath1Enabled

                            Item {
                                id: v1Wrap
                                width: target1Box.width
                                height: v1Row.implicitHeight

                                Row {
                                    id: v1Row
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: setTP.tempText(backend.value1, defrost1Active)
                                        color: (setTP.isBadNumber(backend.value1) || defrost1Active) ? "#c6c5df" : (setTP.diff1 > 5.0 ? "orange" : "#00ff00")
                                        font.pixelSize: setTP.tempPx(backend.value1, 200 * uiScale)
                                        font.bold: true
                                    }

                                    Text {
                                        text: defrost1Active ? "" : "°C"
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
                                        enabled: backend.bath1Enabled
                                        onClicked: {
                                            setTP.noteActivity()
                                            setTP.activeTarget = 1
                                        }
                                    }
                                }

                                Text {
                                    text: I18n.t(setTP.lang, "settemp.edit")
                                    visible: setTP.activeTarget === 1
                                    color: "orange"
                                    font.pixelSize: 20 * uiScale
                                    anchors.horizontalCenter: parent.horizontalCenter
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
                                        enabled: (setTP.activeTarget === 1) ? backend.bath1Enabled : backend.bath2Enabled
                                        onClicked: {
                                            setTP.noteActivity()
                                            if (setTP.activeTarget === 1 && backend.targetTemp < 13.0) backend.targetTemp = backend.targetTemp + 0.5
                                            else if (backend.targetTemp2 < 13.0) backend.targetTemp2 = backend.targetTemp2 + 0.5
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
                                        enabled: (setTP.activeTarget === 1) ? backend.bath1Enabled : backend.bath2Enabled
                                        onClicked: {
                                            setTP.noteActivity()
                                            if (setTP.activeTarget === 1 && backend.targetTemp > 0.0) backend.targetTemp = backend.targetTemp - 0.5
                                            else if (backend.targetTemp2 > 0.0) backend.targetTemp2 = backend.targetTemp2 - 0.5
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
                                anchors.centerIn: parent
                                sourceComponent: biIcon
                                onLoaded: {
                                    item.code = Qt.binding(function() {
                                        return backend.customerScreenLocked ? "\uF47B" : "\uF600"
                                    })
                                    item.px = 100 * uiScale
                                    item.iconColor = "#EDEFF2"
                                }
                            }

                            MouseArea {
                                id: lockArea
                                anchors.fill: parent
                                onClicked: {
                                    setTP.noteActivity()
                                    backend.lockCustomerScreen()
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
                        onClicked: {
                            setTP.noteActivity()
                            setTP.activeTarget = 2
                        }
                        enabled: backend.bath2Enabled
                        z: 0
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 16 * uiScale
                        z: 1

                        // Bath 2 enable/disable
                        Loader {
                            sourceComponent: bathToggleRow
                            onLoaded: {
                                item.enabledValue = Qt.binding(function() { return backend.bath2Enabled })
                                item.onChangedFn = function(v) { backend.bath2Enabled = v }
                            }
                        }

                        // Content that becomes inactive when bath is OFF
                        Column {
                            id: bath2Content
                            spacing: 40 * uiScale
                            opacity: backend.bath2Enabled ? 1.0 : 0.30
                            enabled: backend.bath2Enabled

                            Item {
                                id: v2Wrap
                                width: target2Box.width
                                height: v2Row.implicitHeight

                                Row {
                                    id: v2Row
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: setTP.tempText(backend.value2, defrost2Active)
                                        color: (setTP.isBadNumber(backend.value2) || defrost2Active) ? "#c6c5df" : (setTP.diff2 > 5.0 ? "orange" : "#00ff00")
                                        font.pixelSize: setTP.tempPx(backend.value2, 200 * uiScale)
                                        font.bold: true
                                    }

                                    Text {
                                        text: defrost2Active ? "" : "°C"
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
                                    onClicked: {
                                        setTP.noteActivity()
                                        setTP.activeTarget = 2
                                    }
                                }
                            }

                            Text {
                                text: I18n.t(setTP.lang, "settemp.edit")
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
}}
