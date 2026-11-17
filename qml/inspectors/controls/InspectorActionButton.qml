import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Interactive button surface: hover, keyboard, disabled reason, and cursor remain
// available even when the action is unavailable. Use actionEnabled, not enabled.
Rectangle {
    id: root

    property string text: "Action"
    property url iconSource: ""
    property string variant: "secondary"   // primary | secondary | subtle | danger
    property bool actionEnabled: true
    property bool selected: false
    property string hint: ""
    property string disabledReason: "Action unavailable"
    property int iconSize: 13
    property int buttonHeight: 27
    signal clicked()

    implicitHeight: buttonHeight
    implicitWidth: Math.max(58, buttonContent.implicitWidth + 18)
    radius: 4
    border.width: 1
    border.color: !root.actionEnabled ? Theme.colors.border
                  : root.selected || (mouse.containsMouse && root.variant !== "danger") ? Theme.colors.accent
                  : mouse.containsMouse && root.variant === "danger" ? Theme.colors.error
                  : Theme.colors.border
    color: !root.actionEnabled ? (Theme.dark ? "#2C2E32" : "#EDF1F5")
         : mouse.pressed ? Theme.colors.selection
         : root.variant === "primary" ? (mouse.containsMouse ? Theme.colors.hover : Theme.colors.selection)
         : mouse.containsMouse ? Theme.colors.hover
         : root.selected ? Theme.colors.selection : Theme.colors.control
    opacity: 1
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.text || root.hint
    Accessible.description: root.actionEnabled ? root.hint : root.disabledReason

    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        id: buttonContent
        anchors.centerIn: parent
        spacing: 5
        Image {
            visible: root.iconSource.toString().length > 0
            source: root.iconSource
            sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
            Layout.preferredWidth: visible ? root.iconSize : 0
            Layout.preferredHeight: visible ? root.iconSize : 0
            fillMode: Image.PreserveAspectFit
            opacity: root.actionEnabled ? 0.95 : 0.30
        }
        Label {
            text: root.text
            visible: root.text.length > 0
            font.pixelSize: 10
            font.bold: root.variant === "primary" || root.selected
            color: !root.actionEnabled ? Theme.colors.disabled
                   : root.variant === "danger" && mouse.containsMouse ? Theme.colors.error
                   : Theme.colors.text
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 3
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.colors.accent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.actionEnabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
        onClicked: { if (root.actionEnabled) root.clicked() }
    }
    Keys.onPressed: function(event) {
        if (root.actionEnabled && (event.key === Qt.Key_Return
                                   || event.key === Qt.Key_Enter
                                   || event.key === Qt.Key_Space)) {
            root.clicked()
            event.accepted = true
        }
    }

    ToolTip.visible: mouse.containsMouse
    ToolTip.delay: 420
    ToolTip.timeout: 5500
    ToolTip.text: root.actionEnabled
                  ? (root.hint || root.text)
                  : ("Unavailable: " + root.disabledReason)
}
