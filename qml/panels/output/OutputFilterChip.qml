import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// One selectable filter. The model and state belong to OutputLogStore.
Button {
    id: root
    property string caption: "All"
    property int count: 0
    property bool selected: false
    property color markerColor: Theme.colors.muted

    implicitWidth: Math.max(74, contents.implicitWidth + 19)
    implicitHeight: 25
    padding: 0
    hoverEnabled: true
    opacity: enabled ? 1 : 0.35

    background: Rectangle {
        radius: 5
        color: root.selected ? Theme.colors.selection
              : root.down ? Theme.colors.selection
              : root.hovered ? Theme.colors.hover : Theme.colors.control
        border.width: 1
        border.color: root.selected ? Theme.colors.accent : Theme.colors.border
    }

    contentItem: RowLayout {
        id: contents
        spacing: 5
        Item { Layout.preferredWidth: 2 }
        Rectangle {
            Layout.preferredWidth: 5
            Layout.preferredHeight: 5
            radius: 2.5
            color: root.markerColor
        }
        Label {
            text: root.caption
            font.pixelSize: 10
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            color: root.selected ? Theme.colors.text : Theme.colors.muted
        }
        Label {
            text: String(root.count)
            font.pixelSize: 9
            font.weight: Font.DemiBold
            color: root.selected ? Theme.colors.accent : Theme.colors.disabled
        }
        Item { Layout.preferredWidth: 2 }
    }

    ToolTip.visible: root.hovered
    ToolTip.text: root.caption + " • " + root.count + " messages"
    ToolTip.delay: 500

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
