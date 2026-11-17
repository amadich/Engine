import QtQuick
import QtQuick.Controls
import JeridiEngine

TextField {
    id: root
    implicitHeight: 25
    implicitWidth: 86
    leftPadding: 7
    rightPadding: 6
    topPadding: 3
    bottomPadding: 3
    font.pixelSize: 10
    selectByMouse: true
    color: enabled ? Theme.colors.text : Theme.colors.disabled
    selectionColor: Theme.colors.selection
    selectedTextColor: Theme.colors.text
    placeholderTextColor: Theme.colors.muted
    HoverHandler { cursorShape: root.enabled ? Qt.IBeamCursor : Qt.ForbiddenCursor }

    background: Rectangle {
        radius: 3
        color: !root.enabled || root.readOnly ? Theme.colors.panel
             : root.hovered ? Theme.colors.hover : Theme.colors.surface
        border.width: 1
        border.color: root.activeFocus ? Theme.colors.accent
                      : root.hovered && root.enabled ? Theme.colors.muted : Theme.colors.border
    }
    ToolTip.visible: hovered && !enabled
    ToolTip.text: "Field is unavailable until the configuration is loaded"
    ToolTip.delay: 500
}
