import QtQuick
import QtQuick.Controls
import JeridiEngine

TextField {
    id: root
    implicitHeight: 26
    implicitWidth: 90
    leftPadding: 8
    rightPadding: 7
    topPadding: 3
    bottomPadding: 3
    font.pixelSize: 11
    selectByMouse: true
    color: Theme.colors.text
    selectionColor: Theme.colors.selection
    selectedTextColor: Theme.colors.text
    placeholderTextColor: Theme.colors.muted

    background: Rectangle {
        radius: 3
        color: root.readOnly ? Theme.colors.panel : Theme.colors.surface
        border.width: 1
        border.color: root.activeFocus ? Theme.colors.accent : Theme.colors.border
    }
}
