import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    title: "Temp"
    background: Item {}
    visible: SwipeView.isCurrentItem

    contentItem: Flickable {
        id: scroll
        clip: true
        anchors.fill: parent
    
        contentWidth:  width
        contentHeight: form.implicitHeight + 1
    
        function ensureVisible(item) {
            if (!item) return
            // výška klávesnice = osk.height, necháme nad ní 12 px mezeru
            var pos = item.mapToItem(scroll.contentItem, 0, 0)
            var top = pos.y
            var bottom = pos.y + item.height
            var viewTop = scroll.contentY
            var viewBottom = scroll.contentY + scroll.height - (osk.show ? osk.height : 0) - 12
    
            if (bottom > viewBottom)
                scroll.contentY += (bottom - viewBottom)
            else if (top < viewTop)
                scroll.contentY = top
        }
    
        Item {
            id: form
            width: scroll.width
            implicitHeight: col.implicitHeight
    
            ColumnLayout {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 12
    
                GroupBox {
                    label: Label {
                        text: "Live data"
                        color: "white"
                        font.bold: true
                    }
                    Layout.fillWidth: true
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 24

                        ColumnLayout {
                            spacing: 4
                            Label { text: "Value 1:"; color: "white" }
                            Label {
                                text: Number(backend.value1).toLocaleString(Qt.locale(), 'f', 3)
                                color: "orange"
                                font.bold: true
                                font.pixelSize: 20
                            }
                        }

                        ColumnLayout {
                            spacing: 4
                            Label { text: "Value 2:"; color: "white" }
                            Label {
                                text: Number(backend.value2).toLocaleString(Qt.locale(), 'f', 3)
                                color: "orange"
                                font.bold: true
                                font.pixelSize: 20
                            }
                        }
                    }
                }

                GroupBox {
                    // přebarvený label
                    label: Label {
                        text: "Poslat zprávu do C++"
                        color: "white"
                        font.bold: true
                    }
                    Layout.fillWidth: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 8

                        TextField {
                            id: input
                            Layout.fillWidth: true
                            placeholderText: "zapiš teplotu…"
                            color: "white"
                            placeholderTextColor: "#CCCCCC"
                            background: Rectangle {
                                color: "#FFFFFF"; opacity: 0.3
                                radius: 6
                                border.color: "#FFFFFF"
                                border.width: 1
                            }
                            onPressed: forceActiveFocus()
                            onActiveFocusChanged: if (activeFocus && typeof scroll !== "undefined") scroll.ensureVisible(this)
                            onAccepted: sendBtn.clicked()
                            validator: DoubleValidator { bottom: -100; top: 1000; decimals: 3 }
                            inputMethodHints: Qt.ImhFormattedNumbersOnly | Qt.ImhPreferNumbers
                        }

                        Button {
                            id: sendBtn
                            text: "Send temp."
                            background: Rectangle {
                                implicitWidth: 100
                                implicitHeight: 30
                                color: "#607D8B"
                                radius: 6
                                border.color: "#546E7A"
                            }
                            contentItem: Text {
                                text: sendBtn.text
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                backend.sendMessage(input.text)
                                console.log("[QML] sent:", input.text)
                                input.clear()
                                input.forceActiveFocus()
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            Connections {
                target: osk
                function onExposedHeightChanged() {
                    if (osk.exposedHeight > 0) {
                        // klávesnice se objevuje → drž aktivní pole nad ní
                        scroll.ensureVisible(win.activeFocusItem)
                    } else {
                        // klávesnice zmizela → případně vrať scroll, ať "nestrká" obsah
                        var maxY = Math.max(0, scroll.contentHeight - scroll.height)
                        if (scroll.contentY > maxY) scroll.contentY = maxY
                        if (scroll.contentY < 0)    scroll.contentY = 0
                    }
                }
            }
        }
    }
}