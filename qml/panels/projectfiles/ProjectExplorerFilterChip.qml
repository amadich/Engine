import QtQuick
import QtQuick.Controls
import JeridiEngine

Rectangle {
    id: root
    property string label: "All"
    property bool selected: false
    property int count: -1
    signal triggered()

    implicitHeight: 27
    implicitWidth: 65
    radius: 4
    color: selected ? Theme.colors.selection
          : mouse.containsMouse ? Theme.colors.hover : Theme.colors.control
    border.width: selected || mouse.containsMouse ? 1 : 0
    border.color: selected ? Theme.colors.accent : Theme.colors.border
    Behavior on color { ColorAnimation { duration: 100 } }

    Row {
        anchors.centerIn: parent
        spacing: 4
        Text {
            text: root.label
            color: root.selected ? Theme.colors.text : Theme.colors.muted
            font.pixelSize: 10
            font.bold: root.selected
        }
        Text {
            visible: root.count >= 0
            text: root.count
            color: root.selected ? Theme.colors.accent : Theme.colors.disabled
            font.pixelSize: 9
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
    Accessible.role: Accessible.Button
    Accessible.name: label + (selected ? ", active" : "")
}
