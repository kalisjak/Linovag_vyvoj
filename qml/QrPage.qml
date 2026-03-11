import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "I18n.js" as I18n

Page {
    id: qrP
    property real uiScale: 1.0
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"
    readonly property var qrItems: [
        { title: I18n.t(lang, "qr.history"), source: backend.histQrSource },
        { title: I18n.t(lang, "qr.reclaim"), source: backend.reclaimQrSource },
        { title: I18n.t(lang, "qr.tutorial"), source: backend.tutorialQrSource },
        { title: I18n.t(lang, "qr.datasheet"), source: "qrc:/qml/qr_datasheet.png" },
        { title: I18n.t(lang, "qr.manual"), source: "qrc:/qml/qr_manual.png" },
        { title: I18n.t(lang, "qr.spares"), source: "qrc:/qml/qr_spares.png" }
    ]

    title: I18n.t(lang, "qr.title")
    background: Item {}
    visible: SwipeView.isCurrentItem

    contentItem: Item {
        anchors.fill: parent
        anchors.margins: 28 * uiScale

        Column {
            anchors.fill: parent
            spacing: 20 * uiScale

            // Text {
            //     text: I18n.t(qrP.lang, "qr.subtitle")
            //     color: "#EDEFF2"
            //     font.pixelSize: 34 * uiScale
            //     font.bold: true
            //     wrapMode: Text.WordWrap
            //     width: parent.width
            // }

            GridLayout {
                width: parent.width
                height: parent.height
                columns: 3
                rowSpacing: 18 * uiScale
                columnSpacing: 18 * uiScale

                Repeater {
                    model: qrP.qrItems

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 26 * uiScale
                        color: "#091421"
                        border.width: 2
                        border.color: "#29445f"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 18 * uiScale
                            spacing: 20 * uiScale

                            Text {
                                text: modelData.title
                                color: "#ffffff"
                                font.pixelSize: 26 * uiScale
                                font.bold: true
                                wrapMode: Text.WordWrap
                                width: parent.width
                                height: 72 * uiScale
                            }

                            Item {
                                width: parent.width
                                height: 80

                                ExpandableQrTile {
                                    anchors.centerIn: parent
                                    source: modelData.source
                                    title: modelData.title
                                    biFamily: (typeof win !== "undefined") ? win.biFamily : ""
                                    previewWidth: 180
                                    previewHeight: previewWidth
                                    expandedMaxSize: 1040
                                    showButton: false
                                    previewUsesImage: false
                                    previewIcon: "\uF6AE"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
