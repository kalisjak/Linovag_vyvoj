import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

OverlayPage {
    id: page
    title: "Varování"

    readonly property real s: uiScale
    readonly property string lang: (backend && backend.appLanguage) ? backend.appLanguage : "cs"

    function tt(cs, en, de, dk) {
        switch (lang) {
        case "en": return en
        case "de": return de
        case "dk": return dk
        default: return cs
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#dd2e2e2e"
        z: -10
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.leftMargin: 14 * s
        anchors.rightMargin: 14 * s
        anchors.bottomMargin: 14 * s
        anchors.topMargin: 14 * s
        clip: true
        contentWidth: contentCol.width
        contentHeight: Math.max(height, contentCol.implicitHeight)
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: contentCol
            width: flick.width
            spacing: 14 * s

            Rectangle {
                width: parent.width - 20 * s
                radius: 20 * s
                color: "#cc2e2e2e"
                border.width: 1 * s
                border.color: "#ccc6c5df"
                height: Math.max(250 * s, warningCol.implicitHeight + 50 * s)

                Column {
                    id: warningCol
                    anchors.fill: parent
                    anchors.margins: 14 * s
                    spacing: 20 * s

                    Text {
                        text: tt("Varování a alarmy", "Warnings and alarms", "Warnungen und Alarme", "Advarsler og alarmer")
                        color: "#EDEFF2"
                        font.pixelSize: 40 * s
                        font.bold: true
                    }

                    Rectangle { width: parent.width; height: 1 * s; color: "#c6c5df"; opacity: 0.35 }

                    Rectangle {
                        width: parent.width
                        height: 150 * s
                        radius: 18 * s
                        color: "#1f3a66"
                        border.width: 2 * s
                        border.color: "#80c6c5df"

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 40 * s
                            text: tt("Stránka je připravená pro budoucí přehled varování.",
                                     "This page is ready for a future warning overview.",
                                     "Diese Seite ist fuer eine kuenftige Warnungsuebersicht vorbereitet.",
                                     "Denne side er klar til en fremtidig oversigt over advarsler.")
                            color: "#EDEFF2"
                            font.pixelSize: 28 * s
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
