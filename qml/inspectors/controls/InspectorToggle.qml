import QtQuick
import QtQuick.Controls
import JeridiEngine

CheckBox {
    id: root
    implicitHeight: 24
    font.pixelSize: 10
    spacing: 7
    HoverHandler { cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor }

    indicator: Rectangle {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: 15
        height: 15
        radius: 3
        color: !root.enabled ? Theme.colors.panel
             : root.checked ? Theme.colors.selection
             : root.hovered ? Theme.colors.hover : Theme.colors.surface
        border.width: 1
        border.color: root.enabled && (root.checked || root.hovered) ? Theme.colors.accent
                      : Theme.colors.border
        Text {
            anchors.centerIn: parent
            text: "✓"
            font.pixelSize: 11
            font.bold: true
            color: root.enabled ? Theme.colors.text : Theme.colors.disabled
            visible: root.checked
        }
    }
    contentItem: Text {
        text: root.text
        font: root.font
        color: root.enabled ? Theme.colors.text : Theme.colors.disabled
        leftPadding: root.indicator.width + root.spacing
        verticalAlignment: Text.AlignVCenter
    }
}
