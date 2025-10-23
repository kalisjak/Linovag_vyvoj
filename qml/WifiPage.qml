// WifiPage.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

OverlayPage {
    id: wifi
    title: "Wi-Fi"
    padding: 16
    background: Rectangle { color: "#1b1b1b"; radius: 8; opacity: 0.98 }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            ToolButton { text: "← Zpět"; onClicked: wifi.goBack() }
            Label {
                text: "Wi-Fi"
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        Label { text: "Sem přijde výběr sítí…"; color: "white" }
        Button { text: "Zavřít"; onClicked: wifi.goBack() }
    }
}


