import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "I18n.js" as I18n

Page {
    id: qrP
    property real uiScale: 1.0
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"
    readonly property var qrItems: [
        { title: I18n.t(lang, "qr.history"), popupTitle: I18n.t(lang, "qr.history"), source: backend.histQrSource, icon: "\uF292", iconAdjust: -25 },
        { title: I18n.t(lang, "qr.reclaim"), popupTitle: I18n.t(lang, "reclaim.qr_caption"), source: backend.reclaimQrSource, icon: "\uF32F" },
        { title: I18n.t(lang, "qr.tutorial"), popupTitle: I18n.t(lang, "qr.tutorial"), source: backend.tutorialQrSource, icon: "\uF4F1" },
        { title: I18n.t(lang, "qr.datasheet"), popupTitle: I18n.t(lang, "qr.datasheet"), source: "qrc:/qml/qr_datasheet.png", icon: "\uF194" },
        { title: I18n.t(lang, "qr.manual"), popupTitle: I18n.t(lang, "qr.manual"), source: "qrc:/qml/qr_manual.png", icon: "\uF444", iconAdjust: -15 },
        { title: I18n.t(lang, "qr.spares"), popupTitle: I18n.t(lang, "qr.spares"), source: "qrc:/qml/qr_spares.png", icon: "\uF000" }
    ]

    title: I18n.t(lang, "qr.title")
    background: Item {}
    visible: SwipeView.isCurrentItem

    contentItem: Item {
        anchors.fill: parent
        anchors.topMargin: 18 * uiScale
        anchors.leftMargin: 30 * uiScale
        anchors.rightMargin: 30 * uiScale
        anchors.bottomMargin: 18 * uiScale
        // anchors.margins: 28 * uiScale

        Column {
            anchors.fill: parent
            spacing: 40 * uiScale

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
                        color: "transparent"// "#cc091421"

                        Column {
                            anchors.fill: parent
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            // spacing: 10 * uiScale

                            ExpandableQrTile {
                                // anchors.centerIn: parent
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: modelData.source
                                title: modelData.title
                                popupTitle: modelData.popupTitle
                                biFamily: (typeof win !== "undefined") ? win.biFamily : ""
                                previewWidth: 200
                                previewHeight: previewWidth
                                expandedMaxSize: 720
                                showButton: false
                                previewUsesImage: false
                                previewIcon: modelData.icon
                                previewIconSize: 170 + (modelData.iconAdjust ? modelData.iconAdjust : 0)
                                showExpandHint: false
                            }

                            // Item {
                            //     width: parent.width
                            //     height: parent.height - 92 * uiScale

                            //     ExpandableQrTile {
                            //         anchors.centerIn: parent
                            //         source: modelData.source
                            //         title: modelData.title
                            //         popupTitle: modelData.popupTitle
                            //         biFamily: (typeof win !== "undefined") ? win.biFamily : ""
                            //         previewWidth: 220
                            //         previewHeight: previewWidth
                            //         expandedMaxSize: 1040
                            //         showButton: false
                            //         previewUsesImage: false
                            //         previewIcon: modelData.icon
                            //         showExpandHint: false
                            //     }
                            // }

                            Text {
                                text: modelData.title
                                color: "#ffffff"
                                font.pixelSize: 24 * uiScale
                                font.bold: true
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width
                                // verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
