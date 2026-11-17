import QtQuick
import QtQuick.Controls
import JeridiEngine

ComboBox {
    id: root
    implicitHeight: 26
    implicitWidth: 96
    font.pixelSize: 11
    leftPadding: 7
    rightPadding: 23

    contentItem: Text {
        leftPadding: 7
        rightPadding: 23
        text: root.displayText
        font: root.font
        color: Theme.colors.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: root.width - width - 8
        y: (root.height - height) / 2
        text: "▾"
        font.pixelSize: 12
        color: Theme.colors.muted
    }

    background: Rectangle {
        radius: 3
        color: root.down ? Theme.colors.hover : Theme.colors.surface
        border.width: 1
        border.color: root.activeFocus ? Theme.colors.accent : Theme.colors.border
    }

    delegate: ItemDelegate {
        width: root.width
        implicitHeight: 27
        highlighted: root.highlightedIndex === index
        contentItem: Text {
            text: modelData
            font.pixelSize: 11
            color: Theme.colors.text
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: parent.highlighted ? Theme.colors.selection : Theme.colors.surface
        }
    }

    popup: Popup {
        y: root.height + 2
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight + 6, 220)
        padding: 3
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle {
            color: Theme.colors.surface
            radius: 4
            border.width: 1
            border.color: Theme.colors.border
        }
    }
}
