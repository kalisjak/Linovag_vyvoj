import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

OverlayPage {
    id: wifi
    title: "Wi-Fi"
    readonly property real s: uiScale

    // reference from App.qml (overlay.push props)
    property var floatEditorRef: null

    property var wifiNetworks: []

    property int selectedIndex: wifiNetworks.length > 0 ? 0 : -1
    readonly property var selectedNetwork: (selectedIndex >= 0 && selectedIndex < wifiNetworks.length) ? wifiNetworks[selectedIndex] : null
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"

    property string uiStatusText: ""
    property bool credentialDialogVisible: false
    property bool credentialNeedsUsername: false
    property bool credentialNeedsPassword: true
    property string pendingSsid: ""
    property bool busyConnecting: false
    property string pendingConnectSsid: ""
    property string pendingConnectUser: ""
    property string pendingConnectPass: ""
    property bool pendingConnectEnterprise: false
    property bool showLargeStatus: false
    property bool initialScanDone: false
    property bool refreshInProgress: false

    function tt(cs, en, de, dk) {
        switch (lang) {
        case "en": return en
        case "de": return de
        case "dk": return dk
        default: return cs
        }
    }

    function searchingNetworksLabel() {
        switch (lang) {
        case "en": return "Searching available networks…"
        case "de": return "Suche verfügbare Netzwerke…"
        case "dk": return "Søger efter tilgængelige netværk…"
        default: return "Vyhledávám dostupné sítě…"
        }
    }

    function openKeyboardFor(field) {
        if (floatEditorRef && floatEditorRef.openFor) {
            floatEditorRef.openFor(field)
            return
        }
        if (typeof floatEditor !== "undefined" && floatEditor.openFor) {
            floatEditor.openFor(field)
        }
    }

    function clearStatusMessage() {
        largeStatusHideTimer.stop()
        showLargeStatus = false
        uiStatusText = ""
    }

    function needsCredential(net) {
        if (!net) return false
        if (net.requiresUsernamePassword) return true
        return net.requiresPassword && !net.saved
    }

    function credentialHint(net) {
        if (!net) return "-"
        if (net.requiresUsernamePassword) return tt("Vyžaduje username + password", "Requires username + password",
                                                    "Benutzername + Passwort erforderlich", "Kræver brugernavn + adgangskode")
        if (net.requiresPassword) return net.saved ? tt("Heslo uloženo", "Password saved", "Passwort gespeichert", "Adgangskode gemt")
                                                  : tt("Vyžaduje heslo", "Password required", "Passwort erforderlich", "Adgangskode kræves")
        return tt("Bez hesla", "No password", "Kein Passwort", "Ingen adgangskode")
    }

    function statusLabel(net) {
        if (!net) return "-"
        if (pendingConnectSsid !== "" && net.ssid === pendingConnectSsid) {
            return tt("Připojuji…", "Connecting…", "Verbinde…", "Forbinder…")
        }
        switch (net.statusKey) {
        case "connected":
            return tt("Připojeno", "Connected", "Verbunden", "Forbundet")
        case "available":
            return tt("Dostupná", "Available", "Verfügbar", "Tilgængelig")
        case "enterprise":
            return tt("Vyžaduje username + password", "Requires username + password",
                      "Benutzername + Passwort erforderlich", "Kræver brugernavn + adgangskode")
        case "open":
            return tt("Nezabezpečená", "Open", "Offen", "Åben")
        default:
            return "-"
        }
    }

    function triggerConnectFlow() {
        if (!selectedNetwork) return
        clearStatusMessage()

        if (needsCredential(selectedNetwork)) {
            pendingSsid = selectedNetwork.ssid
            credentialNeedsUsername = !!selectedNetwork.requiresUsernamePassword
            credentialNeedsPassword = !!selectedNetwork.requiresPassword
            userField.text = ""
            passField.text = ""
            credentialDialogVisible = true
            return
        }

        doConnect(selectedNetwork.ssid, "", "", !!selectedNetwork.requiresUsernamePassword)
    }

    function refreshNetworks(forceRescan) {
        if (refreshInProgress) return
        if (!forceRescan && (flick.dragging || flick.flicking || (typeof networkList !== "undefined" && networkList.moving))) return

        refreshInProgress = true
        var keepSsid = selectedNetwork ? selectedNetwork.ssid : ""
        var scanned = []
        var hasBackendWifi = backend && backend.wifiScanNetworks
        if (hasBackendWifi) {
            scanned = backend.wifiScanNetworks(!!forceRescan)
        }
        if (scanned && scanned.length > 0) {
            wifiNetworks = scanned
        } else {
            wifiNetworks = []
            if (backend.wifiLastMessage !== undefined && backend.wifiLastMessage !== "") {
                uiStatusText = backend.wifiLastMessage
            } else if (!hasBackendWifi) {
                uiStatusText = tt("Backend Wi-Fi není dostupný.", "Backend Wi-Fi is unavailable.",
                                  "Backend-Wi-Fi ist nicht verfügbar.", "Backend Wi-Fi er ikke tilgængelig.")
            } else {
                uiStatusText = tt("Nenalezeny žádné Wi-Fi sítě.", "No Wi-Fi networks found.",
                                  "Keine Wi-Fi-Netzwerke gefunden.", "Ingen Wi-Fi-netværk fundet.")
            }
        }

        if (wifiNetworks.length === 0) {
            selectedIndex = -1
            refreshInProgress = false
            return
        }

        if (keepSsid !== "") {
            for (var i = 0; i < wifiNetworks.length; i++) {
                if (wifiNetworks[i].ssid === keepSsid) {
                    selectedIndex = i
                    refreshInProgress = false
                    return
                }
            }
        }
        selectedIndex = 0
        refreshInProgress = false
    }

    function doConnect(ssid, username, password, enterpriseMode) {
        if (!backend || !backend.wifiConnect) return
        clearStatusMessage()
        pendingConnectSsid = ssid
        pendingConnectUser = username
        pendingConnectPass = password
        pendingConnectEnterprise = (enterpriseMode === undefined || enterpriseMode === null)
                               ? (selectedNetwork ? !!selectedNetwork.requiresUsernamePassword : false)
                               : !!enterpriseMode
        busyConnecting = true
        connectStartTimer.start()
    }

    function doConnectNow() {
        var bssid = selectedNetwork && selectedNetwork.bssid ? selectedNetwork.bssid : ""
        var ok = backend.wifiConnect(pendingConnectSsid, pendingConnectUser, pendingConnectPass, pendingConnectEnterprise, bssid)
        showLargeStatus = !!backend.wifiAuthFailure
        if (!ok && backend.wifiAuthFailure) {
            uiStatusText = tt("Špatné heslo. Síť nebyla uložena.",
                              "Wrong password. Network was not saved.",
                              "Falsches Passwort. Das Netzwerk wurde nicht gespeichert.",
                              "Forkert adgangskode. Netværket blev ikke gemt.")
            largeStatusHideTimer.restart()
        } else if (backend.wifiLastMessage !== undefined && backend.wifiLastMessage !== "") {
            clearStatusMessage()
        } else {
            clearStatusMessage()
        }
        busyConnecting = false
        pendingConnectUser = ""
        pendingConnectPass = ""
        pendingConnectEnterprise = false
        var keep = pendingConnectSsid
        pendingConnectSsid = ""
        refreshNetworks(true)
        if (keep !== "" && wifiNetworks && wifiNetworks.length > 0) {
            for (var i = 0; i < wifiNetworks.length; i++) {
                if (wifiNetworks[i].ssid === keep) {
                    selectedIndex = i
                    break
                }
            }
        }
    }

    function doDisconnect(ssid) {
        if (!backend || !backend.wifiDisconnect) return
        backend.wifiDisconnect(ssid)
        clearStatusMessage()
        refreshNetworks(true)
    }

    function doForget(ssid) {
        if (!backend || !backend.wifiForget) return
        backend.wifiForget(ssid)
        clearStatusMessage()
        refreshNetworks(true)
    }

    Component.onCompleted: {
        clearStatusMessage()
    }

    Timer {
        id: deferredInitialScan
        interval: 80
        repeat: false
        onTriggered: {
            wifi.refreshNetworks(true)
            wifi.initialScanDone = true
        }
    }

    Timer {
        id: connectStartTimer
        interval: 30
        repeat: false
        onTriggered: wifi.doConnectNow()
    }

    Timer {
        id: largeStatusHideTimer
        interval: 7000
        repeat: false
        onTriggered: wifi.clearStatusMessage()
    }

    Timer {
        id: periodicReloadTimer
        interval: 12000
        repeat: true
        running: wifi.visible
        onTriggered: wifi.refreshNetworks(false)
    }

    onVisibleChanged: {
        if (visible && !initialScanDone) {
            deferredInitialScan.start()
        }
    }

    Rectangle { anchors.fill: parent; color: "#dd2e2e2e"; z: -10 }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.leftMargin: 14 * s
        anchors.rightMargin: 14 * s
        anchors.bottomMargin: 14 * s
        anchors.topMargin: 14 * s
        clip: true
        contentWidth: contentCol.width
        contentHeight: Math.max(height, contentCol.implicitHeight)
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: contentCol
            width: flick.width
            spacing: 14 * s

            Rectangle {
                width: parent.width - 20 * s
                radius: 20 * s
                color: "#cc2e2e2e"
                border.width: 1 * s
                border.color: "#ccc6c5df"
                height: Math.max(420 * s, flick.height - 6 * s)

                Row {
                    id: mainRow
                    anchors.fill: parent
                    anchors.margins: 14 * s
                    spacing: 14 * s

                    Rectangle {
                        width: parent.width * 0.5 - (7 * s)
                        height: parent.height - 28 * s
                        radius: 20 * s
                        color: "#00000044"
                        border.width: 0 * s
                        border.color: "#c6c5df"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12 * s
                            spacing: 12 * s

                            Row {
                                width: parent.width
                                spacing: 10 * s

                                Text {
                                    text: tt("Dostupné Wi-Fi sítě", "Available Wi-Fi networks", "Verfügbare Wi-Fi-Netze", "Tilgængelige Wi-Fi-netværk")
                                    color: "#EDEFF2"
                                    font.pixelSize: 34 * s
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 72 * s
                                    height: 58 * s
                                    radius: 10 * s
                                    color: reloadArea.pressed ? "#5a5a5ac4" : "#00000099"
                                    border.width: 1 * s
                                    border.color: "#88c6c5df"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↻"
                                        color: "#EDEFF2"
                                        font.pixelSize: 34 * s
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: reloadArea
                                        anchors.fill: parent
                                        onClicked: wifi.refreshNetworks(true)
                                    }
                                }
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                            Rectangle {
                                width: parent.width
                                height: parent.height - (100 * s)
                                radius: 16 * s
                                color: "#111722A8"
                                border.width: 1 * s
                                border.color: "#80c6c5df"

                                ListView {
                                    id: networkList
                                    anchors.fill: parent
                                    anchors.margins: 8 * s
                                    clip: true
                                    spacing: 10 * s
                                    model: wifi.wifiNetworks

                                    delegate: Rectangle {
                                        width: networkList.width
                                        height: 116 * s
                                        radius: 18 * s
                                        color: (index === wifi.selectedIndex) ? "#1f3a66" : "#1d1f24"
                                        border.width: 2 * s
                                        border.color: (index === wifi.selectedIndex) ? "orange" : "#c6c5df"

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: 12 * s
                                            spacing: 10 * s

                                            Column {
                                                width: parent.width * 0.58
                                                spacing: 4 * s

                                                Text {
                                                    text: modelData.ssid
                                                    color: "#EDEFF2"
                                                    font.pixelSize: 31 * s
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: modelData.connected ? tt("PŘIPOJENO", "CONNECTED", "VERBUNDEN", "FORBUNDET")
                                                                             : statusLabel(modelData)
                                                    color: (pendingConnectSsid !== "" && modelData.ssid === pendingConnectSsid) ? "#F2C94C"
                                                          : (modelData.connected ? "#66ff66" : "#c6c5df")
                                                    font.pixelSize: 23 * s
                                                    font.bold: modelData.connected || (pendingConnectSsid !== "" && modelData.ssid === pendingConnectSsid)
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }
                                            }

                                            Rectangle {
                                                width: 118 * s
                                                height: 40 * s
                                                radius: 10 * s
                                                color: modelData.saved ? "#203f2a" : "#3a3a3a"
                                                border.width: 1 * s
                                                border.color: "#c6c5df"
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.saved ? tt("ULOŽENO", "SAVED", "GESPEICH.", "GEMT")
                                                                          : tt("NOVÁ", "NEW", "NEU", "NY")
                                                    color: "#EDEFF2"
                                                    font.pixelSize: 16 * s
                                                    font.bold: true
                                                }
                                            }

                                            Item {
                                                width: 10 * s
                                                height: 1
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                wifi.selectedIndex = index
                                                if (modelData.saved && !modelData.connected) {
                                                    wifi.doConnect(modelData.ssid, "", "", !!modelData.requiresUsernamePassword)
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: networkList.count === 0
                                    text: searchingNetworksLabel()
                                    color: "#EDEFF2"
                                    font.pixelSize: 22 * s
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    width: parent.width - 24 * s
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width * 0.5 - (7 * s)
                        height: parent.height - 28 * s
                        radius: 20 * s
                        color: "#00000044"
                        border.width: 0 * s
                        border.color: "#c6c5df"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16 * s
                            spacing: 12 * s

                            Text {
                                text: tt("Detail sítě", "Network detail", "Netzwerkdetails", "Netværksdetaljer")
                                color: "#EDEFF2"
                                font.pixelSize: 28 * s
                                font.bold: true
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                            Rectangle {
                                width: parent.width
                                height: 65 * s
                                radius: 16 * s
                                color: "#00000066"
                                border.width: 1 * s
                                border.color: "#c6c5df"

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 10 * s
                                    spacing: 10 * s

                                    Text {
                                        id: selectedSsidText
                                        text: selectedNetwork ? selectedNetwork.ssid
                                                             : tt("Není vybraná síť", "No network selected", "Kein Netzwerk ausgewahlt",
                                                                  "Intet netværk valgt")
                                        color: "#EDEFF2"
                                        font.pixelSize: 35 * s
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                    }

                                }
                            }
                                    Rectangle {
                                        id: stateBadge
                                        width: 250 * s
                                        height: 42 * s
                                        radius: 12 * s
                                        color: (selectedNetwork && selectedNetwork.connected) ? "#0b7a21" : "#3a3a3a"
                                        border.width: 1 * s
                                        border.color: "#c6c5df"

                                        Text {
                                            anchors.centerIn: parent
                                            text: (selectedNetwork && selectedNetwork.connected)
                                                  ? tt("PŘIPOJENO", "CONNECTED", "VERBUNDEN", "FORBUNDET")
                                                  : tt("NEPŘIPOJENO", "NOT CONNECTED", "NICHT VERBUNDEN", "IKKE FORBUNDET")
                                            color: "#EDEFF2"
                                            font.pixelSize: 20 * s
                                            font.bold: true
                                        }
                                    }

                            Column {
                                width: parent.width
                                spacing: 12 * s

                                Row {
                                    width: parent.width
                                    Text {
                                        width: parent.width * 0.4
                                        text: tt("Zabezpečení:", "Security:", "Sicherheit:", "Sikkerhed:")
                                        color: "#c6c5df"
                                        font.pixelSize: 24 * s
                                    }
                                    Text {
                                        width: parent.width * 0.6
                                        text: selectedNetwork ? selectedNetwork.security : "-"
                                        color: "#EDEFF2"
                                        font.pixelSize: 24 * s
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text {
                                        width: parent.width * 0.4
                                        text: tt("Pásmo:", "Band:", "Band:", "Bånd:")
                                        color: "#c6c5df"
                                        font.pixelSize: 24 * s
                                    }
                                    Text {
                                        width: parent.width * 0.6
                                        text: selectedNetwork ? selectedNetwork.band : "-"
                                        color: "#EDEFF2"
                                        font.pixelSize: 24 * s
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Row {
                                    width: parent.width
                                    Text {
                                        width: parent.width * 0.4
                                        text: "IP"
                                        color: "#c6c5df"
                                        font.pixelSize: 24 * s
                                    }
                                    Text {
                                        width: parent.width * 0.6
                                        text: (selectedNetwork && selectedNetwork.ipAddress !== "") ? selectedNetwork.ipAddress : "-"
                                        color: "#EDEFF2"
                                        font.pixelSize: 24 * s
                                        wrapMode: Text.WrapAnywhere
                                    }
                                }
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.25 }

                            Row {
                                spacing: 10 * s

                                Rectangle {
                                    width: 240 * s
                                    height: 68 * s
                                    radius: 16 * s
                                    color: connectArea.pressed ? "#5a5a5ac4" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"
                                    opacity: selectedNetwork ? 1.0 : 0.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: (selectedNetwork && selectedNetwork.connected)
                                            ? tt("Odpojit", "Disconnect", "Trennen", "Afbryd")
                                            : tt("Připojit", "Connect", "Verbinden", "Forbind")
                                        color: "#EDEFF2"
                                        font.pixelSize: 26 * s
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: connectArea
                                        anchors.fill: parent
                                        enabled: selectedNetwork !== null
                                        onClicked: {
                                            if (!selectedNetwork) return
                                            if (selectedNetwork.connected) doDisconnect(selectedNetwork.ssid)
                                            else wifi.triggerConnectFlow()
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 210 * s
                                    height: 68 * s
                                    radius: 16 * s
                                    color: forgetArea.pressed ? "#5a5a5ac4" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"
                                    opacity: (selectedNetwork && selectedNetwork.saved) ? 1.0 : 0.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: tt("Zapomenout", "Forget", "Vergessen", "Glem")
                                        color: "#EDEFF2"
                                        font.pixelSize: 24 * s
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: forgetArea
                                        anchors.fill: parent
                                        enabled: selectedNetwork && selectedNetwork.saved
                                        onClicked: doForget(selectedNetwork.ssid)
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                visible: showLargeStatus && uiStatusText !== ""
                                radius: 18 * s
                                color: "#7a1616"
                                border.width: 2 * s
                                border.color: "#ffb3b3"
                                implicitHeight: errorStatusText.implicitHeight + 28 * s

                                Text {
                                    id: errorStatusText
                                    anchors.fill: parent
                                    anchors.margins: 14 * s
                                    text: uiStatusText
                                    color: "#FFF1F1"
                                    font.pixelSize: 30 * s
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.WordWrap
                                }
                            }

                        }
                    }
                }
            }

        }
    }

    Item {
        id: credentialDialog
        anchors.fill: parent
        visible: credentialDialogVisible
        z: 9999

        Rectangle { anchors.fill: parent; color: "#000000aa" }

        Rectangle {
            id: dialogCard
            width: Math.min(parent.width * 0.82, 760 * s)
            height: credentialNeedsUsername ? 500 * s : 420 * s
            anchors.centerIn: parent
            radius: 22 * s
            color: "#1b1b1b"
            border.width: 2 * s
            border.color: "#c6c5df"

            Column {
                anchors.fill: parent
                anchors.margins: 20 * s
                spacing: 16 * s

                Text {
                    text: tt("Přihlašovací údaje", "Credentials", "Anmeldedaten", "Loginoplysninger")
                    color: "#EDEFF2"
                    font.pixelSize: 26 * s
                    font.bold: true
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#EDEFF2"
                    font.pixelSize: 22 * s
                    text: tt("Síť: ", "Network: ", "Netz: ", "Netværk: ") + pendingSsid
                }

                Column {
                    width: parent.width
                    spacing: 10 * s
                    visible: credentialNeedsUsername

                    Text { text: tt("Username", "Username", "Benutzername", "Username"); color: "#c6c5df"; font.pixelSize: 22 * s }
                    TextField {
                        id: userField
                        width: parent.width
                        placeholderText: tt("Zadej username", "Enter username", "Benutzername eingeben", "Indtast brugernavn")
                        color: "white"
                        placeholderTextColor: "#CCCCCC"
                        background: Rectangle {
                            color: "#FFFFFF"
                            opacity: 0.15
                            radius: 6 * s
                            border.color: "#FFFFFF40"
                        }
                        onActiveFocusChanged: if (activeFocus) wifi.openKeyboardFor(this)
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10 * s
                    visible: credentialNeedsPassword

                    Text { text: tt("Heslo", "Password", "Passwort", "Adgangskode"); color: "#c6c5df"; font.pixelSize: 22 * s }
                    TextField {
                        id: passField
                        width: parent.width
                        placeholderText: tt("Zadej heslo", "Enter password", "Passwort eingeben", "Indtast adgangskode")
                        color: "white"
                        placeholderTextColor: "#CCCCCC"
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                        background: Rectangle {
                            color: "#FFFFFF"
                            opacity: 0.15
                            radius: 6 * s
                            border.color: "#FFFFFF40"
                        }
                        onActiveFocusChanged: if (activeFocus) wifi.openKeyboardFor(this)
                    }
                }

                Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.2 }

                Row {
                    width: parent.width -20
                    spacing: 20 * s

                    Rectangle {
                        id: cancelBtn
                        width: 230 * s
                        height: 74 * s
                        radius: 16 * s
                        color: cancelArea.pressed ? "#5a5a5ac4" : "#00000099"
                        border.width: 2 * s
                        border.color: "#c6c5df"

                        Text {
                            anchors.centerIn: parent
                            text: tt("Zrušit", "Cancel", "Abbrechen", "Annuller")
                            color: "#EDEFF2"
                            font.pixelSize: 28 * s
                            font.bold: true
                        }

                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            onClicked: credentialDialogVisible = false
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - cancelBtn.width - submitBtn.width - (20 * s))
                        height: 1
                    }

                    Rectangle {
                        id: submitBtn
                        width: 340 * s
                        height: 74 * s
                        radius: 16 * s
                        color: submitArea.pressed ? "#5a5a5ac4" : "#00000099"
                        border.width: 2 * s
                        border.color: "#c6c5df"

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - (14 * s)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WordWrap
                            text: tt("Potvrdit připojení", "Confirm connect", "Verbindung bestatigen", "Bekræft forbindelse")
                            color: "#EDEFF2"
                            font.pixelSize: 24 * s
                            font.bold: true
                        }

                        MouseArea {
                            id: submitArea
                            anchors.fill: parent
                            onClicked: {
                                doConnect(pendingSsid, userField.text, passField.text, credentialNeedsUsername)
                                credentialDialogVisible = false
                            }
                        }
                    }

                }
            }
        }
    }

    Item {
        id: busyOverlay
        anchors.fill: parent
        visible: busyConnecting
        z: 9900

        Rectangle {
            anchors.fill: parent
            color: "#aa000000"
        }

        Rectangle {
            anchors.centerIn: parent
            width: 240 * s
            height: 180 * s
            radius: 24 * s
            color: "#161c27dd"
            border.width: 0
            border.color: "#7cc8ff"

            Column {
                anchors.centerIn: parent
                spacing: 14 * s

                BusyIndicator {
                    running: busyConnecting
                    width: 92 * s
                    height: 92 * s
                    palette.dark: "#5a5a5a"
                    palette.light: "#d3d3d3"
                }

                Text {
                    text: tt("Připojuji…", "Connecting…", "Verbinde…", "Forbinder…")
                    color: "#F3FAFF"
                    font.pixelSize: 25 * s
                    font.bold: true
                }
            }
        }
    }
}
