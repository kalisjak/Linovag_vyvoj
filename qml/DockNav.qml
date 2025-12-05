import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15


Item {
    id: dock
    property real uiScale: 1.0

    width: parent ? parent.width : 800 * uiScale
    height: 60 * uiScale

    // API
    property int count: 3
    property int currentIndex: 0
    signal goHome()
    signal dotClicked(int index)

    // jediný řádek uprostřed
    Row {
        id: dockN
        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: 24

        // tečky
        Repeater {
            model: dock.count
            delegate: Rectangle {
                width: 24 * uiScale; height: 24 * uiScale; radius: 12 * uiScale
                // anchors.topMargin: 3 * uiScale
                color: (index === dock.currentIndex) ? "#EDEFF2" : "transparent"
                border.color: "#c0c0c0c0"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: dock.dotClicked(index)
                }
            }
        }

        // domeček
        Item {
            // anchors.bottomMargin: 40 * uiScale
            width: 40 * uiScale; height: 40 * uiScale;

            Text {
                anchors.centerIn: parent
                anchors.verticalCenter: parent.verticalCenter
                // anchors.bottomMargin: 10
                text: "⌂"
                font.pixelSize: 40* uiScale
                color: "#EDEFF2"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: dock.goHome()
            }
        }
    }
}