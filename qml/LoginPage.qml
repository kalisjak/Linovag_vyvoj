// LoginPage.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

OverlayPage {
    id: login
    title: "Přihlášení"
    padding: 16
    background: Rectangle { color: "#1b1b1b"; radius: 8; opacity: 0.98 }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent; anchors.margins: 6
            ToolButton { text: "← Zpět"; onClicked: login.goBack() }
            Label { text: "Přihlášení"; font.bold: true; Layout.fillWidth: true }
        }
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 12
        TextField { placeholderText: "Uživatel"
                    onPressed: forceActiveFocus()
                    onActiveFocusChanged: if (activeFocus && typeof scroll !== "undefined") scroll.ensureVisible(this)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly | Qt.ImhPreferNumbers }

        TextField { placeholderText: "Heslo"
                    onPressed: forceActiveFocus()
                    onActiveFocusChanged: if (activeFocus && typeof scroll !== "undefined") scroll.ensureVisible(this)
                    echoMode: TextInput.Password 
                    inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
        }
        RowLayout {
            spacing: 8
            Button { text: "Přihlásit"; onClicked: console.log("login…") }
            Button { text: "Zavřít"; onClicked: login.goBack() }
        }
    }
}
