import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Tiny shared toolbar action. Disabled actions keep their tooltip and forbidden cursor.
Rectangle {
    id: root

    property url iconSource: ""
    property string glyph: ""
    property string hint: ""
    property string disabledReason: "Action unavailable"
    property bool actionEnabled: true
    property bool selected: false
    property int iconSize: 14
    signal triggered()

    implicitWidth: 25
    implicitHeight: 25
    radius: 4
    color: !actionEnabled ? Theme.colors.surface
           : mouse.pressed ? Theme.colors.selection
           : mouse.containsMouse || selected ? Theme.colors.hover
           : "transparent"
    border.width: mouse.containsMouse || selected || activeFocus ? 1 : 0
    border.color: activeFocus || selected ? Theme.colors.accent : Theme.colors.border
    opacity: actionEnabled ? 1 : 0.63
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: hint
    Accessible.description: actionEnabled ? hint : disabledReason

    Behavior on color { ColorAnimation { duration: 100 } }

    Image {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.iconSource
        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
        fillMode: Image.PreserveAspectFit
        visible: root.iconSource.toString().length > 0
        opacity: root.actionEnabled ? 0.95 : 0.35
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        visible: root.iconSource.toString().length === 0
        font.pixelSize: 13
        font.bold: true
        color: root.actionEnabled ? Theme.colors.text : Theme.colors.disabled
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.actionEnabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
        onClicked: { if (root.actionEnabled) root.triggered() }
    }

    Keys.onPressed: function(event) {
        if (root.actionEnabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return
                                   || event.key === Qt.Key_Enter)) {
            root.triggered()
            event.accepted = true
        }
    }

    ToolTip.visible: mouse.containsMouse
    ToolTip.delay: 450
    ToolTip.timeout: 4500
    ToolTip.text: root.actionEnabled ? root.hint : root.disabledReason
}
