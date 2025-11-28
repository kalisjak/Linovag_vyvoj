import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Historie teplot"
    background: Item {}
    visible: SwipeView.isCurrentItem

    contentItem: Item {
        anchors.fill: parent
        anchors.margins: 32

        // LEVÁ ČÁST – QR kód (2/5 šířky)
        Rectangle {
            id: leftPane
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * 0.4   // cca 2/5
            color: "transparent"

            Column {
                anchors.centerIn: parent
                spacing: 16

                Image {
                    id: qrImage
                    source: "qrc:/qml/qr_web.png"
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 220
                    sourceSize.height: 220
                    cache: true
                }

                Text {
                    text: "Verlauf herunterladen"
                    color: "#EDEFF2"
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width
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

        // PRAVÁ ČÁST – LOGY (3/5 šířky)
        Rectangle {
            id: rightPane
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: divider.right
                right: parent.right
            }
            color: "#00000049"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 8

                Text {
                    text: "Temperaturverlauf"
                    color: "#EDEFF2"
                    font.pixelSize: 26
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter //Qt.AlignLeft |
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: "#000000dc"
                    border.color: "#b9b9b9ff"
                    border.width: 0
                    clip: true

                    ListView {
                        id: logView
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4
                        clip: true

                        model: backend.historyLog

                        delegate: Text {
                            text: modelData
                            color: "#EDEFF2"
                            font.pixelSize: 16
                            font.family: "monospace"
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
