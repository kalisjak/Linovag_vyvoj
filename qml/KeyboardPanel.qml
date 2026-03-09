import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Item {
    id: osk
    property real uiScale: 1.0
    readonly property real edgeInset: 6

    width: parent ? (parent.width - (2 * edgeInset)) : 800 * uiScale
    height: parent ? parent.height * 0.66 : 320 * uiScale

    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined
    anchors.leftMargin: parent ? edgeInset : 0
    anchors.rightMargin: parent ? edgeInset : 0

    y: parent ? parent.height - exposedHeight : 0
    z: 200

    property bool show: false
    property real exposedHeight: show ? height : 0
    Behavior on exposedHeight {
        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
    }

    property var target: null

    property bool numericMode: false
    property int symbolPage: 0        // 0=123 set, 1=#+= set
    property bool localeMode: false   // special chars for CZ/DE/DK

    property int shiftState: 0        // 0=off, 1=once, 2=locked
    property bool shift: shiftState > 0

    property var lettersBaseRow1: [ "q","w","e","r","t","y","u","i","o","p" ]
    property var lettersBaseRow2: [ "a","s","d","f","g","h","j","k","l" ]
    property var lettersBaseRow3: [ "z","x","c","v","b","n","m" ]

    property var lettersLocaleRow1: [ "á","č","ď","é","ě","í","ň","ó","ř","š" ]
    property var lettersLocaleRow2: [ "ť","ú","ů","ý","ž","ä","ö","ü","æ","ø" ]
    property var lettersLocaleRow3: [ "å","ß","à","è","ì","ò","ù" ]

    property var numsRow1Page0: [ "1","2","3","4","5","6","7","8","9","0" ]
    property var numsRow2Page0: [ "-","_","@",".",",",":",";","/","?","!" ]
    property var numsRow3Page0: [ "'","\"","(",")","[","]","{","}" ]

    property var numsRow1Page1: [ "#","$","%","&","*","+","=","<",">","|" ]
    property var numsRow2Page1: [ "\\","^","~","`","€","£","§","°","¤","_" ]
    property var numsRow3Page1: [ "!","?","/",":",";","@",",","." ]

    function activeLettersRow1() { return localeMode ? lettersLocaleRow1 : lettersBaseRow1 }
    function activeLettersRow2() { return localeMode ? lettersLocaleRow2 : lettersBaseRow2 }
    function activeLettersRow3() { return localeMode ? lettersLocaleRow3 : lettersBaseRow3 }

    function activeNumsRow1() { return symbolPage === 0 ? numsRow1Page0 : numsRow1Page1 }
    function activeNumsRow2() { return symbolPage === 0 ? numsRow2Page0 : numsRow2Page1 }
    function activeNumsRow3() { return symbolPage === 0 ? numsRow3Page0 : numsRow3Page1 }

    function hide() {
        show = false
    }

    function showFor(field) {
        target = field
        show = true
        if (target) target.forceActiveFocus()
    }

    function editObject() {
        var t = target
        if (!t) return null

        if (t.contentItem && t.contentItem.text !== undefined)
            return t.contentItem

        if (t.text !== undefined)
            return t

        return null
    }

    function insertText(s) {
        var e = editObject()
        if (!e) return

        var txt = e.text || ""
        var pos = (e.cursorPosition !== undefined) ? e.cursorPosition : txt.length

        e.text = txt.slice(0, pos) + s + txt.slice(pos)
        if (e.cursorPosition !== undefined)
            e.cursorPosition = pos + s.length
    }

    function backspace() {
        var e = editObject()
        if (!e) return

        var txt = e.text || ""
        var pos = (e.cursorPosition !== undefined) ? e.cursorPosition : txt.length

        if (pos <= 0 || txt.length === 0)
            return

        e.text = txt.slice(0, pos - 1) + txt.slice(pos)
        if (e.cursorPosition !== undefined)
            e.cursorPosition = pos - 1
    }

    function commitText(s) {
        insertText(s)
        if (!numericMode && shiftState === 1)
            shiftState = 0
    }

    function doEnter() {
        if (floatEditor && floatEditor.active) {
            floatEditor.accept()
        } else {
            commitText("\n")
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#1C1C1C"
        border.color: "#4A4A4A"
        radius: 8
        opacity: exposedHeight > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    ColumnLayout {
        id: layoutRoot
        anchors.fill: parent
        anchors.margins: 6
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: !osk.numericMode

            Repeater {
                model: osk.activeLettersRow1()
                delegate: Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1.0
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText = modelData
                        item.keyType = "char"
                        item.isLetter = true
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: !osk.numericMode

            Repeater {
                model: osk.activeLettersRow2()
                delegate: Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1.0
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText = modelData
                        item.keyType = "char"
                        item.isLetter = true
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: !osk.numericMode

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.7
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "shift"
                    item.keyText = "⇧"
                    item.wide = true
                    item.accent = true
                }
            }

            Repeater {
                model: osk.activeLettersRow3()
                delegate: Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1.0
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText = modelData
                        item.keyType = "char"
                        item.isLetter = true
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.9
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "backspace"
                    item.keyText = "⌫"
                    item.wide = true
                    item.accent = true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: !osk.numericMode

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.7
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "mode"
                    item.keyText = "123"
                    item.wide = true
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.5
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "locale"
                    item.keyText = "äø"
                    item.wide = true
                    item.accent = true
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 4.8
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "space"
                    item.keyText = "Space"
                    item.extraWide = true
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.8
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "enter"
                    item.keyText = "⏎"
                    item.wide = true
                    item.accent = true
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.5
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "hide"
                    item.keyText = "▾"
                    item.wide = true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: osk.numericMode

            Repeater {
                model: osk.activeNumsRow1()
                delegate: Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1.0
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText = modelData
                        item.keyType = "char"
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: osk.numericMode

            Repeater {
                model: osk.activeNumsRow2()
                delegate: Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1.0
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText = modelData
                        item.keyType = "char"
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: osk.numericMode

            Repeater {
                model: osk.activeNumsRow3()
                delegate: Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1.0
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText = modelData
                        item.keyType = "char"
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.9
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "backspace"
                    item.keyText = "⌫"
                    item.wide = true
                    item.accent = true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: osk.numericMode

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.7
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "mode"
                    item.keyText = "ABC"
                    item.wide = true
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 4.8
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "space"
                    item.keyText = "Space"
                    item.extraWide = true
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.8
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "enter"
                    item.keyText = "⏎"
                    item.wide = true
                    item.accent = true
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.5
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "hide"
                    item.keyText = "▾"
                    item.wide = true
                }
            }
        }
    }

    Component {
        id: keyButton

        Rectangle {
            id: keyRect

            property string keyText: ""
            property string keyType: "char"
            property bool isLetter: false
            property bool wide: false
            property bool extraWide: false
            property bool accent: false

            implicitWidth: 56
            implicitHeight: 58
            radius: keyType === "space" ? 16 : (accent ? 12 : 8)

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 1
            Layout.preferredWidth: extraWide ? implicitWidth * 3.4
                                             : (wide ? implicitWidth * 1.7 : implicitWidth)

            color: {
                var utility = keyRect.keyType === "shift"
                           || keyRect.keyType === "locale"
                           || keyRect.keyType === "mode"
                           || keyRect.keyType === "enter"
                           || keyRect.keyType === "backspace"
                var base = utility ? "#313131" : "#414141"
                return base
            }
            border.color: "#A7A7A7"
            border.width: 1

            Text {
                anchors.centerIn: parent
                font.pixelSize: 34
                font.bold: true
                color: "#FFFFFF"
                style: Text.Outline
                styleColor: "#202020"
                text: {
                    var t = keyRect.keyText
                    if (keyRect.keyType === "space")
                        t = "space"
                    if (keyRect.keyType === "shift")
                        t = (osk.shiftState === 2) ? "⬆" : "⇧"
                    if (keyRect.keyType === "mode") {
                        if (!osk.numericMode) t = "123"
                        else if (osk.symbolPage === 0) t = "#+="
                        else t = "ABC"
                    }
                    if (keyRect.keyType === "locale")
                        t = osk.localeMode ? "abc" : "äø"
                    if (keyRect.isLetter)
                        t = osk.shift ? t.toUpperCase() : t.toLowerCase()
                    return t
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (keyRect.keyType === "shift") {
                        if (osk.shiftState === 0) osk.shiftState = 1
                        else if (osk.shiftState === 1) osk.shiftState = 2
                        else osk.shiftState = 0
                        return
                    }
                    if (keyRect.keyType === "mode") {
                        if (!osk.numericMode) {
                            osk.numericMode = true
                            osk.symbolPage = 0
                        } else if (osk.symbolPage === 0) {
                            osk.symbolPage = 1
                        } else {
                            osk.numericMode = false
                            osk.symbolPage = 0
                        }
                        osk.shiftState = 0
                        return
                    }
                    if (keyRect.keyType === "locale") {
                        osk.localeMode = !osk.localeMode
                        osk.shiftState = 0
                        return
                    }
                    if (keyRect.keyType === "hide") {
                        osk.hide()
                        return
                    }

                    if (!osk.target)
                        return

                    osk.target.forceActiveFocus()

                    if (keyRect.keyType === "backspace") {
                        osk.backspace()
                    } else if (keyRect.keyType === "space") {
                        osk.commitText(" ")
                    } else if (keyRect.keyType === "enter") {
                        osk.doEnter()
                    } else if (keyRect.keyType === "char") {
                        var ch = keyRect.keyText
                        if (keyRect.isLetter && osk.shift)
                            ch = ch.toUpperCase()
                        osk.commitText(ch)
                    }
                }
            }
        }
    }
}
