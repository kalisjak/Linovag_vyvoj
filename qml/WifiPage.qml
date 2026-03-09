import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

OverlayPage {
    id: wifi
    title: "Wi-Fi"
    readonly property real s: uiScale

    // reference from App.qml (overlay.push props)
    property var floatEditorRef: null

    // temporary UI-only data (backend phase will replace these)
    property var wifiNetworks: [
        {
            "ssid": "Linovag Office",
            "connected": true,
            "saved": true,
            "security": "WPA2-PSK",
            "band": "2.4 GHz",
            "ipAddress": "192.168.1.45",
            "requiresPassword": true,
            "requiresUsernamePassword": false,
            "signal": 86,
            "statusKey": "connected"
        },
        {
            "ssid": "Guest Network",
            "connected": false,
            "saved": false,
            "security": "WPA2-PSK",
            "band": "5 GHz",
            "ipAddress": "",
            "requiresPassword": true,
            "requiresUsernamePassword": false,
            "signal": 63,
            "statusKey": "available"
        },
        {
            "ssid": "Corp WiFi",
            "connected": false,
            "saved": false,
            "security": "WPA2-Enterprise (802.1X)",
            "band": "5 GHz",
            "ipAddress": "",
            "requiresPassword": true,
            "requiresUsernamePassword": true,
            "signal": 54,
            "statusKey": "enterprise"
        },
        {
            "ssid": "Open Lab",
            "connected": false,
            "saved": false,
            "security": "Open",
            "band": "2.4 GHz",
            "ipAddress": "",
            "requiresPassword": false,
            "requiresUsernamePassword": false,
            "signal": 41,
            "statusKey": "open"
        }
    ]

    property int selectedIndex: wifiNetworks.length > 0 ? 0 : -1
    readonly property var selectedNetwork: (selectedIndex >= 0 && selectedIndex < wifiNetworks.length) ? wifiNetworks[selectedIndex] : null
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"

    property string uiStatusText: ""
    property bool credentialDialogVisible: false
    property bool credentialNeedsUsername: false
    property bool credentialNeedsPassword: true
    property string pendingSsid: ""

    signal connectRequested(string ssid, string username, string password)
    signal disconnectRequested(string ssid)

    function tt(cs, en, de, pl) {
        switch (lang) {
        case "en": return en
        case "de": return de
        case "pl": return pl
        default: return cs
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

    function needsCredential(net) {
        if (!net) return false
        if (net.requiresUsernamePassword) return true
        return net.requiresPassword && !net.saved
    }

    function credentialHint(net) {
        if (!net) return "-"
        if (net.requiresUsernamePassword) return tt("Vyžaduje username + password", "Requires username + password",
                                                    "Benutzername + Passwort erforderlich", "Wymaga username + haslo")
        if (net.requiresPassword) return net.saved ? tt("Heslo uloženo", "Password saved", "Passwort gespeichert", "Haslo zapisane")
                                                  : tt("Vyžaduje heslo", "Password required", "Passwort erforderlich", "Wymaga hasla")
        return tt("Bez hesla", "No password", "Kein Passwort", "Bez hasla")
    }

    function statusLabel(net) {
        if (!net) return "-"
        switch (net.statusKey) {
        case "connected":
            return tt("Připojeno", "Connected", "Verbunden", "Polaczono")
        case "available":
            return tt("Dostupná", "Available", "Verfugbar", "Dostepna")
        case "enterprise":
            return tt("Vyžaduje username + password", "Requires username + password",
                      "Benutzername + Passwort erforderlich", "Wymaga username + haslo")
        case "open":
            return tt("Nezabezpečená", "Open", "Offen", "Otwarte")
        default:
            return "-"
        }
    }

    function signalBarsCount(level) {
        if (level >= 80) return 4
        if (level >= 60) return 3
        if (level >= 35) return 2
        if (level > 0) return 1
        return 0
    }

    function signalColor(level) {
        if (level >= 70) return "#5DDA78"
        if (level >= 45) return "#F2C94C"
        return "#EB5757"
    }

    function triggerConnectFlow() {
        if (!selectedNetwork) return

        if (needsCredential(selectedNetwork)) {
            pendingSsid = selectedNetwork.ssid
            credentialNeedsUsername = !!selectedNetwork.requiresUsernamePassword
            credentialNeedsPassword = !!selectedNetwork.requiresPassword
            userField.text = ""
            passField.text = ""
            credentialDialogVisible = true
            return
        }

        uiStatusText = tt("Připraveno k připojení: ", "Ready to connect: ", "Bereit zum Verbinden: ", "Gotowe do polaczenia: ")
                     + selectedNetwork.ssid
        connectRequested(selectedNetwork.ssid, "", "")
    }

    readonly property real topBarH: 70 * s
    readonly property real topBarRightKeepW: 900 * s

    Rectangle {
        x: 0
        y: 0
        width: Math.max(0, parent.width - topBarRightKeepW)
        height: topBarH - 3
        color: "#882e2e2e"
        z: -10
    }

    Rectangle {
        x: 0
        y: topBarH
        width: parent.width
        height: Math.max(0, parent.height - topBarH)
        color: "#dd2e2e2e"
        z: -10
    }

    Rectangle {
        id: topLeftOverlay
        x: 0
        y: 0
        width: 520 * s
        height: topBarH - 5
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
                    font.pixelSize: 22 * s
                    font.bold: true
                }

                MouseArea { id: backArea; anchors.fill: parent; onClicked: wifi.goBack() }
            }

            Text {
                text: "Wi-Fi"
                color: "#EDEFF2"
                font.pixelSize: 30 * s
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
                        width: parent.width * 0.46
                        height: parent.height - 28 * s
                        radius: 20 * s
                        color: "#00000044"
                        border.width: 0 * s
                        border.color: "#c6c5df"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12 * s
                            spacing: 12 * s

                            Text {
                                text: tt("Dostupné Wi-Fi sítě", "Available Wi-Fi networks", "Verfugbare Wi-Fi-Netze", "Dostepne sieci Wi-Fi")
                                color: "#EDEFF2"
                                font.pixelSize: 30 * s
                                font.bold: true
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                            Rectangle {
                                width: parent.width
                                height: parent.height - (90 * s)
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
                                        height: 88 * s
                                        radius: 18 * s
                                        color: (index === wifi.selectedIndex) ? "#1f3a66" : "#1d1f24"
                                        border.width: 2 * s
                                        border.color: (index === wifi.selectedIndex) ? "orange" : "#c6c5df"

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: 12 * s
                                            spacing: 10 * s

                                            Column {
                                                width: parent.width * 0.72
                                                spacing: 4 * s

                                                Text {
                                                    text: modelData.ssid
                                                    color: "#EDEFF2"
                                                    font.pixelSize: 26 * s
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: modelData.connected ? tt("PŘIPOJENO", "CONNECTED", "VERBUNDEN", "POLACZONO")
                                                                             : statusLabel(modelData)
                                                    color: modelData.connected ? "#66ff66" : "#c6c5df"
                                                    font.pixelSize: 18 * s
                                                    font.bold: modelData.connected
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }
                                            }

                                            Row {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 4 * s

                                                Repeater {
                                                    model: 4
                                                    delegate: Rectangle {
                                                        width: 8 * s
                                                        height: (10 + (index * 6)) * s
                                                        radius: 2 * s
                                                        color: index < signalBarsCount(modelData.signal)
                                                               ? signalColor(modelData.signal)
                                                               : "#5D5D5D"
                                                        border.width: 1
                                                        border.color: "#222222"
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: wifi.selectedIndex = index
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width * 0.54 - 14 * s
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
                                text: tt("Detail sítě", "Network detail", "Netzwerkdetails", "Szczegoly sieci")
                                color: "#EDEFF2"
                                font.pixelSize: 28 * s
                                font.bold: true
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                            Rectangle {
                                width: parent.width
                                height: 60 * s
                                radius: 16 * s
                                color: "#00000066"
                                border.width: 1 * s
                                border.color: "#c6c5df"

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 10 * s
                                    spacing: 8 * s

                                    Text {
                                        text: selectedNetwork ? selectedNetwork.ssid
                                                             : tt("Není vybraná síť", "No network selected", "Kein Netzwerk ausgewahlt",
                                                                  "Brak wybranej sieci")
                                        color: "#EDEFF2"
                                        font.pixelSize: 30 * s
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: parent.width - 130 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        width: 110 * s
                                        height: 34 * s
                                        radius: 12 * s
                                        color: (selectedNetwork && selectedNetwork.connected) ? "#0b4a16" : "#00000099"
                                        border.width: 1 * s
                                        border.color: "#c6c5df"
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: (selectedNetwork && selectedNetwork.connected) ? tt("PŘIPOJENO", "CONNECTED", "VERBUNDEN", "POLACZONO")
                                                                                               : tt("NEAKTIVNÍ", "INACTIVE", "INAKTIV", "NIEAKTYWNE")
                                            color: "#EDEFF2"
                                            font.pixelSize: 17 * s
                                            font.bold: true
                                        }
                                    }
                                }
                            }

                            Grid {
                                width: parent.width
                                columns: 2
                                rowSpacing: 8 * s
                                columnSpacing: 8 * s

                                Text { text: tt("Stav připojení:", "Connection state:", "Verbindungsstatus:", "Stan polaczenia:"); color: "#c6c5df"; font.pixelSize: 21 * s }
                                Text { text: selectedNetwork ? statusLabel(selectedNetwork) : "-"; color: "#EDEFF2"; font.pixelSize: 21 * s }

                                Text { text: tt("Zabezpečení:", "Security:", "Sicherheit:", "Zabezpieczenie:"); color: "#c6c5df"; font.pixelSize: 21 * s }
                                Text { text: selectedNetwork ? selectedNetwork.security : "-"; color: "#EDEFF2"; font.pixelSize: 21 * s }

                                Text { text: tt("Pásmo:", "Band:", "Band:", "Pasmo:"); color: "#c6c5df"; font.pixelSize: 21 * s }
                                Text { text: selectedNetwork ? selectedNetwork.band : "-"; color: "#EDEFF2"; font.pixelSize: 21 * s }

                                Text { text: "IP"; color: "#c6c5df"; font.pixelSize: 21 * s }
                                Text {
                                    text: (selectedNetwork && selectedNetwork.ipAddress !== "") ? selectedNetwork.ipAddress : "-"
                                    color: "#EDEFF2"
                                    font.pixelSize: 21 * s
                                }

                                Text { text: tt("Přihlášení:", "Credentials:", "Anmeldung:", "Logowanie:"); color: "#c6c5df"; font.pixelSize: 21 * s }
                                Text { text: credentialHint(selectedNetwork); color: "#EDEFF2"; font.pixelSize: 21 * s }
                            }

                            Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.25 }

                            Row {
                                spacing: 10 * s

                                Rectangle {
                                    width: 210 * s
                                    height: 68 * s
                                    radius: 16 * s
                                    color: connectArea.pressed ? "#5a5a5ac4" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"
                                    opacity: selectedNetwork ? 1.0 : 0.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: (selectedNetwork && selectedNetwork.connected) ? tt("Přepojit", "Switch", "Wechseln", "Przelacz")
                                                                                           : tt("Připojit", "Connect", "Verbinden", "Polacz")
                                        color: "#EDEFF2"
                                        font.pixelSize: 26 * s
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: connectArea
                                        anchors.fill: parent
                                        enabled: selectedNetwork !== null
                                        onClicked: wifi.triggerConnectFlow()
                                    }
                                }

                                Rectangle {
                                    width: 210 * s
                                    height: 68 * s
                                    radius: 16 * s
                                    color: disconnectArea.pressed ? "#5a5a5ac4" : "#00000099"
                                    border.width: 2 * s
                                    border.color: "#c6c5df"
                                    opacity: (selectedNetwork && selectedNetwork.connected) ? 1.0 : 0.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: tt("Odpojit", "Disconnect", "Trennen", "Rozlacz")
                                        color: "#EDEFF2"
                                        font.pixelSize: 26 * s
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: disconnectArea
                                        anchors.fill: parent
                                        enabled: selectedNetwork && selectedNetwork.connected
                                        onClicked: {
                                            uiStatusText = tt("Připraveno k odpojení: ", "Ready to disconnect: ",
                                                              "Bereit zum Trennen: ", "Gotowe do rozlaczenia: ") + selectedNetwork.ssid
                                            disconnectRequested(selectedNetwork.ssid)
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: uiStatusText === "" ? tt("Akce jsou připravené pro backend napojení (nmcli).",
                                                               "Actions are ready for backend connection (nmcli).",
                                                               "Aktionen sind fur die Backend-Anbindung bereit (nmcli).",
                                                               "Akcje sa gotowe na podlaczenie backendu (nmcli).")
                                                     : uiStatusText
                                color: "#c6c5df"
                                font.pixelSize: 20 * s
                                wrapMode: Text.WordWrap
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
                    text: tt("Přihlašovací údaje", "Credentials", "Anmeldedaten", "Dane logowania")
                    color: "#EDEFF2"
                    font.pixelSize: 26 * s
                    font.bold: true
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#EDEFF2"
                    font.pixelSize: 19 * s
                    text: tt("Síť: ", "Network: ", "Netz: ", "Siec: ") + pendingSsid
                }

                Column {
                    width: parent.width
                    spacing: 10 * s
                    visible: credentialNeedsUsername

                    Text { text: tt("Username", "Username", "Benutzername", "Username"); color: "#c6c5df"; font.pixelSize: 18 * s }
                    TextField {
                        id: userField
                        width: parent.width
                        placeholderText: tt("Zadej username", "Enter username", "Benutzername eingeben", "Wpisz username")
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

                    Text { text: tt("Heslo", "Password", "Passwort", "Haslo"); color: "#c6c5df"; font.pixelSize: 18 * s }
                    TextField {
                        id: passField
                        width: parent.width
                        placeholderText: tt("Zadej heslo", "Enter password", "Passwort eingeben", "Wpisz haslo")
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
                    width: parent.width
                    spacing: 12 * s

                    Item {
                        width: Math.max(0, parent.width - cancelBtn.width - submitBtn.width - (12 * s))
                        height: 1
                    }

                    Rectangle {
                        id: cancelBtn
                        width: 170 * s
                        height: 58 * s
                        radius: 16 * s
                        color: cancelArea.pressed ? "#5a5a5ac4" : "#00000099"
                        border.width: 2 * s
                        border.color: "#c6c5df"

                        Text {
                            anchors.centerIn: parent
                            text: tt("Zrušit", "Cancel", "Abbrechen", "Anuluj")
                            color: "#EDEFF2"
                            font.pixelSize: 22 * s
                            font.bold: true
                        }

                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            onClicked: credentialDialogVisible = false
                        }
                    }

                    Rectangle {
                        id: submitBtn
                        width: 280 * s
                        height: 58 * s
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
                            text: tt("Potvrdit připojení", "Confirm connect", "Verbindung bestatigen", "Potwierdz polaczenie")
                            color: "#EDEFF2"
                            font.pixelSize: 19 * s
                            font.bold: true
                        }

                        MouseArea {
                            id: submitArea
                            anchors.fill: parent
                            onClicked: {
                                uiStatusText = tt("Připraveno k připojení: ", "Ready to connect: ",
                                                  "Bereit zum Verbinden: ", "Gotowe do polaczenia: ") + pendingSsid
                                connectRequested(pendingSsid, userField.text, passField.text)
                                credentialDialogVisible = false
                            }
                        }
                    }

                }
            }
        }
    }
}
