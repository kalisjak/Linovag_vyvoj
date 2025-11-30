import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Item {
    id: osk

    // --- pozice a rozměry ---

    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined
    width: parent ? parent.width : 800

    // výška max ~ půlka okna
    height: parent ? parent.height * 0.5 : 240

    // vysouvání odspodu podle exposedHeight
    y: parent ? parent.height - exposedHeight : 0
    z: 2000

    // API pro App.qml
    property bool show: false
    property real exposedHeight: show ? height : 0
    Behavior on exposedHeight {
        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
    }

    // cílové pole, na které píšeme
    property var target: null    // sem nastavíš TextField / TextArea zvenku

    // režimy
    property bool numericMode: false
    property int  shiftState: 0      // 0=off, 1=once, 2=locked (caps)
    property bool shift: shiftState > 0

    // rozložení kláves TODO: NEKOMPLETNÍ
    property var lettersRow1: [ "q","w","e","r","t","y","u","i","o","p" ]
    property var lettersRow2: [ "a","s","d","f","g","h","j","k","l" ]
    property var lettersRow3: [ "z","x","c","v","b","n","m" ]

    property var numsRow1:   [ "1","2","3","4","5","6","7","8","9","0" ]
    property var numsRow2:   [ "-","/",":",";","(",")","€","&","@","#" ]
    property var numsRow3:   [ ".","_",",","?","!","\"","'" ]

    // --- veřejné funkce ---

    function hide() {
        show = false
    }

    function showFor(field) {
        // můžeš volat zvenku: osk.showFor(input)
        target = field
        show = true
        if (target) target.forceActiveFocus()
    }

    // pomocná funkce: vrátí skutečný editovatelný objekt (TextInput/TextArea)
    function editObject() {
        var t = target
        if (!t) return null

        // když je to TextField z Controls 2 – má contentItem (TextInput)
        if (t.contentItem && t.contentItem.text !== undefined)
            return t.contentItem

        // TextInput / TextArea
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
        // jednorázový shift spadne po prvním znaku
        if (!numericMode && shiftState === 1)
            shiftState = 0
    }

    function doEnter() {
    // pokud je aktivní plovoucí editor, potvrď ho
    if (floatEditor && floatEditor.active) {
        floatEditor.accept()
    } else {
        commitText("\n")
    }
}

    // --- pozadí panelu ---

    Rectangle {
        anchors.fill: parent
        color: "#202020"
        border.color: "#505050"
        radius: 10
        opacity: exposedHeight > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // --- layout kláves ---

    ColumnLayout {
        id: layoutRoot
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // PÍSMENA – 1. řádek
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: !osk.numericMode

            Repeater {
                model: osk.lettersRow1.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText  = osk.lettersRow1[index]
                        item.keyType  = "char"
                        item.isLetter = true
                    }
                }
            }
        }

        // PÍSMENA – 2. řádek
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: !osk.numericMode

            Repeater {
                model: osk.lettersRow2.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText  = osk.lettersRow2[index]
                        item.keyType  = "char"
                        item.isLetter = true
                    }
                }
            }
        }

        // PÍSMENA – 3. řádek (SHIFT + písmena + BKSP)
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: !osk.numericMode

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType  = "shift"
                    item.keyText  = "⇧"
                    item.wide     = true
                    item.accent   = true
                }
            }

            Repeater {
                model: osk.lettersRow3.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText  = osk.lettersRow3[index]
                        item.keyType  = "char"
                        item.isLetter = true
                    }
                }
            }

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType  = "backspace"
                    item.keyText  = "⌫"
                    item.wide     = true
                    item.accent   = true
                }
            }
        }

        // PÍSMENA – spodní řádek
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: !osk.numericMode

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "mode"
                    item.keyText = "123"
                    item.wide    = true
                }
            }

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType   = "space"
                    item.keyText   = "Space"
                    item.extraWide = true
                }
            }

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType  = "enter"
                    item.keyText  = "⏎"
                    item.wide     = true
                    item.accent   = true
                }
            }

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "hide"
                    item.keyText = "▾"
                    item.wide    = true
                }
            }
        }

        // ČÍSLA – 1. řádek
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: osk.numericMode

            Repeater {
                model: osk.numsRow1.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText = osk.numsRow1[index]
                        item.keyType = "char"
                    }
                }
            }
        }

        // ČÍSLA – 2. řádek
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: osk.numericMode

            Repeater {
                model: osk.numsRow2.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText = osk.numsRow2[index]
                        item.keyType = "char"
                    }
                }
            }
        }

        // ČÍSLA – 3. řádek
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: osk.numericMode

            Repeater {
                model: osk.numsRow3.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: {
                        item.keyText = osk.numsRow3[index]
                        item.keyType = "char"
                    }
                }
            }

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType  = "backspace"
                    item.keyText  = "⌫"
                    item.wide     = true
                    item.accent   = true
                }
            }
        }

        // ČÍSLA – spodní řádek
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: osk.numericMode

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "mode"
                    item.keyText = "ABC"
                    item.wide    = true
                }
            }

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType   = "space"
                    item.keyText   = "Space"
                    item.extraWide = true
                }
            }

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType  = "enter"
                    item.keyText  = "⏎"
                    item.wide     = true
                    item.accent   = true
                }
            }

            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.keyType = "hide"
                    item.keyText = "▾"
                    item.wide    = true
                }
            }
        }
    }

    // --- šablona klávesy ---

    Component {
        id: keyButton

        Rectangle {
            id: keyRect

            property string keyText: ""
            property string keyType: "char"   // char/shift/backspace/mode/space/enter/hide
            property bool   isLetter: false
            property bool   wide: false
            property bool   extraWide: false
            property bool   accent: false

            implicitWidth: 54
            implicitHeight: 46
            radius: 8

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: extraWide ? implicitWidth * 3
                                             : (wide ? implicitWidth * 1.5 : implicitWidth)

            color: {
                var base = accent ? "#d0d0d0" : "#f5f5f5"
                if (keyRect.keyType === "shift" && osk.shift)
                    base = "#c0c0c0"
                return base
            }
            border.color: "#a0a0a0"

            Text {
                anchors.centerIn: parent
                font.pixelSize: 18
                text: {
                    var t = keyRect.keyText
                    if (keyRect.keyType === "mode")
                        t = osk.numericMode ? "ABC" : "123"
                    if (keyRect.isLetter) {
                        t = osk.shift ? t.toUpperCase() : t.toLowerCase()
                    }
                    return t
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (keyRect.keyType === "shift") {
                        if (osk.shiftState === 0)       osk.shiftState = 1
                        else if (osk.shiftState === 1)  osk.shiftState = 2
                        else                            osk.shiftState = 0
                        return
                    }
                    if (keyRect.keyType === "mode") {
                        osk.numericMode = !osk.numericMode
                        osk.shiftState = 0
                        return
                    }
                    if (keyRect.keyType === "hide") {
                        osk.hide()
                        return
                    }

                    // ostatní klávesy už potřebují target
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
