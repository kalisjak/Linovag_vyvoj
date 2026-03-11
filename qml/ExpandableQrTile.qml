import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: tile

    property string source: ""
    property string title: ""
    property string biFamily: ""
    property real previewWidth: 340
    property real previewHeight: 340
    property bool showButton: true
    property real expandedMaxSize: 980
    property bool previewUsesImage: true
    property string previewIcon: "\uF6AE"

    width: previewWidth
    height: showButton ? previewHeight + 92 : previewHeight

    function toggleExpanded() {
        if (qrPopup.opened)
            qrPopup.close()
        else if (source !== "")
            qrPopup.open()
    }

    Rectangle {
        id: previewFrame
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: tile.previewWidth
        height: tile.previewHeight
        color: "transparent"


        Image {
            visible: tile.previewUsesImage
            anchors.fill: parent
            anchors.margins: 12
            source: tile.source
            fillMode: Image.PreserveAspectFit
            cache: false
        }

        Text {
            visible: !tile.previewUsesImage
            anchors.centerIn: parent
            text: tile.previewIcon
            color: hoverArea.containsMouse ? "#ffffff" : "#c1d2e4"
            font.family: tile.biFamily
            font.pixelSize: Math.min(parent.width, parent.height) * 0.75
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            width: 56
            height: 56
            radius: 28
            color: "#12263b"
            border.color: "#dfe7f1"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\uF401"
                color: "#ffffff"
                font.family: tile.biFamily
                font.pixelSize: 32
            }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: true
                NumberAnimation { to: 0.3; duration: 600 }
                NumberAnimation { to: 1.0; duration: 800 }
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: tile.toggleExpanded()
        }
    }

    Rectangle {
        visible: tile.showButton
        anchors.top: previewFrame.bottom
        anchors.topMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        width: 160
        height: 56
        radius: 18
        color: buttonArea.pressed ? "#12345a" : "#0c1a2a"
        border.width: 2
        border.color: "#dfe7f1"

        Row {
            anchors.centerIn: parent
            spacing: 12

            Text {
                text: "QR"
                color: "#f3f6fa"
                font.pixelSize: 24
                font.bold: true
            }

            Text {
                text: "\uF401"
                color: "#f3f6fa"
                font.family: tile.biFamily
                font.pixelSize: 32
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            onClicked: tile.toggleExpanded()
        }
    }

    Popup {
        id: qrPopup
        parent: Overlay.overlay
        modal: false
        focus: true
        padding: 0
        width: rotateScene ? 720 : 1280
        height: rotateScene ? 1280  : 720
        background: Rectangle {
            color: "#d0000000"
        }

        contentItem: Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: qrPopup.close()
            }

            Item {
                anchors.centerIn: parent
                width: qrPopup.width
                height:qrPopup.height
                rotation: (typeof win !== "undefined" && win.rotateScene) ? 90 : 0
                transformOrigin: Item.Center

                Column {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 14

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 640
                        height: width
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            anchors.margins: 10
                            source: tile.source
                            fillMode: Image.PreserveAspectFit
                            cache: false
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: qrPopup.close()
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 80
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: tile.title
                            color: "#f3f6fa"
                            font.pixelSize: 34
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }
                    }
                }
            }
        }
    }
}
