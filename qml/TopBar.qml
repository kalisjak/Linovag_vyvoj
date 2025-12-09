import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: bar
    property real uiScale: 1.0

    // stavové příznaky pro ikonky vpravo
    property bool errorActive: true      // TODO: napojit na backend
    property bool coolingActive: true    // TODO: napojit na backend
    property bool defrostActive: false    // TODO: napojit na backend
    property bool compressorOn: true      // TODO: napojit na backend

    implicitHeight: 70 * uiScale
    height: implicitHeight

    color: "transparent"
    anchors.left: parent.left
    anchors.right: parent.right

    // dělící linka dole
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#c7c7c7bd"      // tenká jemná linka
    }

    signal openWifi()
    signal openSettings()
    signal openLogin()

    RowLayout { 
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Vlevo výrobní číslo (z backendu)
        Label {
            id: sn
            text: (typeof backend !== "undefined" && backend.serialNumber && backend.serialNumber.length > 0)
                  ? backend.serialNumber : "SN-000000"
            color: "#E0E0E0"
            font.pixelSize: 26 * uiScale
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.fillWidth: true
        }

        // Vpravo Wi-Fi / Stavové ikony / Nastavení / Přihlášení
        Row {
            spacing: 30 * uiScale
            // Layout.fillWidth: true

            // 1) Varování (bliká žlutě při chybě)
            ToolButton {
                id: warnBtn
                visible: bar.errorActive
                contentItem: biIcon.createObject(this, {
                    "code": "\uF33A",
                    "px": 44 * uiScale,
                    "iconColor": Qt.binding(function() {
                        return "#FFD54F";    // žlutá
                    })
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "transparent"
                    implicitWidth: 52 * uiScale
                    implicitHeight: 52 * uiScale
                }
                SequentialAnimation on opacity {
                    running: bar.errorActive
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.0; duration: 500 }
                    NumberAnimation { from: 1.0; to: 0.1; duration: 500 }
                    NumberAnimation { from: 0.1; to: 1.0; duration: 500 }
                }
            }

            // 2) Chlazení aktivní
            ToolButton {
                id: coolingBtn
                visible: bar.coolingActive
                contentItem: biIcon.createObject(this, {
                    "code": "\uF56E",
                    "px": 44 * uiScale,
                    "iconColor": "#4FC3F7"   // modrá
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 52 * uiScale
                    implicitHeight: 52 * uiScale
                }
            }

            // 3) Odmrazování aktivní
            ToolButton {
                id: defrostBtn
                visible: bar.defrostActive
                contentItem: biIcon.createObject(this, {
                    "code": "\uF30B",
                    "px": 44 * uiScale,
                    "iconColor": "#EF5350"   // červená
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 52 * uiScale
                    implicitHeight: 52 * uiScale
                }
            }

            // 4) Kompresor zap/vyp (zelený / červený)
            ToolButton {
                id: compressorBtn
                contentItem: biIcon.createObject(this, {
                    "code": "\uF670",        // libovolná ikona pro kompresor/stroj
                    "px": 44 * uiScale,
                    "iconColor": Qt.binding(function() {
                        return bar.compressorOn ? "#3abb41" : "#EF5350";
                    })
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: "#00000033"
                    implicitWidth: 52 * uiScale
                    implicitHeight: 52 * uiScale
                }
            }

            // 5) Wi-Fi (lehce stmavne při stlačení)
            ToolButton {
                id: wifiBtn
                onClicked: bar.openWifi()
                contentItem: biIcon.createObject(this, {
                    "code": "\uF61C",
                    "px": 44 * uiScale,
                    "iconColor": Qt.binding(function() {
                        return wifiBtn.down ? "#C0C3C8" : "#EDEFF2";
                    })
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: wifiBtn.down ? "#00000066" : "#00000033"
                    implicitWidth: 52 * uiScale
                    implicitHeight: 52 * uiScale
                }
            }

            // 6) Nastavení – při stlačení jiná ikonka (\uF3E5 → \uF3E2)
            ToolButton {
                id: settingsBtn
                onClicked: bar.openSettings()
                contentItem: biIcon.createObject(this, {
                    "code": Qt.binding(function() {
                        return settingsBtn.down ? "\uF3E2" : "\uF3E5";
                    }),
                    "px": 44 * uiScale,
                    "iconColor": "#EDEFF2"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: settingsBtn.down ? "#00000066" : "#00000033"
                    implicitWidth: 52 * uiScale
                    implicitHeight: 52 * uiScale
                }
            }

            // 7) Přihlášení / uživatel – při stlačení jiná ikonka (\uF4E1 → \uF4DA)
            ToolButton {
                id: loginBtn
                onClicked: bar.openLogin()
                contentItem: biIcon.createObject(this, {
                    "code": Qt.binding(function() {
                        return loginBtn.down ? "\uF4DA" : "\uF4E1";
                    }),
                    "px": 44 * uiScale,
                    "iconColor": "#EDEFF2"
                })
                background: Rectangle {
                    radius: 7 * uiScale
                    color: loginBtn.down ? "#00000066" : "#00000033"
                    implicitWidth: 52 * uiScale
                    implicitHeight: 52 * uiScale
                }
            }
        }

    }
}
