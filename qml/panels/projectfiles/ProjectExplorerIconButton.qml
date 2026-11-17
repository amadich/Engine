import QtQuick
import QtQuick.Controls
import JeridiEngine

// Reusable 25px explorer action with clear hover / disabled / keyboard states.
Rectangle {
    id: root
    property url iconSource: ""
    property string glyph: ""
    property string hint: ""
    property string disabledReason: "Unavailable"
    property bool actionEnabled: true
    property bool selected: false
    property int iconSize: 14
    signal triggered()

    implicitWidth: 25
    implicitHeight: 25
    radius: 4
    color: !actionEnabled ? Theme.colors.surface
           : mouse.pressed ? Theme.colors.selection
           : (mouse.containsMouse || selected || activeFocus) ? Theme.colors.hover
           : "transparent"
    border.width: mouse.containsMouse || selected || activeFocus ? 1 : 0
    border.color: selected || activeFocus ? Theme.colors.accent : Theme.colors.border
    opacity: actionEnabled ? 1 : 0.58
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: hint
    Accessible.description: actionEnabled ? hint : disabledReason
    Behavior on color { ColorAnimation { duration: 90 } }

    Image {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        visible: root.iconSource.toString().length > 0
        source: root.iconSource
        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
        fillMode: Image.PreserveAspectFit
        opacity: root.actionEnabled ? 0.95 : 0.35
    }
    Text {
        anchors.centerIn: parent
        visible: root.iconSource.toString().length === 0
        text: root.glyph
        font.pixelSize: 13
        font.bold: true
        color: root.actionEnabled ? Theme.colors.text : Theme.colors.disabled
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: root.actionEnabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
        onClicked: if (root.actionEnabled) root.triggered()
    }
    Keys.onPressed: function(event) {
        if (root.actionEnabled && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
            root.triggered()
            event.accepted = true
        }
    }
    ToolTip.visible: mouse.containsMouse
    ToolTip.delay: 430
    ToolTip.timeout: 3500
    ToolTip.text: root.actionEnabled ? root.hint : root.disabledReason
}
