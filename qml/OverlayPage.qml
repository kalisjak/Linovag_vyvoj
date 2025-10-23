// OverlayPage.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    id: base
    property var pageStack
    function goBack() {
        var stk = base.pageStack || base.StackView.view
        if (!stk) return
        if (stk.depth > 1) stk.pop(); else stk.clear()
    }
}
