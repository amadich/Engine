import QtQuick
import QtQuick.Controls
import "WizardStyle.js" as S

ComboBox {
    id: control
    implicitHeight: 29
    implicitWidth: 160
    leftPadding: 9
    rightPadding: 27
    font.pixelSize: 12
    hoverEnabled: true
    contentItem: Text {
        text: control.displayText
        color: control.enabled ? S.title : S.faint
        font: control.font
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    indicator: Text {
        x: control.width - width - 9
        anchors.verticalCenter: parent.verticalCenter
        text: "⌄"
        font.pixelSize: 16
        color: S.muted
    }
    background: Rectangle {
        radius: 2
        color: control.down ? S.hover : S.input
        border.width: control.activeFocus ? 1 : 0
        border.color: S.accent
    }
    delegate: ItemDelegate {
        required property int index
        required property var modelData
        width: control.width
        height: 29
        padding: 7
        highlighted: control.highlightedIndex === index
        contentItem: Text {
            text: String(modelData)
            font.pixelSize: 12
            color: S.title
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle { color: parent.highlighted ? S.selected : parent.hovered ? S.hover : S.side }
    }
    popup: Popup {
        y: control.height
        width: control.width
        implicitHeight: contentItem.implicitHeight + 4
        padding: 2
        contentItem: ListView {
            clip: true
            implicitHeight: Math.min(contentHeight, 260)
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle { color: S.side; border.color: S.line; border.width: 1; radius: 2 }
    }
}
