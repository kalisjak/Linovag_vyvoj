// KeyboardPanel.qml (v1.2 – sjednocené anchors + animace bottomMargin)
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Item {
    id: kb
    width: parent ? parent.width : 800
    height: parent ? parent.height * 0.5 : 240
    z: 2000

    // ✨ Nové: viditelná výška panelu (0…height)
    property real exposedHeight: show ? height : 0
    Behavior on exposedHeight { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

    // místo anchors.bottomMargin animujeme prostě y podle exposedHeight
    anchors.left:   parent ? parent.left   : undefined
    anchors.right:  parent ? parent.right  : undefined
    y: parent ? parent.height - exposedHeight : 0

    // panel je pořád "visible", jen mění výšku (y)
    visible: true

    Rectangle { anchors.fill: parent; color: bgColor }

    // --- API / téma ---
    property bool  forceVisible: false
    property color bgColor: "#161616EE"
    property color keyBg:  "#2A2A2A"
    property color keyBgAlt: "#333333"
    property color keyFg:  "#EDEFF2"
    property color keyStroke: "#444444"
    property color accent: "#4A90E2"

    // --- stav ---
    property bool numericMode: false
    property var  _target: null
    property bool _hasEditableFocus: _target !== null
    property bool show: forceVisible || _hasEditableFocus
    // SHIFT režim: 0=off, 1=once (po jednom znaku spadne), 2=locked (caps)
    property int  shiftState: 0
    property bool shift: shiftState > 0  // z toho se dál počítají řádky písmen

    // --- sledování focusu a režimu ABC/123 ---
    property var  _lastFocused: null       // paměť posledního focusu
    property bool manualMode: false        // když uživatel přepne 123/ABC ručně

    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            function findEditable(obj) {
                if (!obj) return null
                if (typeof obj.insert === "function") return obj     // TextInput / TextArea
                if (obj.contentItem && typeof obj.contentItem.insert === "function")
                    return obj.contentItem                           // TextField.contentItem
                return null
            }
            function getHints(obj) {
                // vezmi hints z vlastníku pole (TextField) i z contentItem
                var h = 0
                if (obj && obj.inputMethodHints !== undefined) h |= obj.inputMethodHints
                if (obj && obj.parent && obj.parent.inputMethodHints !== undefined) h |= obj.parent.inputMethodHints
                return h
            }

            var f = (win && win.activeFocusItem) ? win.activeFocusItem : null
            var t = findEditable(f)

            // když máme nový cíl, znovu rozhodni počáteční režim
            if (t !== kb._target) {
                kb._target = t
                kb._lastFocused = t
                kb.manualMode = false   // reset uživatelského přepnutí na novém poli

                // POZOR: automatický numeric jen jako výchozí,
                // a jen pokud to dává smysl podle hints
                var imh = getHints(t)
                var wantNums = !!(imh & (Qt.ImhDigitsOnly | Qt.ImhFormattedNumbersOnly | Qt.ImhPreferNumbers))
                kb.numericMode = wantNums
            }

            // pokud dočasně není focus (klik na klávesu), drž poslední známý target
            // if (!kb._target && kb._lastFocused) kb._target = kb._lastFocused
        }
    }

    function insertAtCursor(s) {
        if (!kb._target) return
        var t = kb._target
        var pos = (t.cursorPosition !== undefined) ? t.cursorPosition : 0

        if (typeof t.insert === "function") {
            // preferulní podpis insert(position, text); fallback na insert(text)
            try {
                if (t.insert.length >= 2) t.insert(pos, s)
                else                      t.insert(s)
            } catch (e) {
                // nouzový ruční update textu
                var txt = t.text || ""
                t.text = txt.slice(0, pos) + s + txt.slice(pos)
            }
        } else {
            var txt2 = t.text || ""
            t.text = txt2.slice(0, pos) + s + txt2.slice(pos)
        }

        if (t.cursorPosition !== undefined)
            t.cursorPosition = pos + s.length
    }

    function commitText(s) {
        insertAtCursor(s)
        // Když je SHIFT jen jednorázový (1), po napsání znaku spadne zpět
        if (!numericMode && kb.shiftState === 1)
            kb.shiftState = 0
    }

    function doEnter() {
        if (!kb._target) return
        var t = kb._target

        // 1) pokud pole má accepted(), použij ho (TextField enter)
        if (typeof t.accepted === "function") {
            t.accepted()
            return
        }
        // 2) jinak newline do multiline
        if (t.wrapMode !== undefined && t.wrapMode !== TextInput.NoWrap) {
            insertAtCursor("\n")
            return
        }
        // 3) fallback – prostě „potvrď“ přes parent, pokud má accepted
        if (t.parent && typeof t.parent.accepted === "function") {
            t.parent.accepted()
        }
    }

    function doBackspace() {
        if (!_target) return
        if (typeof _target.backspace === "function") _target.backspace()
        else {
            var pos = _target.cursorPosition || 0
            if (pos > 0) {
                var txt = _target.text || ""
                _target.text = txt.slice(0, pos-1) + txt.slice(pos)
                _target.cursorPosition = pos - 1
            }
        }
    }

    function hide() {
        kb.forceVisible = false
        kb.shift = false
        kb.manualMode = false
        kb._target = null
        // zajisti, že nikdo nezůstane ve focusu
        if (win && win.activeFocusItem) win.activeFocusItem.focus = false
    }
    
    // Šablona klávesy
    Component {
        id: keyButton
        Rectangle {
            id: key
            implicitWidth: 54
            implicitHeight: 46
            radius: 8
            color: keyBg
            border.color: keyStroke

            property string label: ""
            property string send: ""
            property bool   wide: false
            property bool   xwide: false
            property bool   accentKey: false

            width: xwide ? 200 : (wide ? 100 : implicitWidth)

            Text {
                anchors.centerIn: parent
                text: key.label
                color: key.accentKey ? accent : keyFg
                font.pixelSize: 18
                renderType: Text.NativeRendering
            }

            Timer {
                id: repeatTimer
                interval: 70
                repeat: true
                onTriggered: { if (key.send === "__BKSP") kb.doBackspace() }
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true         // nenech klávesu „ukrást“ focus poli
                hoverEnabled: false
                propagateComposedEvents: false

                onPressed: {
                    // vizuální stisk
                    key.color = keyBgAlt

                    // udrž fokus v cílovém poli, aby _target zůstal platný
                    if (kb._target) kb._target.forceActiveFocus()

                    // Backspace: první smazání hned + nastartuj opakování
                    if (key.send === "__BKSP") {
                        kb.doBackspace()
                        repeatTimer.start()
                    }
                }

                onReleased: {
                    key.color = keyBg
                    repeatTimer.stop()
                }

                onCanceled: {
                    key.color = keyBg
                    repeatTimer.stop()
                }

                onClicked: {
                    // po kliknutí znovu vrať fokus do aktivního pole
                    if (kb._target) kb._target.forceActiveFocus()

                    // akce podle typu klávesy
                    if (key.send === "__SHIFT")  {
                        if      (kb.shiftState === 0) kb.shiftState = 1;   // první tap: jednorázově
                        else if (kb.shiftState === 1) kb.shiftState = 2;   // druhý tap: zamknout (caps)
                        else                          kb.shiftState = 0;   // třetí tap: vypnout
                    }
                    else if (key.send === "__BKSP")   { /* řeší pressed/repeat */ }
                    else if (key.send === "__ENTER")  { kb.doEnter() }
                    else if (key.send === "__SPACE")  { kb.commitText(" ") }
                    else if (key.send === "__HIDE")   { kb.hide() }
                    else if (key.send === "__MODE")   { kb.numericMode = !kb.numericMode; kb.manualMode = true }
                    else                               { kb.commitText(key.send) }
                }
            }
        }
    }

    // Rozložení kláves
    property var row1: shift ? ["Q","W","E","R","T","Y","U","I","O","P"]
                             : ["q","w","e","r","t","y","u","i","o","p"]
    property var row2: shift ? ["A","S","D","F","G","H","J","K","L"]
                             : ["a","s","d","f","g","h","j","k","l"]
    property var row3: shift ? ["Z","X","C","V","B","N","M"]
                             : ["z","x","c","v","b","n","m"]

    property var nums1: ["1","2","3","4","5","6","7","8","9","0"]
    property var nums2: ["-","/",";",":","(",")","€","&","@","\""]
    property var nums3: [".",",","?","!","'"]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // --- Písmena ---
        Item { Layout.fillWidth: true; height: 0; visible: !kb.numericMode }

        RowLayout {
            spacing: 6; visible: !kb.numericMode
            Repeater {
                model: kb.row1.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: { item.send = kb.row1[index]; item.label = kb.row1[index] }
                }
            }
        }

        RowLayout {
            spacing: 6; visible: !kb.numericMode
            Item { Layout.preferredWidth: 16; Layout.fillHeight: true }
            Repeater {
                model: kb.row2.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: { item.send = kb.row2[index]; item.label = kb.row2[index] }
                }
            }
        }

        RowLayout {
            spacing: 6; visible: !kb.numericMode
            // Loader { sourceComponent: keyButton; onLoaded: { item.send="__SHIFT"; item.label="⇧"; item.wide=true; item.accentKey=true } }
            Loader {
                sourceComponent: keyButton
                onLoaded: {
                    item.send = "__SHIFT"
                    item.wide = true
                    // label se mění podle stavu: ⇧ (momentary) / ⇪ (locked)
                    item.label = Qt.binding(function() { return kb.shiftState === 2 ? "⇪" : "⇧" })
                    // zvýraznění, když je shift aktivní (1 i 2)
                    item.accentKey = Qt.binding(function() { return kb.shift })
                }
            }
            Repeater {
                model: kb.row3.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: { item.send = kb.row3[index]; item.label = kb.row3[index] }
                }
            }
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__BKSP"; item.label="⌫"; item.wide=true; item.accentKey=true } }
        }

        RowLayout {
            spacing: 6; visible: !kb.numericMode
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__MODE";  item.label="123";   item.wide=true } }
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__SPACE"; item.label="Space"; item.xwide=true } }
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__ENTER"; item.label="⏎";     item.wide=true; item.accentKey=true } }
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__HIDE";  item.label="▾";     item.wide=true } }
        }

        // --- Numeric ---
        RowLayout {
            spacing: 6; visible: kb.numericMode
            Repeater {
                model: kb.nums1.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: { item.send = kb.nums1[index]; item.label = kb.nums1[index] }
                }
            }
        }
        RowLayout {
            spacing: 6; visible: kb.numericMode
            Repeater {
                model: kb.nums2.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: { item.send = kb.nums2[index]; item.label = kb.nums2[index] }
                }
            }
        }
        RowLayout {
            spacing: 6; visible: kb.numericMode
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__MODE"; item.label="ABC"; item.wide=true; item.accentKey=true } }
            Repeater {
                model: kb.nums3.length
                delegate: Loader {
                    sourceComponent: keyButton
                    onLoaded: { item.send = kb.nums3[index]; item.label = kb.nums3[index] }
                }
            }
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__BKSP"; item.label="⌫"; item.wide=true; item.accentKey=true } }
        }

        RowLayout {
            spacing: 6; visible: kb.numericMode
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__SPACE"; item.label="Space"; item.xwide=true } }
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__ENTER"; item.label="⏎";     item.wide=true; item.accentKey=true } }
            Loader { sourceComponent: keyButton; onLoaded: { item.send="__HIDE";  item.label="▾";     item.wide=true } }
        }
    }
}
