// SettingsPage.qml
// Full-screen (below TopBar) overlay settings page for scheduled auto-defrost.

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "I18n.js" as I18n

OverlayPage {
    id: page
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"
    title: I18n.t(lang, "settings.title")

    readonly property real s: uiScale
    property var floatEditorRef: null

    property int activeTimeIdx: 1   // 1 or 2
    readonly property int stepMin: 15   // step for adjusting time, in minutes
    property string lockPinDraft: backend && backend.customerLockPin ? backend.customerLockPin : "1234"
    property string lockSaveMessage: ""
    property bool lockPinDialogOpen: false
    property string lockPinEntry: ""
    property string lockPinFirstEntry: ""
    property string lockPinDialogMessage: ""
    property bool lockPinConfirmStep: false

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

    function openLockPinDialog() {
        lockPinDialogOpen = true
        lockPinEntry = ""
        lockPinFirstEntry = ""
        lockPinConfirmStep = false
        lockPinDialogMessage = ""
    }

    function closeLockPinDialog() {
        lockPinDialogOpen = false
        lockPinEntry = ""
        lockPinFirstEntry = ""
        lockPinConfirmStep = false
        lockPinDialogMessage = ""
    }

    function appendLockPinDigit(digit) {
        if (!lockPinDialogOpen || lockPinEntry.length >= 4)
            return
        lockPinEntry += digit
        lockPinDialogMessage = ""
    }

    function removeLockPinDigit() {
        if (!lockPinDialogOpen || lockPinEntry.length === 0)
            return
        lockPinEntry = lockPinEntry.slice(0, lockPinEntry.length - 1)
        lockPinDialogMessage = ""
    }

    function submitLockPinEntry() {
        if (lockPinEntry.length !== 4) {
            lockPinDialogMessage = I18n.t(page.lang, "settings.lock_save_invalid")
            return
        }

        if (!lockPinConfirmStep) {
            lockPinFirstEntry = lockPinEntry
            lockPinEntry = ""
            lockPinConfirmStep = true
            lockPinDialogMessage = ""
            return
        }

        if (lockPinEntry !== lockPinFirstEntry) {
            lockPinEntry = ""
            lockPinFirstEntry = ""
            lockPinConfirmStep = false
            lockPinDialogMessage = I18n.t(page.lang, "settings.lock_pin_mismatch")
            return
        }

        backend.setCustomerLockPin(lockPinEntry)
        page.lockPinDraft = backend.customerLockPin
        page.lockSaveMessage = I18n.t(page.lang, "settings.lock_save_ok")
        closeLockPinDialog()
    }

    Rectangle {
        anchors.fill: parent
        color: "#dd2e2e2e"
        z: -10
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.leftMargin: 14 * s
        anchors.rightMargin: 14 * s
        anchors.bottomMargin: 14 * s
        anchors.topMargin: 14 * s
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
                                text: I18n.t(page.lang, "settings.main")
                                color: "#EDEFF2"
                                font.pixelSize: 32 * s
                                font.bold: true
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }
                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0 }

                            // ON/OFF
                            Row {
                                spacing: 10 * s

                                Rectangle {
                                    width: 156 * s
                                    height: 62 * s
                                    radius: 22 * s
                                    color: backend.autoDefrostEnabled ? "#00ff00" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"

                                    Text {
                                        anchors.centerIn: parent
                                        text: I18n.t(page.lang, "settings.on")
                                        color: backend.autoDefrostEnabled ? "#000000" : "#c6c5df"
                                        font.pixelSize: 26 * s
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: backend.autoDefrostEnabled = true
                                    }
                                }

                                Rectangle {
                                    width: 156 * s
                                    height: 62 * s
                                    radius: 22 * s
                                    color: !backend.autoDefrostEnabled ? "orange" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"

                                    Text {
                                        anchors.centerIn: parent
                                        text: I18n.t(page.lang, "settings.off")
                                        color: !backend.autoDefrostEnabled ? "#000000" : "#c6c5df"
                                        font.pixelSize: 26 * s
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
                                      I18n.t(page.lang, "settings.enabled_desc") :
                                      I18n.t(page.lang, "settings.disabled_desc")
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
                                    text: I18n.t(page.lang, "settings.times")
                                    color: "#EDEFF2"
                                    font.pixelSize: 30 * s
                                    font.bold: true
                                }

                                Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                                // Time 1
                                Rectangle {
                                    width: parent.width
                                    height: 118 * s
                                    radius: 24 * s
                                    color: (activeTimeIdx === 1) ? "#1f3a66" : "#00000099"
                                    border.width: 2 * s
                                    border.color: (activeTimeIdx === 1) ? "orange" : "#c6c5df"
                                    opacity: backend.autoDefrostEnabled ? 1.0 : 0.35

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 14 * s
                                        spacing: 12 * s

                                        Text { text: I18n.t(page.lang, "settings.time1"); color: "#EDEFF2"; font.pixelSize: 24 * s; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                        Item { width: 1; height: 1; }
                                        Text {
                                            text: fmt(backend.autoDefrostTime1Min)
                                            color: "#EDEFF2"
                                            font.pixelSize: 38 * s
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Item { width: 1; Layout.fillWidth: true }
                                        Text {
                                            text: (activeTimeIdx === 1) ? I18n.t(page.lang, "settings.edit") : ""
                                            color: "orange"
                                            font.pixelSize: 20 * uiScale
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
                                    height: 118 * s
                                    radius: 24 * s
                                    color: (activeTimeIdx === 2) ? "#1f3a66" : "#00000099"
                                    border.width: 2 * s
                                    border.color: (activeTimeIdx === 2) ? "orange" : "#c6c5df"
                                    opacity: backend.autoDefrostEnabled ? 1.0 : 0.35

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 14 * s
                                        spacing: 12 * s

                                        Text { text: I18n.t(page.lang, "settings.time2"); color: "#EDEFF2"; font.pixelSize: 24 * s; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                        Item { width: 1; height: 1; }
                                        Text {
                                            text: fmt(backend.autoDefrostTime2Min)
                                            color: "#EDEFF2"
                                            font.pixelSize: 38 * s
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Item { width: 1; Layout.fillWidth: true }
                                        Text {
                                            text: (activeTimeIdx === 2) ? I18n.t(page.lang, "settings.edit") : ""
                                            color: "orange"
                                            font.pixelSize: 20 * uiScale
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
                                        text: backend.autoDefrostEnabled ? I18n.format(page.lang, "settings.step_min", page.stepMin)
                                                                        : I18n.t(page.lang, "settings.auto_off")
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
                height: lockRow.implicitHeight + 28 * s

                Row {
                    id: lockRow
                    anchors.fill: parent
                    anchors.margins: 14 * s
                    spacing: 14 * s

                    Rectangle {
                        width: parent.width * 0.46
                        height: Math.max(320 * s, parent.height - 28 * s)
                        radius: 20 * s
                        color: "#00000044"
                        border.width: 0
                        border.color: "#c6c5df"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12 * s
                            spacing: 15 * s

                            Text {
                                text: I18n.t(page.lang, "settings.lock_title")
                                color: "#EDEFF2"
                                font.pixelSize: 32 * s
                                font.bold: true
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                            Text {
                                text: I18n.t(page.lang, "settings.lock_mode")
                                color: "#EDEFF2"
                                font.pixelSize: 24 * s
                                font.bold: true
                            }

                            Row {
                                spacing: 10 * s

                                Rectangle {
                                    width: 190 * s
                                    height: 62 * s
                                    radius: 22 * s
                                    color: backend.customerAutoLockEnabled ? "#00ff00" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"

                                    Text {
                                        anchors.centerIn: parent
                                        text: I18n.t(page.lang, "settings.lock_auto")
                                        color: backend.customerAutoLockEnabled ? "#000000" : "#c6c5df"
                                        font.pixelSize: 24 * s
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: backend.customerAutoLockEnabled = true
                                    }
                                }

                                Rectangle {
                                    width: 190 * s
                                    height: 62 * s
                                    radius: 22 * s
                                    color: !backend.customerAutoLockEnabled ? "orange" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"

                                    Text {
                                        anchors.centerIn: parent
                                        text: I18n.t(page.lang, "settings.lock_manual")
                                        color: !backend.customerAutoLockEnabled ? "#000000" : "#c6c5df"
                                        font.pixelSize: 24 * s
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: backend.customerAutoLockEnabled = false
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: I18n.t(page.lang, "settings.lock_pin_hint")
                                color: "#c6c5df"
                                font.pixelSize: 18 * s
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width * 0.54 - 14 * s
                        height: Math.max(320 * s, parent.height - 28 * s)
                        radius: 20 * s
                        color: "#00000044"
                        border.width: 0
                        border.color: "#c6c5df"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16 * s
                            spacing: 16 * s

                            Text {
                                text: I18n.t(page.lang, "settings.lock_pin")
                                color: "#EDEFF2"
                                font.pixelSize: 30 * s
                                font.bold: true
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                            Rectangle {
                                width: parent.width
                                height: 84 * s
                                radius: 16 * s
                                color: "#1f3a66"
                                border.width: 2 * s
                                border.color: "#80c6c5df"

                                Text {
                                    anchors.centerIn: parent
                                    text: page.lockPinDraft
                                    color: "#EDEFF2"
                                    font.pixelSize: 34 * s
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                width: 240 * s
                                height: 74 * s
                                radius: 16 * s
                                color: saveLockPinArea.pressed ? "#1f3a66" : "#00000099"
                                border.width: 2 * s
                                border.color: "#c6c5df"

                                Text {
                                    anchors.centerIn: parent
                                    text: I18n.t(page.lang, "settings.lock_save")
                                    color: "#EDEFF2"
                                    font.pixelSize: 22 * s
                                    font.bold: true
                                }

                                MouseArea {
                                    id: saveLockPinArea
                                    anchors.fill: parent
                                    onClicked: page.openLockPinDialog()
                                }
                            }

                            Text {
                                width: parent.width
                                text: page.lockSaveMessage
                                visible: text.length > 0
                                wrapMode: Text.WordWrap
                                color: text === I18n.t(page.lang, "settings.lock_save_ok") ? "#9BE39B" : "#FF7B7B"
                                font.pixelSize: 18 * s
                            }
                        }
                    }
                }
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
                    text: I18n.t(page.lang, "settings.confirm_title")
                    color: "#EDEFF2"
                    font.pixelSize: 24 * s
                    font.bold: true
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#EDEFF2"
                    font.pixelSize: 22 * s
                    text: I18n.t(page.lang, "settings.confirm_body")
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

                        Text { anchors.centerIn: parent; text: I18n.t(page.lang, "common.cancel"); color: "#EDEFF2"; font.pixelSize: 20 * s; font.bold: true }
                        MouseArea { id: cancelArea; anchors.fill: parent; onClicked: confirmOff.visible = false }
                    }

                    Rectangle {
                        width: 160 * s
                        height: 64 * s
                        radius: 18 * s
                        color: okArea.pressed ? "#5a5a5ac4" : "#00000099"
                        border.width: 2 * s
                        border.color: "#c6c5df"

                        Text { anchors.centerIn: parent; text: I18n.t(page.lang, "common.ok"); color: "#EDEFF2"; font.pixelSize: 20 * s; font.bold: true }
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

    Item {
        anchors.fill: parent
        visible: page.lockPinDialogOpen
        z: 10000

        Rectangle {
            anchors.fill: parent
            color: "#bb000000"
        }

        Rectangle {
            width: Math.min(parent.width * 0.72, 680 * s)
            height: 590 * s
            anchors.centerIn: parent
            radius: 22 * s
            color: "#1b1b1b"
            border.width: 2 * s
            border.color: "#c6c5df"

            Column {
                anchors.fill: parent
                anchors.margins: 22 * s
                spacing: 14 * s

                Text {
                    width: parent.width
                    text: page.lockPinConfirmStep ? I18n.t(page.lang, "settings.lock_repeat_pin")
                                                  : I18n.t(page.lang, "settings.lock_new_pin")
                    color: "#EDEFF2"
                    font.pixelSize: 28 * s
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: parent.width
                    height: 72 * s
                    radius: 18 * s
                    color: "#0E1116"
                    border.width: 2 * s
                    border.color: page.lockPinDialogMessage.length > 0 ? "#C84C4C" : "#EDEFF2"

                    Text {
                        anchors.centerIn: parent
                        text: page.lockPinEntry
                        color: "#EDEFF2"
                        font.pixelSize: 34 * s
                        font.bold: true
                    }
                }

                Text {
                    width: parent.width
                    text: page.lockPinDialogMessage
                    visible: text.length > 0
                    color: "#FF7B7B"
                    font.pixelSize: 18 * s
                    horizontalAlignment: Text.AlignHCenter
                }

                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 3
                    rowSpacing: 12 * s
                    columnSpacing: 12 * s

                    Repeater {
                        model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "\u232B", "0", "OK"]

                        delegate: Rectangle {
                            width: 160 * s
                            height: 72 * s
                            radius: 20 * s
                            color: keypadArea.pressed ? "#ccEDEFF2" : "#F6F7F9"
                            border.width: 2 * s
                            border.color: "#EDEFF2"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#171A20"
                                font.pixelSize: modelData === "\u232B" ? 28 * s : 34 * s
                                font.bold: true
                            }

                            MouseArea {
                                id: keypadArea
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData === "\u232B")
                                        page.removeLockPinDigit()
                                    else if (modelData === "OK")
                                        page.submitLockPinEntry()
                                    else
                                        page.appendLockPinDigit(modelData)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: 180 * s
                    height: 44 * s
                    radius: 18 * s
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: cancelLockPinArea.pressed ? "#5a5a5ac4" : "orange"
                    border.width: 2 * s
                    border.color: "#c6c5df"

                    Text {
                        anchors.centerIn: parent
                        text: I18n.t(page.lang, "common.cancel")
                        color: "#2e2e2e"
                        font.pixelSize: 20 * s
                        font.bold: true
                    }

                    MouseArea {
                        id: cancelLockPinArea
                        anchors.fill: parent
                        onClicked: page.closeLockPinDialog()
                    }
                }
            }
        }
    }
}
