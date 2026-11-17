import QtQuick
import QtQuick.Controls
import JeridiEngine

SpinBox {
    id: root
    from: 0
    to: 100
    stepSize: 1
    editable: true
    implicitHeight: 25
    implicitWidth: 76
    font.pixelSize: 10
    HoverHandler { cursorShape: root.enabled ? Qt.IBeamCursor : Qt.ForbiddenCursor }

    background: Rectangle {
        radius: 3
        color: !root.enabled ? Theme.colors.panel
             : root.hovered ? Theme.colors.hover : Theme.colors.surface
        border.width: 1
        border.color: root.activeFocus ? Theme.colors.accent : Theme.colors.border
    }

    contentItem: TextInput {
        text: root.textFromValue(root.value, root.locale)
        font: root.font
        color: root.enabled ? Theme.colors.text : Theme.colors.disabled
        selectionColor: Theme.colors.selection
        selectedTextColor: Theme.colors.text
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        leftPadding: 21
        rightPadding: 21
        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        selectByMouse: true
    }

    down.indicator: Rectangle {
        x: 0
        y: 1
        width: 20
        height: root.height - 2
        radius: 2
        color: !root.down.enabled ? Theme.colors.panel
             : root.down.pressed ? Theme.colors.selection
             : minusHover.hovered ? Theme.colors.hover : Theme.colors.control
        HoverHandler {
            id: minusHover
            cursorShape: root.down.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
        }
        Text {
            anchors.centerIn: parent
            text: "−"
            font.pixelSize: 14
            color: root.down.enabled ? Theme.colors.text : Theme.colors.disabled
        }
    }

    up.indicator: Rectangle {
        x: root.width - width
        y: 1
        width: 20
        height: root.height - 2
        radius: 2
        color: !root.up.enabled ? Theme.colors.panel
             : root.up.pressed ? Theme.colors.selection
             : plusHover.hovered ? Theme.colors.hover : Theme.colors.control
        HoverHandler {
            id: plusHover
            cursorShape: root.up.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
        }
        Text {
            anchors.centerIn: parent
            text: "+"
            font.pixelSize: 13
            color: root.up.enabled ? Theme.colors.text : Theme.colors.disabled
        }
    }
}
