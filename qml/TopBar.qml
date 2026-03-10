import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: bar
    property real uiScale: 1.0
    property bool overlayMode: false
    property string overlayTitle: ""

    readonly property int swType: backend.softwareType
    readonly property bool isDual: swType === 22

    // indikace
    readonly property bool forcedActive: backend.forcedSensors
    readonly property bool condensHot: backend.value5 >= 45.0   // CRITICAL_TEMPERATURE_KONDENZ (config.hpp)

    // stavy z backendu (napojené z cooling workerů)
    readonly property bool errorActive: backend.errorActive

    readonly property bool cooling1Active: backend.coolingActive
    readonly property bool defrost1Active: backend.defrostActive
    readonly property bool compressor1On: backend.compressorOn
    readonly property bool drip1Active: backend.dripHoldActive

    readonly property bool cooling2Active: backend.cooling2Active
    readonly property bool defrost2Active: backend.defrost2Active
    readonly property bool compressor2On: backend.compressor2On
    readonly property bool drip2Active: backend.dripHold2Active

    implicitHeight: 78 * uiScale
    height: implicitHeight
    color: "transparent"
    anchors.left: parent.left
    anchors.right: parent.right

    // reálný čas uprostřed
    property string timeText: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: bar.timeText = Qt.formatTime(new Date(), "HH:mm")
    }

    // dělící linka dole
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#c7c7c7bd"
    }

    signal openWifi()
    signal openSettings()
    signal openLogin()
    signal navigateBack()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 8
        spacing: 8

        // ===== LEFT TEXTS =====
        RowLayout {
            id: leftInfo
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.fillWidth: true
            spacing: 12 * uiScale

            Row {
                visible: bar.overlayMode
                spacing: 14 * uiScale
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                Rectangle {
                    width: 132 * uiScale
                    height: 48 * uiScale
                    radius: 14 * uiScale
                    color: backArea.pressed ? "#5a5a5ac4" : "#33000000"
                    border.width: 2 * uiScale
                    border.color: "#c6c5df"

                    Text {
                        anchors.centerIn: parent
                        text: "← Zpět"
                        color: "#EDEFF2"
                        font.pixelSize: 24 * uiScale
                        font.bold: true
                    }

                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        onClicked: bar.navigateBack()
                    }
                }

                Label {
                    text: bar.overlayTitle
                    color: "#EDEFF2"
                    font.pixelSize: 30 * uiScale
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Label {
                id: typeLabel
                visible: !bar.overlayMode
                text: bar.isDual ? "Type 2+2" : "Type - 3"
                color: "#E0E0E0"
                font.pixelSize: 26 * uiScale
                Layout.alignment: Qt.AlignVCenter
            }

            Label {
                visible: !bar.overlayMode && bar.forcedActive
                text: "FORCED"
                color: "#FFD54F"
                font.pixelSize: 22 * uiScale
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Label {
                visible: !bar.overlayMode && bar.condensHot
                text: "CONDENS"
                color: "#FF8A65"
                font.pixelSize: 22 * uiScale
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true } // spacer
        }

        // ===== CENTER TIME =====
        Label {
            id: clockLabel
            text: bar.timeText
            color: "#EDEFF2"
            font.pixelSize: 26 * uiScale
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth: 130 * uiScale
        }

        // ===== RIGHT ICONS =====
        Row {
            id: rightIcons
            spacing: 22 * uiScale
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            // 0) Varování (bliká žlutě při chybě)
            ToolButton {
                id: warnBtn
                visible: bar.errorActive
                contentItem: biIcon.createObject(this, {
                    "code": "\uF33A",
                    "px": 48 * uiScale,
                    "iconColor": "#FFD54F"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "transparent"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
                SequentialAnimation on opacity {
                    running: bar.errorActive
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.0; duration: 500 }
                    NumberAnimation { from: 1.0; to: 0.1; duration: 500 }
                    NumberAnimation { from: 0.1; to: 1.0; duration: 500 }
                }
            }

            // --- TYPE 3: cooling + compressor
            ToolButton {
                id: cooling1Btn
                visible: !bar.isDual && bar.cooling1Active
                contentItem: biIcon.createObject(this, {
                    "code": "\uF56E",
                    "px": 48 * uiScale,
                    "iconColor": "#4FC3F7"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }
            
            ToolButton {
                id: defrost1Btn
                visible: !bar.isDual && bar.defrost1Active
                contentItem: biIcon.createObject(this, {
                    "code": "\uF30C",
                    "px": 48 * uiScale,
                    "iconColor": "#EF5350"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
                SequentialAnimation on opacity {
                    running: bar.defrost1Active
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.0; duration: 500 }
                    NumberAnimation { from: 1.0; to: 0.1; duration: 500 }
                    NumberAnimation { from: 0.1; to: 1.0; duration: 500 }
                }
            }

            ToolButton {
                id: drip1Btn
                visible: !bar.isDual && bar.drip1Active && !bar.defrost1Active
                contentItem: biIcon.createObject(this, {
                    "code": "\uF30B",
                    "px": 48 * uiScale,
                    "iconColor": "#EF5350"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            ToolButton {
                id: compressor1Btn
                visible: !bar.isDual
                contentItem: biIcon.createObject(this, {
                    "code": "\uF670",
                    "px": 48 * uiScale,
                    "iconColor": Qt.binding(function() { return bar.compressor1On ? "#3abb41" : "#EF5350"; })
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            // --- TYPE 22: cooling1 + compressor1 | cooling2 + compressor2
            ToolButton {
                id: cooling1Btn22
                visible: bar.isDual && bar.cooling1Active
                contentItem: biIcon.createObject(this, {
                    "code": "\uF56E",
                    "px": 48 * uiScale,
                    "iconColor": "#4FC3F7"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            ToolButton {
                id: defrost1Btn22
                visible: bar.isDual && bar.defrost1Active
                contentItem: biIcon.createObject(this, {
                    "code": "\uF30C",
                    "px": 48 * uiScale,
                    "iconColor": "#EF5350"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
                SequentialAnimation on opacity {
                    running: bar.defrost1Active
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.0; duration: 500 }
                    NumberAnimation { from: 1.0; to: 0.1; duration: 500 }
                    NumberAnimation { from: 0.1; to: 1.0; duration: 500 }
                }
            }

            ToolButton {
                id: drip1Btn22
                visible: bar.isDual && bar.drip1Active && !bar.defrost1Active
                contentItem: biIcon.createObject(this, {
                    "code": "\uF30B",
                    "px": 48 * uiScale,
                    "iconColor": "#EF5350"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            ToolButton {
                id: compressor1Btn22
                visible: bar.isDual
                contentItem: biIcon.createObject(this, {
                    "code": "\uF670",
                    "px": 48 * uiScale,
                    "iconColor": Qt.binding(function() { return bar.compressor1On ? "#3abb41" : "#EF5350"; })
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            Rectangle {
                visible: bar.isDual
                width: 2
                height: 48 * uiScale
                radius: 1
                color: "#c7c7c7bd"
                anchors.verticalCenter: parent.verticalCenter
            }

            ToolButton {
                id: cooling2Btn22
                visible: bar.isDual && bar.cooling2Active
                contentItem: biIcon.createObject(this, {
                    "code": "\uF56E",
                    "px": 48 * uiScale,
                    "iconColor": "#4FC3F7"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            ToolButton {
                id: defrost2Btn22
                visible: bar.isDual && bar.defrost2Active
                contentItem: biIcon.createObject(this, {
                    "code": "\uF30C",
                    "px": 48 * uiScale,
                    "iconColor": "#EF5350"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
                SequentialAnimation on opacity {
                    running: bar.defrost2Active
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.0; duration: 500 }
                    NumberAnimation { from: 1.0; to: 0.1; duration: 500 }
                    NumberAnimation { from: 0.1; to: 1.0; duration: 500 }
                }
            }

            ToolButton {
                id: drip2Btn22
                visible: bar.isDual && bar.drip2Active && !bar.defrost2Active
                contentItem: biIcon.createObject(this, {
                    "code": "\uF30B",
                    "px": 48 * uiScale,
                    "iconColor": "#EF5350"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            ToolButton {
                id: compressor2Btn22
                visible: bar.isDual
                contentItem: biIcon.createObject(this, {
                    "code": "\uF670",
                    "px": 48 * uiScale,
                    "iconColor": Qt.binding(function() { return bar.compressor2On ? "#3abb41" : "#EF5350"; })
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            // Wi‑Fi / Settings / Person (beze změny)
            ToolButton {
                id: wifiBtn
                onClicked: bar.openWifi()
                contentItem: biIcon.createObject(this, {
                    "code": Qt.binding(function() { return backend.wifiConnected ? "\uF61C" : "\uF3EF"; }),
                    "px": 48 * uiScale,
                    "iconColor": Qt.binding(function() { return wifiBtn.down ? "#C0C3C8" : "#EDEFF2"; })
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: wifiBtn.down ? "#66000000" : "transparent"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            ToolButton {
                id: settingsBtn
                onClicked: bar.openSettings()
                contentItem: biIcon.createObject(this, {
                    "code": Qt.binding(function() { return settingsBtn.down ? "\uF3E2" : "\uF3E5"; }),
                    "px": 48 * uiScale,
                    "iconColor": "#EDEFF2"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: settingsBtn.down ? "#66000000" : "transparent"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }

            ToolButton {
                id: loginBtn
                onClicked: bar.openLogin()
                contentItem: biIcon.createObject(this, {
                    "code": Qt.binding(function() { return loginBtn.down ? "\uF4DA" : "\uF4E1"; }),
                    "px": 48 * uiScale,
                    "iconColor": "#EDEFF2"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: loginBtn.down ? "#66000000" : "transparent"
                    implicitWidth: 58 * uiScale
                    implicitHeight: 58 * uiScale
                }
            }
        }
    }
}
