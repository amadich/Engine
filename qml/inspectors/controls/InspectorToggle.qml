import QtQuick
import QtQuick.Controls
import JeridiEngine

CheckBox {
    id: root
    implicitHeight: 24
    font.pixelSize: 11
    spacing: 7

    indicator: Rectangle {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: 16
        height: 16
        radius: 3
        color: root.checked ? Theme.colors.selection : Theme.colors.surface
        border.width: 1
        border.color: root.checked ? Theme.colors.accent : Theme.colors.border
        Text {
            anchors.centerIn: parent
            text: "✓"
            font.pixelSize: 12
            font.bold: true
            color: Theme.colors.text
            visible: root.checked
        }
    }
    contentItem: Text {
        text: root.text
        font: root.font
        color: Theme.colors.text
        leftPadding: root.indicator.width + root.spacing
        verticalAlignment: Text.AlignVCenter
    }
}
