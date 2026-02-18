// OverlayPage.qml
// Lightweight helper used for full-screen overlay pages pushed into StackView.
// It provides a dim background and a simple goBack().

import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    id: base

    // Optional explicit stack reference (otherwise uses StackView.view)
    property var pageStack

    // If your app uses a fixed TopBar above the StackView content,
    // content below should start at y=0 (already below the bar).
    // For overlays that want to visually "reach" the TopBar area on the left,
    // they can place items with negative y.

    // Common dim layer (can be overridden per-page)
    background: Rectangle {
        color: "#000000"
        opacity: 0.35
    }

    function goBack() {
        var stk = base.pageStack || base.StackView.view
        if (!stk) return
        if (stk.depth > 1) stk.pop(); else stk.clear()
    }
}
