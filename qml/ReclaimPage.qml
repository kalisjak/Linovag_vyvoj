import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: reclP
    property real uiScale: 1.0

    title: "Reklamacni stranka"
    background: Item {}
    visible: SwipeView.isCurrentItem

    contentItem: Item {
        anchors.fill: parent
        anchors.margins: 19 * uiScale

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
                anchors.top: parent.top
                anchors.topMargin: 70 * uiScale
                spacing: 16

                Image {
                    id: qrImage
                    source: "qrc:/qml/qr_reklam.png"
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 340 * uiScale
                    sourceSize.height: 340 * uiScale
                    cache: true
                }

                Text {
                    text: "Otevřít email s předvyplněnou reklamační žádostí"
                    color: "#EDEFF2"
                    font.pixelSize: 32 * uiScale
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
                leftMargin: 18 * uiScale
                topMargin: 40 * uiScale
                // bottomMargin: 10 * uiScale
            }
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15 * uiScale
                spacing: 12

                Text {
                    text: "Reklamační žádost"
                    color: "#EDEFF2"
                    font.pixelSize: 45 * uiScale
                    font.bold: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.leftMargin: 12 * uiScale
                }

                // BLOK ODRAŽEK (EMAIL, OBJEDNÁVKA, ID)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10 * uiScale
                    Layout.leftMargin: 20 * uiScale
                    Layout.topMargin: 10 * uiScale

                    // 1) Email
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * uiScale

                        Rectangle {
                            width: 10 * uiScale
                            height: 10 * uiScale
                            radius: 2 * uiScale
                            color: "#EDEFF2"
                            Layout.alignment: Qt.AlignVCenter   // čtvereček na stejné úrovni jako text
                        }

                        Text {
                            text: "Email:"
                            color: "#EDEFF2"
                            font.pixelSize: 28 * uiScale
                            font.bold: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: backend.reclaimEmail || "reklamace@gastro.cz"
                            color: "#EDEFF2"
                            font.pixelSize: 28 * uiScale
                            font.bold: false
                            wrapMode: Text.WordWrap
                        }
                    }

                    // 2) Číslo objednávky
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * uiScale

                        Rectangle {
                            width: 10 * uiScale
                            height: 10 * uiScale
                            radius: 2 * uiScale
                            color: "#EDEFF2"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "Číslo objednávky:"
                            color: "#EDEFF2"
                            font.pixelSize: 28 * uiScale
                            font.bold: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: backend.reclaimOrderNumber || "xx-123456-abcd"
                            color: "#EDEFF2"
                            font.pixelSize: 28 * uiScale
                            font.bold: false
                            wrapMode: Text.WordWrap
                        }
                    }

                    // 3) ID zařízení
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * uiScale

                        Rectangle {
                            width: 10 * uiScale
                            height: 10 * uiScale
                            radius: 2 * uiScale
                            color: "#EDEFF2"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "ID zařízení:"
                            color: "#EDEFF2"
                            font.pixelSize: 28 * uiScale
                            font.bold: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (typeof backend !== "undefined" && backend.serialNumber) ? backend.serialNumber : "SN-000000"
                            color: "#EDEFF2"
                            font.pixelSize: 28 * uiScale
                            font.bold: false
                            wrapMode: Text.WordWrap
                        }
                    }
                }


                // NÁPIS NAD OKÉNKEM S CHYBAMI
                Text {
                    text: "Nalezené chyby:"
                    color: "#EDEFF2"
                    font.pixelSize: 28 * uiScale
                    font.bold: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.topMargin: 18 * uiScale
                    Layout.leftMargin: 12 * uiScale
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: "#060a11ff"
                    border.color: "#FFFFFF33"
                    border.width: 0
                    clip: true

                    ListView {
                        id: errorsView
                        anchors.fill: parent
                        anchors.leftMargin: 12 * uiScale
                        // anchors.margins: 10 * uiScale
                        // spacing: 4
                        clip: true

                        // v C++ jako Q_PROPERTY(QStringList reclaimErrors ...)
                        model: [backend.reclaimErrorsText || "Zatím nebyla detekována žádná chyba."]
                        // model: [backend.reclaimErrorsText || "Hej nic ještě nebylo nahlášeno, vše vypadá OK! \nAle tohle je testovací text, který simuluje nějaké chyby, které by mohly být zobrazeny v tomto okně. Může to být delší text, který se bude zalamovat podle šířky okna a bude potřeba scrollovat, pokud je ho hodně. \nTakže tady přidávám ještě nějaký další text, aby to opravdu vypadalo jako reálný scénář."]

                        delegate: Text {
                            width: errorsView.width
                            text: modelData
                            color: "#EDEFF2"
                            font.pixelSize: 26 * uiScale
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }
}
