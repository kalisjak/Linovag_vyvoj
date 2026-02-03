import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: win
    width: 1280 // 800
    height: 720 // 480
    visible: true
    title: "Linovag"
    flags: Qt.FramelessWindowHint
    color: "black"
    Component.onCompleted: win.contentItem.focus = true

    // --- škálování vůči návrhovému rozlišení ---
    readonly property int designWidth: 1280
    readonly property int designHeight: 720

    // jednotný scale (1.0 = původní vzhled pro 1280x720)
    // property real uiScale: 2.0
    property real uiScale: Math.min(width / designWidth,
                                    height / designHeight)

    // Bootstrap Icons font
    FontLoader {
        id: biFont
        source: "qrc:/qml/fonts/bootstrap-icons.ttf"
    }
    property string biFamily: biFont.name

    // Jednoduchý ikonový "label"
    Component {
        id: biIcon
        Text {
            // vstupy
            property string code: ""            // např. "\uF61C" (wifi)
            property color  iconColor: "#EDEFF2"
            property int    px: 20

            text: code
            font.family: biFamily
            font.pixelSize: px
            color: iconColor
            renderType: Text.NativeRendering
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }


    // --- volitelné otočení celé scény (ponechám pro RPi orientaci) ---
    property bool rotateScene: false


    // --- KOŘEN PRO CELOU SCÉNU (rotovatelný) ---
    Item {
        id: rot
        width: rotateScene ? win.height : win.width
        height: rotateScene ? win.width  : win.height

        // transformOrigin: Item.BottomRight
        // x: 0
        // y: rotateScene ? win.height : 0
        // rotation: rotateScene ? 270 : 0

        x: rotateScene ? win.width : 0
        y: 0
        rotation: rotateScene ? 90 : 0
        transformOrigin: Item.TopLeft

        Image {
            id: bg
            anchors.fill: parent
            source: "qrc:/qml/plocha_tmava.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            z: 0
        }

        TopBar {
            id: topbar
            uiScale: win.uiScale
            z: 10
            width: parent.width
            anchors.top: parent.top

            // signály z TopBaru – otevře overlay stránky
            onOpenWifi:     overlay.push(Qt.resolvedUrl("WifiPage.qml"),     { pageStack: overlay })
            onOpenSettings: overlay.push(Qt.resolvedUrl("SettingsPage.qml"), { pageStack: overlay })
            onOpenLogin:    overlay.push(Qt.resolvedUrl("LoginPage.qml"),    { pageStack: overlay })
        }

        // Hlavní "plovoucí" stránkování
        SwipeView {
            id: pages
            z: 5
            anchors {
                top: topbar.bottom
                left: parent.left
                right: parent.right
                bottom: dock.top
            }
            interactive: true
            clip: true

            HomePage   { uiScale: win.uiScale }
            SetTempPage { uiScale: win.uiScale }  // index 1
            HistPage { uiScale: win.uiScale }     // index 2
            QrPage   { uiScale: win.uiScale }     // index 3
            ReclaimPage { uiScale: win.uiScale }  // index 4
            TestPage { uiScale: win.uiScale }     // index 5
            // TempPage {  }     // index 6
        }

        // Spodní "dock" s tečkami a domečkem
        DockNav {
            id: dock
            uiScale: win.uiScale
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10 // + osk.exposedHeight
            count: pages.count
            currentIndex: pages.currentIndex
            onGoHome: pages.currentIndex = 0
            onDotClicked: function(i) { pages.currentIndex = i }
        }

        // --- ROUTER pro overlay stránky (Wifi/Settings/Login) ---
        StackView {
            id: overlay
            anchors.fill: parent
            z: 50
            initialItem: null

            visible: depth > 0
            enabled: depth > 0
            focus: depth > 0
        }

        KeyboardPanel {
            id: osk
            uiScale: win.uiScale
            z: 30
        }

    Item {
        id: floatEditor
        anchors.fill: parent
        visible: active
        z: 250

        property bool active: false
        property var sourceField   // původní TextField / TextArea

        function openFor(field) {
            sourceField = field

            // načteme aktuální text
            if (field) {
                if (field.text !== undefined)
                    edit.text = field.text
                else if (field.contentItem && field.contentItem.text !== undefined)
                    edit.text = field.contentItem.text
            }

            active = true
            osk.showFor(edit)      // klávesnice píše do plovoucího pole
            edit.forceActiveFocus()
        }

        function accept() {
            // ořízneme případné \n na konci (Enter z OSK)
            var t = edit.text
            if (t.length > 0 && t.charAt(t.length-1) === "\n")
                t = t.slice(0, t.length-1)

            if (sourceField) {
                if (sourceField.text !== undefined)
                    sourceField.text = t
                else if (sourceField.contentItem && sourceField.contentItem.text !== undefined)
                    sourceField.contentItem.text = t
            }
            close()
        }

        function close() {
            active = false
            osk.target = null
            osk.hide()
        }

        // MouseArea přes celou obrazovku:
        // klik MIMO panel a MIMO klávesnici -> accept()
        MouseArea {
            id: overlayCatcher
            anchors.fill: parent
            z: 0
            propagateComposedEvents: true

            onClicked: {
                var keyboardTop = height - osk.exposedHeight

                var inPanel = mouse.x >= panel.x && mouse.x <= panel.x + panel.width &&
                              mouse.y >= panel.y && mouse.y <= panel.y + panel.height

                var inKeyboard = mouse.y >= keyboardTop

                if (!inPanel && !inKeyboard) {
                    floatEditor.accept()
                } else {
                    mouse.accepted = false    // pusť event dál (panel / klávesnice)
                }
            }
        }

        // jen vizuální zatemnění, bez MouseArea
        Rectangle {
            anchors.fill: parent
            color: "#00000080"
            z: 0
        }

        // samotný panel s textovým polem
        Rectangle {
            id: panel
            width: parent.width * 0.9
            height: 120
            radius: 10
            color: "#333333"
            border.color: "#888888"
            z: 1

            anchors.horizontalCenter: parent.horizontalCenter
            // pozice: kousek nad klávesnicí – bez anchoru na osk.top!
            y: parent.height - osk.exposedHeight - height - 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                TextField {
                    id: edit
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Zadej text…"
                    color: "white"
                    placeholderTextColor: "#CCCCCC"
                    property bool isFloatingEditor: true

                    background: Rectangle {
                        color: "#000000"
                        opacity: 0.3
                        radius: 6
                        border.color: "#FFFFFF40"
                    }

                    // Enter / šipka dolů z HW klávesnice -> potvrdit
                    Keys.onReturnPressed: floatEditor.accept()
                    Keys.onDownPressed: floatEditor.accept()

                    // Enter z OSK:
                    // OSK vloží "\n", to tady odchytíme, smažeme a potvrdíme
                    onTextChanged: {
                        if (isFloatingEditor && text.length > 0 &&
                            text.charAt(text.length-1) === "\n") {
                            text = text.slice(0, text.length-1)
                            floatEditor.accept()
                        }
                    }
                }
            }
        }
    }

        // --- SPLASH OVERLAY (3 s logo přes celou obrazovku) ---
        Item {
            id: splash
            anchors.fill: parent
            z: 999
            visible: true
            opacity: 1.0

            Rectangle { anchors.fill: parent; color: "black" }
            Image {
                anchors.fill: parent
                source: "qrc:/qml/logo.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Timer {
                id: splashTimer
                interval: 1000
                running: true
                repeat: false
                onTriggered: fadeOut.start()
            }
            SequentialAnimation {
                id: fadeOut
                PropertyAnimation { target: splash; property: "opacity"; to: 0.0; duration: 400; easing.type: Easing.InOutQuad }
                ScriptAction { script: splash.visible = false }
                ScriptAction { script: pages.currentIndex = 0 }
            }
        }
}
}