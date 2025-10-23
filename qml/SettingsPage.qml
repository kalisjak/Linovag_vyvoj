// SettingsPage.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

OverlayPage {
    id: set
    title: "Nastavení"
    padding: 16
    background: Rectangle { color: "#1b1b1b"; radius: 8; opacity: 0.98 }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent; anchors.margins: 6
            ToolButton { text: "← Zpět"; onClicked: set.goBack() }
            Label { text: "Nastavení"; font.bold: true; Layout.fillWidth: true }
        }
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 12
        Label { text: "Základní nastavení…"; color: "white" }
        Button { text: "Zavřít"; onClicked: set.goBack() }
    }
}
