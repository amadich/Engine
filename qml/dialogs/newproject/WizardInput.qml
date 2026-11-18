import QtQuick
import QtQuick.Controls
import "WizardStyle.js" as S

TextField {
    id: field
    implicitHeight: 29
    leftPadding: 9
    rightPadding: 8
    topPadding: 3
    bottomPadding: 3
    selectByMouse: true
    font.pixelSize: 12
    color: S.title
    placeholderTextColor: S.faint
    selectionColor: S.accent
    selectedTextColor: "white"
    background: Rectangle {
        radius: 2
        color: S.input
        border.width: field.activeFocus ? 1 : 0
        border.color: S.accent
    }
}
