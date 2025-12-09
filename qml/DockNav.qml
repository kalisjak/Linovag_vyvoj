import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15


Item {
    id: dock
    property real uiScale: 1.0

    width: parent ? parent.width : 800 * uiScale
    height: 60 * uiScale

    // API
    property int count: 4
    property int currentIndex: 0
    signal goHome()
    signal dotClicked(int index)

    // jediný řádek uprostřed
    Row {
        id: dockN
        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: 35 * uiScale


        Repeater {
            model: dock.count

            delegate: Rectangle {
                width: 24 * uiScale
                height: 24 * uiScale
                radius: 12 * uiScale

                // Barva tečky – pro index 0 žádný kruh, jen domeček
                color: (index === 0
                        ? "transparent"
                        : (index === dock.currentIndex ? "#EDEFF2" : "transparent"))

                border.color: "#c0c0c0c0"
                border.width: index === 0 ? 0 : 2   // první pozice bez okraje

                // --- první pozice = domeček místo tečky ---
                Loader {
                    anchors.centerIn: parent
                    visible: index === 0
                    sourceComponent: biIcon
                    onLoaded: {
                        // prázdný vs plný domeček podle currentIndex
                        // (použij si své kódy, jen ne \uF425 a \uF424)
                        item.code = Qt.binding(function() {
                            return (dock.currentIndex === 0 ? "\uF424" : "\uF425");
                        })
                        item.px = 35 * uiScale
                        item.iconColor = "#EDEFF2"
                    }
                }

                // --- ostatní pozice = tečky jako dřív ---
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: index !== 0
                    color: parent.color
                    border.color: parent.border.color
                    border.width: parent.border.width
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: dock.dotClicked(index)
                }
            }
        }

        // tečky
        // Repeater {
        //     model: dock.count
        //     delegate: Rectangle {
        //         width: 24 * uiScale; height: 24 * uiScale; radius: 12 * uiScale
        //         // anchors.topMargin: 3 * uiScale
        //         color: (index === dock.currentIndex) ? "#EDEFF2" : "transparent"
        //         border.color: "#c0c0c0c0"
        //         border.width: 1

        //         MouseArea {
        //             anchors.fill: parent
        //             onClicked: dock.dotClicked(index)
        //         }
        //     }
        // }

        // // domeček
        // Item {
        //     // anchors.bottomMargin: 40 * uiScale
        //     width: 40 * uiScale; height: 40 * uiScale;

        //     Text {
        //         anchors.centerIn: parent
        //         anchors.verticalCenter: parent.verticalCenter
        //         // anchors.bottomMargin: 10
        //         text: "⌂"
        //         font.pixelSize: 40* uiScale
        //         color: "#EDEFF2"
        //     }
        //     MouseArea {
        //         anchors.fill: parent
        //         onClicked: dock.goHome()
        //     }
        // }
    }
}