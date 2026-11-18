import QtQuick
import QtQuick.Controls
import JeridiEngine

// Compact, native-feeling menu surface shared by all top-level and nested menus.
Menu {
    id: root
    property int menuWidth: 286

    width: menuWidth
    padding: 5
    topPadding: 6
    bottomPadding: 6
    popupType: Popup.Window
    overlap: 3

    delegate: EngineMenuItem { }

    background: Rectangle {
        implicitWidth: root.menuWidth
        radius: 6
        color: Theme.dark ? "#2B2D30" : "#FAFBFD"
        border.width: 1
        border.color: Theme.dark ? "#505259" : "#B9C8D8"
    }
}
