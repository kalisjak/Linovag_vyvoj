import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "I18n.js" as I18n

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

    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"
    readonly property int publicPageCount: 5
    readonly property int firstServicePageIndex: 5
    readonly property int setTempPageIndex: 1
    readonly property bool customerScreenLocked: backend ? backend.customerScreenLocked : false
    readonly property bool serviceModeEnabled: backend ? backend.serviceModeEnabled : false
    property bool serviceUnlockOpen: false
    property bool customerUnlockOpen: false
    property string customerPinEntry: ""
    property string customerUnlockError: ""

    function openOverlayPage(source, title, extraProps) {
        var props = { pageStack: overlay, floatEditorRef: floatEditor }
        if (extraProps) {
            for (var key in extraProps)
                props[key] = extraProps[key]
        }
        if (overlay.depth > 0)
            overlay.clear()
        overlay.push(Qt.resolvedUrl(source), props)
        topbar.overlayMode = true
        topbar.overlayTitle = title
    }

    function canAutoLockCustomer() {
        return !!backend
            && backend.customerAutoLockEnabled
            && !backend.customerScreenLocked
            && !serviceUnlockOpen
            && !customerUnlockOpen
            && overlay.depth === 0
            && pages.currentIndex === setTempPageIndex
    }

    function resetCustomerAutoLock() {
        customerAutoLockTimer.stop()
        if (canAutoLockCustomer())
            customerAutoLockTimer.restart()
    }

    function openCustomerUnlock() {
        if (!customerScreenLocked)
            return
        customerPinEntry = ""
        customerUnlockError = ""
        customerUnlockOpen = true
        customerUnlockTimeout.restart()
    }

    function closeCustomerUnlock() {
        customerUnlockOpen = false
        customerPinEntry = ""
        customerUnlockError = ""
        customerUnlockTimeout.stop()
    }

    function appendCustomerPinDigit(digit) {
        if (!customerUnlockOpen || customerPinEntry.length >= 4)
            return

        customerPinEntry += digit
        customerUnlockError = ""
        customerUnlockTimeout.restart()

        if (customerPinEntry.length !== 4)
            return

        if (backend && backend.unlockCustomerScreen(customerPinEntry)) {
            closeCustomerUnlock()
            resetCustomerAutoLock()
            return
        }

        customerPinEntry = ""
        customerUnlockError = I18n.t(lang, "custlock.invalid_pin")
    }

    function removeCustomerPinDigit() {
        if (!customerUnlockOpen || customerPinEntry.length === 0)
            return
        customerPinEntry = customerPinEntry.slice(0, customerPinEntry.length - 1)
        customerUnlockError = ""
        customerUnlockTimeout.restart()
    }

    function openServiceUnlock() {
        if (serviceModeEnabled) {
            pages.currentIndex = firstServicePageIndex
            return
        }
        servicePinField.text = ""
        serviceUnlockError.text = ""
        serviceUnlockOpen = true
        if (floatEditor.active)
            floatEditor.close()
        resetCustomerAutoLock()
    }

    function closeServiceUnlock() {
        serviceUnlockOpen = false
        servicePinField.text = ""
        serviceUnlockError.text = ""
        if (floatEditor.active)
            floatEditor.close()
        resetCustomerAutoLock()
    }

    function submitServiceUnlock() {
        if (!backend)
            return
        if (backend.unlockServiceMode(servicePinField.text)) {
            closeServiceUnlock()
            pages.currentIndex = firstServicePageIndex
            return
        }
        serviceUnlockError.text = I18n.t(lang, "service.invalid_pin")
        if (floatEditor.active)
            floatEditor.close()
    }

    // Bootstrap Icons font
    FontLoader {
        id: biFont
        source: "qrc:/qml/fonts/bootstrap-icons.ttf"
    }
    property string biFamily: biFont.name
    readonly property string biWrench2: "\uF000"
    readonly property string biWrench3: "\uF001"

    Component {
        id: biIcon
        Text {
            property string code: ""
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

// ============= otočení celé scény pro RPI ==========
    
    property bool rotateScene: true

// =============================================================================

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
            uiScale: win.uiScale
            z: 10
            width: parent.width
            anchors.top: parent.top

            onOpenWifi: {
                win.openOverlayPage("WifiPage.qml", I18n.t(win.lang, "overlay.wifi"))
            }
            onOpenSettings: {
                win.openOverlayPage("SettingsPage.qml", I18n.t(win.lang, "overlay.settings"))
            }
            onOpenLogin: {
                win.openOverlayPage("PersonPage.qml", I18n.t(win.lang, "overlay.person"))
            }
            onNavigateBack: {
                if (overlay.depth > 1) overlay.pop()
                else if (overlay.depth === 1) overlay.clear()
            }
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
            interactive: !serviceUnlockOpen && !win.customerScreenLocked
            clip: true
            onCurrentIndexChanged: {
                if (!win.serviceModeEnabled && currentIndex >= win.publicPageCount)
                    currentIndex = win.publicPageCount - 1
                if (win.customerScreenLocked && currentIndex !== win.setTempPageIndex)
                    currentIndex = win.setTempPageIndex
                win.resetCustomerAutoLock()
            }

            HomePage {
                uiScale: win.uiScale
                onServiceRequested: win.openServiceUnlock()
                onPersonRequested: win.openOverlayPage("PersonPage.qml", I18n.t(win.lang, "overlay.person"))
                onSettingsRequested: win.openOverlayPage("SettingsPage.qml", I18n.t(win.lang, "overlay.settings"))
                onWarningRequested: win.openOverlayPage("WarningPage.qml", "Varování")
            }
            SetTempPage {
                uiScale: win.uiScale
                onUserActivity: win.resetCustomerAutoLock()
            }  // index 1
            HistPage { uiScale: win.uiScale }     // index 2
            QrPage   { uiScale: win.uiScale }     // index 3
            ReclaimPage { uiScale: win.uiScale }  // index 4
            TestPage { uiScale: win.uiScale }     // index 5
            SensorConfigPage { }    // index 6
            // TempPage {  }     // index 7
        }

        // Spodní "dock" s tečkami a domečkem
        DockNav {
            id: dock
            uiScale: win.uiScale
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10 // + osk.exposedHeight
            count: win.serviceModeEnabled ? pages.count : win.publicPageCount
            currentIndex: pages.currentIndex
            enabled: !win.customerScreenLocked
            onGoHome: pages.currentIndex = 0
            onDotClicked: function(i) { pages.currentIndex = i }
        }

        Connections {
            target: backend
            ignoreUnknownSignals: true
            function onCustomerScreenLockChanged() {
                if (backend.customerScreenLocked) {
                    pages.currentIndex = win.setTempPageIndex
                    win.closeCustomerUnlock()
                    return
                }
                win.resetCustomerAutoLock()
            }
            function onCustomerLockConfigChanged() {
                win.resetCustomerAutoLock()
            }
            function onServiceModeEnabledChanged() {
                if (!backend.serviceModeEnabled && pages.currentIndex >= win.publicPageCount)
                    pages.currentIndex = 0
            }
        }

        // --- ROUTER pro overlay stránky (Wifi/Settings/Person) ---
        StackView {
            id: overlay
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: topbar.bottom
            z: 50
            initialItem: null

            visible: depth > 0
            enabled: depth > 0
            focus: depth > 0

            onDepthChanged: {
                if (depth <= 0) {
                    topbar.overlayMode = false
                    topbar.overlayTitle = ""
                    win.resetCustomerAutoLock()
                    return
                }
                topbar.overlayMode = true
                if (currentItem && currentItem.title !== undefined) topbar.overlayTitle = currentItem.title
                win.resetCustomerAutoLock()
            }
        }

        Connections {
            target: overlay.currentItem
            ignoreUnknownSignals: true
            function onTitleChanged() {
                if (overlay.depth > 0 && overlay.currentItem && overlay.currentItem.title !== undefined)
                    topbar.overlayTitle = overlay.currentItem.title
            }
        }

        KeyboardPanel {
            id: osk
            uiScale: win.uiScale
            z: 240
        }

        Timer {
            id: customerAutoLockTimer
            interval: 30000
            repeat: false
            onTriggered: {
                if (win.canAutoLockCustomer())
                    backend.lockCustomerScreen()
            }
        }

        Timer {
            id: customerUnlockTimeout
            interval: 6000
            repeat: false
            onTriggered: win.closeCustomerUnlock()
        }

        Rectangle {
            anchors.fill: parent
            z: 225
            visible: win.customerScreenLocked && pages.currentIndex === win.setTempPageIndex
            color: win.customerUnlockOpen ? "#C8000000" : "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!win.customerUnlockOpen)
                        win.openCustomerUnlock()
                    else
                        customerUnlockTimeout.restart()
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 22 * win.uiScale
                visible: !win.customerUnlockOpen

                Loader {
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: biIcon
                    onLoaded: {
                        item.code = "\uF47B"
                        item.px = 250 * win.uiScale
                        item.iconColor = "#88272727"
                    }
                }

                // Text {
                //     text: I18n.t(win.lang, "custlock.tap_to_unlock")
                //     color: "#55272727"
                //     font.pixelSize: 28 * win.uiScale
                //     font.bold: true
                //     horizontalAlignment: Text.AlignHCenter
                // }
            }

            Rectangle {
                width: Math.min(parent.width * 0.54, 620 * win.uiScale)
                height: 600 * win.uiScale
                anchors.centerIn: parent
                radius: 26 * win.uiScale
                color: "#171A20"
                border.width: 2 * win.uiScale
                border.color: "#EDEFF2"
                visible: win.customerUnlockOpen

                Column {
                    anchors.fill: parent
                    anchors.margins: 28 * win.uiScale
                    spacing: 18 * win.uiScale

                    Text {
                        width: parent.width
                        text: I18n.t(win.lang, "custlock.enter_pin")
                        color: "#EDEFF2"
                        font.pixelSize: 28 * win.uiScale
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        width: parent.width
                        height: 72 * win.uiScale
                        radius: 18 * win.uiScale
                        color: "#0E1116"
                        border.width: 2 * win.uiScale
                        border.color: win.customerUnlockError.length > 0 ? "#C84C4C" : "#EDEFF2"

                        Text {
                            anchors.centerIn: parent
                            text: win.customerPinEntry
                            color: "#EDEFF2"
                            font.pixelSize: 34 * win.uiScale
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                win.customerPinEntry = ""
                                win.customerUnlockError = ""
                                customerUnlockTimeout.restart()
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: win.customerUnlockError
                        visible: text.length > 0
                        color: "#FF7B7B"
                        font.pixelSize: 18 * win.uiScale
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Grid {
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 3
                        rowSpacing: 14 * win.uiScale
                        columnSpacing: 14 * win.uiScale

                        Repeater {
                            model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "\u232B", "0", ""]

                            delegate: Item {
                                width: 150 * win.uiScale
                                height: 82 * win.uiScale

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20 * win.uiScale
                                    visible: modelData !== ""
                                    color: digitArea.pressed ? "#E6E8EB" : "#F6F7F9"
                                    border.width: 2 * win.uiScale
                                    border.color: "#EDEFF2"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "#171A20"
                                        font.pixelSize: modelData === "\u232B" ? 28 * win.uiScale : 34 * win.uiScale
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: digitArea
                                        anchors.fill: parent
                                        onClicked: {
                                            if (modelData === "\u232B")
                                                win.removeCustomerPinDigit()
                                            else
                                                win.appendCustomerPinDigit(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            z: 230
            visible: win.serviceUnlockOpen
            color: "#C0000000"

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            Rectangle {
                width: Math.min(parent.width * 0.72, 760 * win.uiScale)
                height: 420 * win.uiScale
                anchors.centerIn: parent
                radius: 28 * win.uiScale
                color: "#171A20"
                border.width: 2 * win.uiScale
                border.color: "#EDEFF2"

                Column {
                    anchors.fill: parent
                    anchors.margins: 34 * win.uiScale
                    spacing: 24 * win.uiScale

                    Text {
                        text: I18n.t(win.lang, "service.title")
                        color: "#EDEFF2"
                        font.pixelSize: 34 * win.uiScale
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    Text {
                        text: I18n.t(win.lang, "service.warning")
                        color: "#EDEFF2"
                        font.pixelSize: 24 * win.uiScale
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    Text {
                        text: I18n.t(win.lang, "service.prompt")
                        color: "#C9CDD3"
                        font.pixelSize: 20 * win.uiScale
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    TextField {
                        id: servicePinField
                        width: parent.width
                        height: 68 * win.uiScale
                        color: "#EDEFF2"
                        placeholderText: I18n.t(win.lang, "service.placeholder")
                        placeholderTextColor: "#7F8895"
                        echoMode: TextInput.Password
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 28 * win.uiScale
                        inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        validator: RegularExpressionValidator { regularExpression: /[0-9]*/ }
                        readOnly: true
                        background: Rectangle {
                            radius: 18 * win.uiScale
                            color: "#0E1116"
                            border.width: 2 * win.uiScale
                            border.color: serviceUnlockError.text.length > 0 ? "#C84C4C" : "#EDEFF2"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: floatEditor.openFor(servicePinField)
                        }
                    }

                    Text {
                        id: serviceUnlockError
                        text: ""
                        color: "#FF7B7B"
                        font.pixelSize: 18 * win.uiScale
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                        visible: text.length > 0
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 18 * win.uiScale

                        Rectangle {
                            width: 210 * win.uiScale
                            height: 62 * win.uiScale
                            radius: 18 * win.uiScale
                            color: cancelServiceArea.pressed ? "#E6E8EB" : "#F6F7F9"
                            border.width: 2 * win.uiScale
                            border.color: "#EDEFF2"

                            Text {
                                anchors.centerIn: parent
                                text: I18n.t(win.lang, "common.cancel")
                                color: "#171A20"
                                font.pixelSize: 20 * win.uiScale
                                font.bold: true
                            }

                            MouseArea {
                                id: cancelServiceArea
                                anchors.fill: parent
                                onClicked: win.closeServiceUnlock()
                            }
                        }

                        Rectangle {
                            width: 210 * win.uiScale
                            height: 62 * win.uiScale
                            radius: 18 * win.uiScale
                            color: unlockServiceArea.pressed ? "#E6E8EB" : "#F6F7F9"
                            border.width: 2 * win.uiScale
                            border.color: "#EDEFF2"

                            Text {
                                anchors.centerIn: parent
                                text: I18n.t(win.lang, "service.unlock")
                                color: "#171A20"
                                font.pixelSize: 20 * win.uiScale
                                font.bold: true
                            }

                            MouseArea {
                                id: unlockServiceArea
                                anchors.fill: parent
                                onClicked: win.submitServiceUnlock()
                            }
                        }
                    }
                }
            }
        }

    Item {
        id: floatEditor
        anchors.fill: parent
        visible: active
        z: 250

        property bool active: false
        property var sourceField   // původní TextField / TextArea
        property bool sourceIsPassword: false

        function openFor(field) {
            sourceField = field
            sourceIsPassword = !!(field && field.echoMode !== undefined && field.echoMode === TextInput.Password)

            // načteme aktuální text
            if (field) {
                if (field.text !== undefined)
                    edit.text = field.text
                else if (field.contentItem && field.contentItem.text !== undefined)
                    edit.text = field.contentItem.text
            }

            edit.echoMode = sourceIsPassword ? TextInput.Password : TextInput.Normal

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
            sourceIsPassword = false
            edit.echoMode = TextInput.Normal
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

        // horní třetina (mimo klávesnici) je lehce ztmavená,
        // aby pozadí nerušilo, ale zůstalo rozeznatelné
        Rectangle {
            x: 0
            y: 0
            width: parent.width
            height: Math.max(0, parent.height - osk.exposedHeight)
            color: "#99000000"
            z: 0
        }

        // samotný panel s textovým polem
        Rectangle {
            id: panel
            width: parent.width * 0.84
            height: 120
            radius: 10
            color: "#333333"
            border.color: "#888888"
            z: 1

            anchors.horizontalCenter: parent.horizontalCenter
            // pozice: mezi horním okrajem a začátkem klávesnice
            y: {
                var keyboardTop = parent.height - osk.exposedHeight
                var topSpace = Math.max(0, keyboardTop)
                return Math.max(8, (topSpace - height) / 2)
            }

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
