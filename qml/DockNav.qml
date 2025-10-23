import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15


Item {
    id: dock
    width: parent ? parent.width : 800
    height: 40

    // API
    property int count: 3
    property int currentIndex: 0
    signal goHome()
    signal dotClicked(int index)

    // jediný řádek uprostřed
    Row {
        id: r
        anchors.centerIn: parent
        spacing: 24

        // tečky
        Repeater {
            model: dock.count
            delegate: Rectangle {
                width: 12; height: 12; radius: 6
                // studená světle šedá → méně „žloutne“ na teplé tapetě
                color: (index === dock.currentIndex) ? "#EDEFF2" : "#50505096"
                border.color: "#c0c0c0c0"
                border.width: 1

                // jemný „halo“ podklad (pomůže proti barvení pozadím)
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 6
                    height: parent.height + 6
                    radius: (width/2)
                    color: "#00000033"
                    z: -1
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: dock.dotClicked(index)
                }
            }
        }

        // domeček
        Item {
            width: 28; height: 28

            Rectangle {
                anchors.centerIn: parent
                width: 28; height: 28; radius: 14
                color: "#00000033"   // halo
                z: -1
            }
            Text {
                anchors.centerIn: parent
                text: "⌂"
                font.pixelSize: 27
                color: "#EDEFF2"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: dock.goHome()
            }
        }
    }
}