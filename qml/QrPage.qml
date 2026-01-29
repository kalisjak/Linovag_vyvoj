import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: qrP
    property real uiScale: 1.0

    title: "QR kód"
    background: Item {}
    visible: SwipeView.isCurrentItem

    contentItem: Item {
        anchors.fill: parent
        anchors.margins: 19 * uiScale

        // LEVÁ ČÁST
        Rectangle {
            id: leftPane
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * 0.5   // cca 1/2
            color: "transparent"

            Column {
                id: qrCol01
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                // anchors.bottom: parent.bottom
                anchors.top: parent.top
                anchors.topMargin: 100 * uiScale
                // anchors.bottomMargin: parent.height * 0.05
                spacing: 16

                Image {
                    id: qrWeb
                    source: "qrc:/qml/qr_web.png"
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 340 * uiScale
                    sourceSize.height: 340 * uiScale
                    // sourceSize.width: Math.min(qrP.width, qrP.height) * 0.6
                    // sourceSize.height: Math.min(qrP.width, qrP.height) * 0.6
                    cache: true
                }

                Text {
                    text: "Produktwebseite öffnen" // (DE) / Otevřít webové stránky produktu (CZ) / Open product website (EN) / Produktwebseite öffnen (DE) / Åbn produktets webside (DK)
                    color: "#EDEFF2"
                    font.pixelSize: 30 * uiScale
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width * 0.9
                }
            }
        }
        // SVISLÁ ČÁRA MEZI PANELY
        Rectangle {
            id: divider
            anchors.left: leftPane.right
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: parent.height * 0.7
            color: "#b9b9b9ff"
        }

        // PRAVÁ ČÁST
        Rectangle {
            id: rightPane
            anchors {
                left: divider.right
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            color: "transparent"

            Column {
                id: qrCol02
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.top: parent.top
                anchors.topMargin: 100 * uiScale
                spacing: 16

                Image {
                    id: qrApp
                    source: "qrc:/qml/qr_tutor.png"
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 340 * uiScale
                    sourceSize.height: 340 * uiScale
                    cache: true
                }

                Text {
                    text: "Wartungsanleitung öffnen" // (DE) / Otevřít tutoriál k údržbě (CZ) / Open maintenance tutorial (EN) / Wartungsanleitung öffnen (DE) / Åben vedligeholdelsevejledning (DK)
                    color: "#EDEFF2"
                    font.pixelSize: 30 * uiScale
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width * 0.9
                }
            }
        }
    }
}
