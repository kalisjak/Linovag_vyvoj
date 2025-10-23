import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: win
    width: 800
    height: 480
    visible: true
    title: "Linovag"
    flags: Qt.FramelessWindowHint
    color: "black"
    Component.onCompleted: win.contentItem.focus = true

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
    property bool rotateScene: true


    // --- KOŘEN PRO CELOU SCÉNU (rotovatelný) ---
    Item {
        id: rot
        width: rotateScene ? win.height : win.width
        height: rotateScene ? win.width  : win.height

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

            HomePage { }
            TempPage { }     // index 1
            QrPage   { }     // index 2
            bottomPadding: osk.exposedHeight
        }

        // Spodní "dock" s tečkami a domečkem
        DockNav {
            id: dock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10 + osk.exposedHeight
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

        // Component.onCompleted: {
        //     onCurrentIndexChanged: console.log("pages idx ->", pages.currentIndex)
        // }

        KeyboardPanel {
            id: osk
            z: 30
        }

        MouseArea {
            anchors.fill: parent
            z: osk.z - 1           // pod klávesnicí, nad obsahem
            enabled: osk.show
            hoverEnabled: false
            onClicked: {
                if (win.activeFocusItem) win.activeFocusItem.focus = false
                osk.hide()
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