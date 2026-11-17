import QtQuick
import QtQuick.Controls
import JeridiEngine

SpinBox {
    id: root
    from: 0
    to: 100
    stepSize: 1
    editable: true
    implicitHeight: 26
    implicitWidth: 80
    font.pixelSize: 11

    background: Rectangle {
        radius: 3
        color: Theme.colors.surface
        border.width: 1
        border.color: root.activeFocus ? Theme.colors.accent : Theme.colors.border
    }

    contentItem: TextInput {
        text: root.textFromValue(root.value, root.locale)
        font: root.font
        color: Theme.colors.text
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
        color: root.down.pressed ? Theme.colors.selection : Theme.colors.control
        Text {
            anchors.centerIn: parent
            text: "−"
            font.pixelSize: 15
            color: root.down.enabled ? Theme.colors.text : Theme.colors.disabled
        }
    }

    up.indicator: Rectangle {
        x: root.width - width
        y: 1
        width: 20
        height: root.height - 2
        radius: 2
        color: root.up.pressed ? Theme.colors.selection : Theme.colors.control
        Text {
            anchors.centerIn: parent
            text: "+"
            font.pixelSize: 14
            color: root.up.enabled ? Theme.colors.text : Theme.colors.disabled
        }
    }
}
