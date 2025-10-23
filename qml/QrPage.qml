import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    title: "QR kód"
    background: Item {}
    visible: SwipeView.isCurrentItem

    contentItem: Item {
        anchors.fill: parent
        Column {
            anchors.centerIn: parent
            Image {
                id: qr
                source: "qrc:/qml/qr_web.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                width: 250
                height: 250
            }
        }
    }
}
