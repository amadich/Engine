import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    property string label: "All"
    property int count: 0
    property bool selected: false
    signal triggered()

    implicitHeight: 25
    radius: 4
    color: selected ? Theme.colors.selection
           : mouse.containsMouse ? Theme.colors.hover : Theme.colors.control
    border.width: 1
    border.color: selected ? Theme.colors.accent : Theme.colors.border
    Behavior on color { ColorAnimation { duration: 90 } }

    RowLayout {
        anchors.centerIn: parent
        spacing: 4
        Label {
            text: root.label
            font.pixelSize: 10
            font.bold: root.selected
            color: Theme.colors.text
        }
        Label {
            text: String(root.count)
            font.pixelSize: 9
            color: root.selected ? Theme.colors.accent : Theme.colors.muted
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
    Accessible.name: root.label + " " + root.count
}
