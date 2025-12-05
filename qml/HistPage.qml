import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: histP
    property real uiScale: 1.0

    title: "Historie teplot"
    background: Item {}
    visible: SwipeView.isCurrentItem

    contentItem: Item {
        anchors.fill: parent
        // relativní odsazení, aby to fungovalo i na 720x1280
        anchors.margins: 19 * uiScale // Math.min(parent.width, parent.height) * 0.03

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
                id: qrColumn
                anchors.horizontalCenter: parent.horizontalCenter
                // posunout QR trochu níž
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.05
                // anchors.topMargin: 10 * uiScale
                // anchors.bottomMargin: 70 * uiScale
                spacing: 16

                Image {
                    id: qrImage
                    source: "qrc:/qml/qr_hist.png"
                    fillMode: Image.PreserveAspectFit
                    // velikost relativně k menšímu rozměru
                    sourceSize.width: Math.min(histP.width, histP.height) * 0.6
                    sourceSize.height: Math.min(histP.width, histP.height) * 0.6
                    // sourceSize.width: 320 * uiScale
                    // sourceSize.height: 320 * uiScale
                    cache: true
                }

                Text {
                    text: "Otevřít webový přehled historie"
                    color: "#EDEFF2"
                    // font.pixelSize: Math.min(histP.width, histP.height) * 0.05
                    font.pixelSize: 36 * uiScale
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

        // PRAVÁ ČÁST – LOGY (3/5 šířky)
        Rectangle {
            id: rightPane
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: divider.right
                right: parent.right
                // odsazení od středové čáry
                leftMargin: 18 * uiScale //Math.min(parent.width, parent.height) * 0.03
                topMargin: Math.min(parent.width, parent.height) * 0.05
                bottomMargin: 18 * uiScale
            }
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.min(parent.width, parent.height) * 0.02
                spacing: Math.min(parent.width, parent.height) * 0.01

                Text {
                    text: "Log teplot"
                    color: "#EDEFF2"
                    font.pixelSize: Math.min(histP.width, histP.height) * 0.08
                    font.bold: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    // odsazení nadpisu od středové čáry
                    Layout.leftMargin: Math.min(parent.width, parent.height) * 0.03
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: "#060a11ff"
                    border.color: "#FFFFFF33"
                    border.width: 0
                    clip: true

                    ListView {
                        id: logView
                        anchors.fill: parent
                        anchors.margins: Math.min(histP.width, histP.height) * 0.03
                        spacing: 4
                        clip: true

                        model: backend.historyLog

                        // automatické sledování konce logu
                        property bool autoFollow: true

                        delegate: Text {
                            text: modelData
                            color: "#EDEFF2"
                            font.pixelSize: Math.min(histP.width, histP.height) * 0.052
                            font.family: "monospace"
                            elide: Text.ElideRight
                        }

                        Component.onCompleted: {
                            // po načtení skoč na konec
                            positionViewAtEnd()
                        }

                        onCountChanged: {
                            // když přibude nový log a autoFollow je zapnutý,
                            // drž se na nejnovější hodnotě
                            if (autoFollow) {
                                positionViewAtEnd()
                            }
                        }

                        onMovementStarted: {
                            // uživatel začal manuálně skrolovat → vypnout auto-follow
                            autoFollow = false
                            followTimer.stop()
                        }

                        onMovementEnded: {
                            // až uživatel přestane skrolovat, za 10 s se vrátíme
                            // na autoFollow a skočíme na konec
                            followTimer.restart()
                        }
                    }

                    // Timer, který po 10 s nečinnosti vrátí ListView na nejnovější hodnoty
                    Timer {
                        id: followTimer
                        interval: 10000
                        repeat: false
                        running: false
                        onTriggered: {
                            logView.autoFollow = true
                            logView.positionViewAtEnd()
                        }
                    }
                }
            }
        }
    }
}
