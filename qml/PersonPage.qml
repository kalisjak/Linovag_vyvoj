import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

OverlayPage {
    id: page
    title: "Osobní nastavení"

    readonly property real s: uiScale
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"
    property var floatEditorRef: null
    property int currentLanguageIndex: 0

    readonly property var languages: [
        { code: "cs", label: "Čeština" },
        { code: "en", label: "English" },
        { code: "de", label: "Deutsch" },
        { code: "dk", label: "Dansk" }
    ]

    function tt(cs, en, de, dk) {
        switch (lang) {
        case "en": return en
        case "de": return de
        case "dk": return dk
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

    function languageIndex(code) {
        for (var i = 0; i < languages.length; i++) {
            if (languages[i].code === code)
                return i
        }
        return 0
    }

    function selectLanguage(index) {
        if (!backend) return
        var count = languages.length
        if (count === 0) return
        while (index < 0) index += count
        while (index >= count) index -= count
        currentLanguageIndex = index
        backend.appLanguage = languages[index].code
    }

    function syncFromBackend() {
        currentLanguageIndex = languageIndex(lang)
        emailField.text = backend && backend.reclaimEmail ? backend.reclaimEmail : ""
    }

    Component.onCompleted: syncFromBackend()

    Connections {
        target: backend
        function onAppLanguageChanged() { page.currentLanguageIndex = page.languageIndex(backend.appLanguage) }
        function onReclaimInfoChanged() { emailField.text = backend.reclaimEmail }
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
                height: Math.max(250 * s, languageCol.implicitHeight + 50 * s)

                Column {
                    id: languageCol
                    anchors.fill: parent
                    anchors.margins: 14 * s
                    spacing: 20 * s

                    Text {
                        text: tt("Jazyk aplikace", "Application language", "App-Sprache", "App-sprog")
                        color: "#EDEFF2"
                        font.pixelSize: 40 * s
                        font.bold: true
                    }

                    Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                    Rectangle {
                        width: parent.width
                        height: 170 * s
                        // radius: 18 * s
                        color: "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 18 * s
                            spacing: 50 * s

                            Rectangle {
                                width: 150 * s
                                height: parent.height
                                radius: 18 * s
                                color: prevLangArea.pressed ? "#5a5a5ac4" : "#ccEDEFF2"
                                border.width: 2 * s
                                border.color: "#c6c5df"

                                Text {
                                    anchors.centerIn: parent
                                    text: "‹"
                                    color: "#2e2e2e"
                                    font.pixelSize: 70 * s
                                    font.bold: true
                                }

                                MouseArea {
                                    id: prevLangArea
                                    anchors.fill: parent
                                    onClicked: page.selectLanguage(page.currentLanguageIndex - 1)
                                }
                            }

                            Rectangle {
                                width: parent.width - (2 * 200 * s)
                                height: parent.height
                                radius: 18 * s
                                color: "#1f3a66"
                                border.width: 2 * s
                                border.color: "#c6c5df"

                                Text {
                                    anchors.centerIn: parent
                                    text: page.languages[page.currentLanguageIndex].label
                                    color: "#EDEFF2"
                                    font.pixelSize: 34 * s
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 150 * s
                                height: parent.height
                                radius: 18 * s
                                color: nextLangArea.pressed ? "#5a5a5ac4" : "#ccEDEFF2"
                                border.width: 2 * s
                                border.color: "#c6c5df"

                                Text {
                                    anchors.centerIn: parent
                                    text: "›"
                                    color: "#2e2e2e"
                                    font.pixelSize: 70 * s
                                    font.bold: true
                                }

                                MouseArea {
                                    id: nextLangArea
                                    anchors.fill: parent
                                    onClicked: page.selectLanguage(page.currentLanguageIndex + 1)
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
                height: Math.max(245 * s, personalCol.implicitHeight + 50 * s)

                Column {
                    id: personalCol
                    anchors.fill: parent
                    anchors.margins: 14 * s
                    spacing: 20 * s

                    Text {
                        text: tt("Osobní údaje", "Personal details", "Persönliche Daten", "Personlige oplysninger")
                        color: "#EDEFF2"
                        font.pixelSize: 40 * s
                        font.bold: true
                    }

                    Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                    Text {
                        text: tt("E-mail zákazníka", "Customer e-mail", "Kunden-E-Mail", "Kundens e-mail")
                        color: "#EDEFF2"
                        font.pixelSize: 30 * s
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: 18 * s
                        anchors.left: undefined
                        anchors.right: undefined

                        TextField {
                            id: emailField
                            width: parent.width - 300 * s
                            height: 80 * s
                            text: backend && backend.reclaimEmail ? backend.reclaimEmail : ""
                            placeholderText: "napr. info@firma.cz"
                            color: "#EDEFF2"
                            placeholderTextColor: "#9DA7B5"
                            font.pixelSize: 30 * s
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            background: Rectangle {
                                radius: 16 * s
                                color: "#1f3a66"
                                border.width: 2 * s
                                border.color: emailField.activeFocus ? "orange" : "#80c6c5df"
                            }
                            onActiveFocusChanged: if (activeFocus) page.openKeyboardFor(this)
                        }
                        

                        Rectangle {
                            width: 240 * s
                            height: 80 * s
                            radius: 16 * s
                            color: saveEmailArea.pressed ? "#1f3a66" : "#00000099"
                            border.width: 2 * s
                            border.color: "#c6c5df"
                            anchors.verticalCenter: emailField.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: tt("Uložit", "Save", "Speichern", "Gem")
                                color: "#EDEFF2"
                                font.pixelSize: 24 * s
                                font.bold: true
                            }

                            MouseArea {
                                id: saveEmailArea
                                anchors.fill: parent
                                onClicked: backend.setReclaimEmail(emailField.text.trim())
                            }
                        }
                    }
                }
            }
        }
    }
}
