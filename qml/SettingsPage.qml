// SettingsPage.qml
// Full-screen (below TopBar) overlay settings page for scheduled auto-defrost.

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

OverlayPage {
    id: page
    title: "Nastavení"

    readonly property real s: uiScale

    property int activeTimeIdx: 1   // 1 or 2
    readonly property int stepMin: 15   // step for adjusting time, in minutes

    function clampMin(v) {
        var m = Math.round(v / stepMin) * stepMin
        while (m < 0) m += 1440
        while (m >= 1440) m -= 1440
        return m
    }

    function fmt(mins) {
        var h = Math.floor(mins / 60)
        var m = mins % 60
        var hs = (h < 10 ? "0" : "") + h
        var ms = (m < 10 ? "0" : "") + m
        return hs + ":" + ms
    }

    function currentMin(idx) {
        return idx === 1 ? backend.autoDefrostTime1Min : backend.autoDefrostTime2Min
    }

    function setCurrentMin(idx, mins) {
        mins = clampMin(mins)
        if (idx === 1) backend.autoDefrostTime1Min = mins
        else backend.autoDefrostTime2Min = mins
    }

    function adjust(deltaMin) {
        setCurrentMin(activeTimeIdx, currentMin(activeTimeIdx) + deltaMin)
    }

    // ---------------- DIM + SCROLLABLE CONTENT ----------------
    // Dim overlay: cover whole screen, but keep the RIGHT part of TopBar visible/active.
    // Adjust keep width if your TopBar right area is larger/smaller.
    readonly property real topBarH: 70 * s
    readonly property real topBarRightKeepW: 900 * s

    Rectangle {
        // TopBar area - only LEFT part is dimmed
        x: 0
        y: 0
        width: Math.max(0, parent.width - topBarRightKeepW)
        height: topBarH - 3
        color: "#882e2e2e"
        z: -10
    }

    Rectangle {
        // Everything below TopBar is dimmed fully
        x: 0
        y: topBarH
        width: parent.width
        height: Math.max(0, parent.height - topBarH)
        color: "#dd2e2e2e"
        z: -10
    }

    // left overlay "header" (sits where TopBar is on the left)
    // If StackView area is already below TopBar, this may render partly above;
    // that's intentional per request.
    Rectangle {
        id: topLeftOverlay
        x: 0
        y: 0
        width: 520 * s
        height: topBarH -5
        radius: 0
        color: "#00000066"
        z: 50

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14 * s
            anchors.rightMargin: 14 * s
            spacing: 25 * s

            Rectangle {
                width: 110 * s
                height: 46 * s
                radius: 14 * s
                color: backArea.pressed ? "#5a5a5ac4" : "#bb000000"
                border.width: 2 * s
                border.color: "#c6c5df"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "← Zpět"
                    color: "#EDEFF2"
                    font.pixelSize: 20 * s
                    font.bold: true
                }
                MouseArea { id: backArea; anchors.fill: parent; onClicked: page.goBack() }
            }

            Text {
                text: "Nastavení"
                color: "#EDEFF2"
                font.pixelSize: 26 * s
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.leftMargin: 14 * s
        anchors.rightMargin: 14 * s
        anchors.bottomMargin: 14 * s
        anchors.topMargin: topBarH + (14 * s)
        clip: true
        contentWidth: contentItem.width
        contentHeight: contentCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Column {
            id: contentCol
            width: flick.width
            spacing: 14 * s

            // Main card
            Rectangle {
                width: parent.width -20 * s
                radius: 20 * s
                color: "#cc2e2e2e"
                border.width: 1 * s
                border.color: "#ccc6c5df"
                height: mainRow.implicitHeight + 28 * s

                Row {
                    id: mainRow
                    anchors.fill: parent
                    anchors.margins: 14 * s
                    spacing: 14 * s

                    // ---------------- LEFT COLUMN ----------------
                    Rectangle {
                        width: parent.width * 0.46
                        height: Math.max(420 * s, parent.height - 28 * s)
                        radius: 20 * s
                        color: "#00000044"
                        border.width: 0 * s
                        border.color: "#c6c5df"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12 * s
                            spacing: 15 * s

                            Text {
                                text: "Nastavení automatického\nčasového odtávání"
                                color: "#EDEFF2"
                                font.pixelSize: 24 * s
                                font.bold: true
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }
                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0 }

                            // ON/OFF
                            Row {
                                spacing: 10 * s

                                Rectangle {
                                    width: 120 * s
                                    height: 46 * s
                                    radius: 18 * s
                                    color: backend.autoDefrostEnabled ? "#00ff00" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "ZAP"
                                        color: backend.autoDefrostEnabled ? "#000000" : "#c6c5df"
                                        font.pixelSize: 20 * s
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: backend.autoDefrostEnabled = true
                                    }
                                }

                                Rectangle {
                                    width: 120 * s
                                    height: 46 * s
                                    radius: 18 * s
                                    color: !backend.autoDefrostEnabled ? "orange" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "VYP"
                                        color: !backend.autoDefrostEnabled ? "#000000" : "#c6c5df"
                                        font.pixelSize: 20 * s
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (backend.autoDefrostEnabled) confirmOff.visible = true
                                            else backend.autoDefrostEnabled = false
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: backend.autoDefrostEnabled ?
                                      "Funkce je zapnutá. Defrost se spustí v nastavených časech pouze pokud zařízení běží alespoň 4 hodiny a poslední defrost byl min. 4 hodiny zpět." :
                                      "Funkce je vypnutá."
                                color: backend.autoDefrostEnabled ? "#c6c5df" : "#666666"
                                font.pixelSize: 16 * s
                            }
                        }
                    }

                    // ---------------- RIGHT COLUMN ----------------
                    Rectangle {
                        width: parent.width * 0.54 - 14 * s
                        height: Math.max(420 * s, parent.height - 28 * s)
                        radius: 20 * s
                        color: "#00000044"
                        border.width: 0 * s
                        border.color: "#c6c5df"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 16 * s
                            spacing: 70 * s

                            // Times list
                            Column {
                                width: parent.width * 0.64
                                spacing: 16 * s

                                Text {
                                    text: "Časy automatického\nodtávání"
                                    color: "#EDEFF2"
                                    font.pixelSize: 22 * s
                                    font.bold: true
                                }

                                Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                                // Time 1
                                Rectangle {
                                    width: parent.width
                                    height: 96 * s
                                    radius: 20 * s
                                    color: (activeTimeIdx === 1) ? "#1f3a66" : "#00000099"
                                    border.width: 2 * s
                                    border.color: (activeTimeIdx === 1) ? "orange" : "#c6c5df"
                                    opacity: backend.autoDefrostEnabled ? 1.0 : 0.35

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 14 * s
                                        spacing: 12 * s

                                        Text { text: "Čas 1"; color: "#EDEFF2"; font.pixelSize: 20 * s; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                        Item { width: 1; height: 1; }
                                        Text {
                                            text: fmt(backend.autoDefrostTime1Min)
                                            color: "#EDEFF2"
                                            font.pixelSize: 30 * s
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Item { width: 1; Layout.fillWidth: true }
                                        Text {
                                            text: (activeTimeIdx === 1) ? "EDIT" : ""
                                            color: "orange"
                                            font.pixelSize: 16 * uiScale
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: backend.autoDefrostEnabled
                                        onClicked: activeTimeIdx = 1
                                    }
                                }

                                // Time 2
                                Rectangle {
                                    width: parent.width
                                    height: 96 * s
                                    radius: 20 * s
                                    color: (activeTimeIdx === 2) ? "#1f3a66" : "#00000099"
                                    border.width: 2 * s
                                    border.color: (activeTimeIdx === 2) ? "orange" : "#c6c5df"
                                    opacity: backend.autoDefrostEnabled ? 1.0 : 0.35

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 14 * s
                                        spacing: 12 * s

                                        Text { text: "Čas 2"; color: "#EDEFF2"; font.pixelSize: 20 * s; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                        Item { width: 1; height: 1; }
                                        Text {
                                            text: fmt(backend.autoDefrostTime2Min)
                                            color: "#EDEFF2"
                                            font.pixelSize: 30 * s
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Item { width: 1; Layout.fillWidth: true }
                                        Text {
                                            text: (activeTimeIdx === 2) ? "EDIT" : ""
                                            color: "orange"
                                            font.pixelSize: 16 * uiScale
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: backend.autoDefrostEnabled
                                        onClicked: activeTimeIdx = 2
                                    }
                                }
                            }

                            // Shared arrows
                            Rectangle {
                                id: arrowsPane
                                width: parent.width * 0.25
                                height: parent.height
                                radius: 20 * s
                                color: "#00000044"
                                border.width: 0 * s
                                border.color: "#c6c5df"

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 18 * s

                                    Rectangle {
                                        width: 120 * s
                                        height: 120 * s
                                        radius: 26 * s
                                        color: upArea.pressed ? "#5a5a5ac4" : "#00000099"
                                        opacity: backend.autoDefrostEnabled ? 1.0 : 0.35
                                        border.width: 2 * s
                                        border.color: "#c6c5df"

                                        Text { anchors.centerIn: parent; text: "▲"; color: "#EDEFF2"; font.pixelSize: 60 * s; font.bold: true }
                                        MouseArea {
                                            id: upArea
                                            anchors.fill: parent
                                            enabled: backend.autoDefrostEnabled
                                            onClicked: page.adjust(-page.stepMin)
                                        }
                                    }

                                    Text {
                                        text: backend.autoDefrostEnabled ? ("krok " + page.stepMin + " min") : "AUTO OFF"
                                        color: backend.autoDefrostEnabled ? "#c6c5df" : "#666666"
                                        font.pixelSize: 18 * s
                                        horizontalAlignment: Text.AlignHCenter
                                        width: parent.width
                                    }

                                    Rectangle {
                                        width: 120 * s
                                        height: 120 * s
                                        radius: 26 * s
                                        color: downArea.pressed ? "#5a5a5ac4" : "#00000099"
                                        opacity: backend.autoDefrostEnabled ? 1.0 : 0.35
                                        border.width: 2 * s
                                        border.color: "#c6c5df"

                                        Text { anchors.centerIn: parent; text: "▼"; color: "#EDEFF2"; font.pixelSize: 60 * s; font.bold: true }
                                        MouseArea {
                                            id: downArea
                                            anchors.fill: parent
                                            enabled: backend.autoDefrostEnabled
                                            onClicked: page.adjust(+page.stepMin)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            
            Rectangle {
                width: parent.width - 20 * s
                radius: 20 * s
                color: "#cc2e2e2e"
                border.width: 1 * s
                border.color: "#ccc6c5df"
                height: mainRow.implicitHeight + 28 * s
            }
            // spacer bottom (so it feels scrollable even on small screens)
            Item { width: 1; height: 30 * s }
        }
    }

    Item {
        id: confirmOff
        anchors.fill: parent
        visible: false
        z: 9999

        Rectangle {
            anchors.fill: parent
            color: "#000000aa"
        }

        Rectangle {
            id: dialogCard
            width: Math.min(parent.width * 0.8, 700 * s)
            height: 310 * s
            anchors.centerIn: parent
            radius: 22 * s
            color: "#1b1b1b"
            border.width: 2 * s
            border.color: "#c6c5df"

            Column {
                anchors.fill: parent
                anchors.margins: 20 * s
                spacing: 24 * s

                Text {
                    text: "Vypnout auto odtávání?"
                    color: "#EDEFF2"
                    font.pixelSize: 24 * s
                    font.bold: true
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#EDEFF2"
                    font.pixelSize: 22 * s
                    text: "Pokud časový defrost vypneš, zařízení nemusí správně fungovat a může zamrznout výparník.\n\nOpravdu chceš pokračovat?"
                }

                Rectangle {
                    width: parent.width - 20
                    height: 1 * s
                    color: "#00000000"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Row {
                    spacing: 310 * s
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: 160 * s
                        height: 64 * s
                        radius: 18 * s
                        color: cancelArea.pressed ? "#5a5a5ac4" : "#00000099"
                        border.width: 2 * s
                        border.color: "#c6c5df"

                        Text { anchors.centerIn: parent; text: "Zrušit"; color: "#EDEFF2"; font.pixelSize: 20 * s; font.bold: true }
                        MouseArea { id: cancelArea; anchors.fill: parent; onClicked: confirmOff.visible = false }
                    }

                    Rectangle {
                        width: 160 * s
                        height: 64 * s
                        radius: 18 * s
                        color: okArea.pressed ? "#5a5a5ac4" : "#00000099"
                        border.width: 2 * s
                        border.color: "#c6c5df"

                        Text { anchors.centerIn: parent; text: "OK"; color: "#EDEFF2"; font.pixelSize: 20 * s; font.bold: true }
                        MouseArea {
                            id: okArea
                            anchors.fill: parent
                            onClicked: {
                                backend.autoDefrostEnabled = false
                                confirmOff.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
