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

    Row {
        id: dockN
        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: 35 * uiScale


        Repeater {
            model: dock.count

            delegate: Rectangle {
                width: 26 * uiScale
                height: 26 * uiScale
                radius: 13 * uiScale

                color: (index === 0
                        ? "transparent"
                        : (index === dock.currentIndex ? "#EDEFF2" : "transparent"))

                border.color: "#c0c0c0c0"
                border.width: index === 0 ? 0 : 2   // first dot is "home" (no border)

                Loader {
                    anchors.centerIn: parent
                    visible: index === 0
                    sourceComponent: biIcon
                    onLoaded: {
                        item.code = Qt.binding(function() {
                            return (dock.currentIndex === 0 ? "\uF424" : "\uF425");
                        })
                        item.px = 37 * uiScale
                        item.iconColor = "#EDEFF2"
                    }
                }

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
    }
}