import QtQuick
import QtQuick.Controls
import "WizardStyle.js" as S

Button {
    id: control
    property bool primary: false
    implicitHeight: 30
    implicitWidth: 92
    hoverEnabled: true
    font.pixelSize: 12
    font.weight: primary ? Font.DemiBold : Font.Normal
    leftPadding: 12
    rightPadding: 12
    contentItem: Text {
        text: control.text
        font: control.font
        color: !control.enabled ? S.faint : control.primary ? "white" : S.title
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 3
        color: !control.enabled ? "#36383c" : control.primary
            ? (control.down ? "#2565b6" : control.hovered ? "#438de5" : "#3579cc")
            : (control.down ? "#41444b" : control.hovered ? "#44474d" : "#3a3c41")
    }
}
