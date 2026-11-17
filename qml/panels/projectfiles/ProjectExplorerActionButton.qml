import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Small labeled action, matching the Inspector's compact interaction density.
Rectangle {
    id: root
    property string label: "Action"
    property url iconSource: ""
    property bool actionEnabled: true
    property bool primary: false
    property string hint: ""
    signal triggered()

    implicitHeight: 29
    implicitWidth: 90
    radius: 4
    color: !actionEnabled ? Theme.colors.surface
           : mouse.pressed ? Theme.colors.selection
           : mouse.containsMouse ? Theme.colors.hover
           : primary ? Theme.colors.selection : Theme.colors.control
    border.width: 1
    border.color: !actionEnabled ? Theme.colors.border
                  : mouse.containsMouse || primary ? Theme.colors.accent : Theme.colors.border
    opacity: actionEnabled ? 1 : 0.55
    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6
        Image {
            visible: root.iconSource.toString().length > 0
            Layout.preferredWidth: 13
            Layout.preferredHeight: 13
            source: root.iconSource
            sourceSize: Qt.size(26, 26)
        }
        Label {
            text: root.label
            color: root.actionEnabled ? Theme.colors.text : Theme.colors.disabled
            font.pixelSize: 10
            font.bold: root.primary
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.actionEnabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
        onClicked: if (root.actionEnabled) root.triggered()
    }
    ToolTip.visible: mouse.containsMouse
    ToolTip.delay: 400
    ToolTip.text: root.actionEnabled ? (root.hint || root.label) : "Select an item first"
    Accessible.role: Accessible.Button
    Accessible.name: root.label
}
