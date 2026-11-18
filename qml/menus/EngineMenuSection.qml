import QtQuick
import QtQuick.Controls
import JeridiEngine

MenuItem {
    id: root
    enabled: false
    implicitHeight: 25
    padding: 0
    leftPadding: 13
    contentItem: Label {
        text: root.text.toUpperCase()
        font.pixelSize: 9
        font.weight: Font.DemiBold
        font.letterSpacing: 0.7
        color: Theme.colors.muted
        verticalAlignment: Text.AlignVCenter
    }
    background: Item { }
}
