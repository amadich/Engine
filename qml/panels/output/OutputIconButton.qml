import QtQuick
import QtQuick.Controls
import JeridiEngine

// Shared compact control for actions in the Output Console.
Button {
    id: root
    property url iconSource: ""
    property string hint: ""
    property int iconSize: 15
    property bool active: false

    implicitWidth: 29
    implicitHeight: 27
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    opacity: enabled ? 1 : 0.33

    background: Rectangle {
        radius: 5
        color: root.active ? Theme.colors.selection
              : root.down ? Theme.colors.selection
              : root.hovered ? Theme.colors.hover
              : "transparent"
        border.width: root.active || root.activeFocus ? 1 : 0
        border.color: Theme.colors.accent
    }

    contentItem: Item {
        Image {
            anchors.centerIn: parent
            source: root.iconSource
            width: root.iconSize
            height: root.iconSize
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(32, 32)
            opacity: root.enabled ? 0.95 : 0.45
        }
    }

    ToolTip.visible: root.hovered && root.hint.length > 0
    ToolTip.text: root.hint
    ToolTip.delay: 420

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
