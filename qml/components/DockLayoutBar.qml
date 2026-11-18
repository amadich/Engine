import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    property var visiblePanels: ({})
    property string focusPanel: ""
    signal toggleRequested(string id)
    signal presetRequested(string name)
    signal resetRequested()
    signal focusEditorRequested()

    implicitHeight: 34
    color: Theme.colors.control

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 5
        Label {
            text: "WORKSPACE"
            color: Theme.colors.muted
            font.pixelSize: 9
            font.bold: true
            Layout.rightMargin: 6
        }
        Repeater {
            model: [
                { id: "components", label: "Library", icon: "cube.svg" },
                { id: "files", label: "Files", icon: "tree.svg" },
                { id: "output", label: "Output", icon: "file.svg" },
                { id: "inspector", label: "Inspector", icon: "cog_tool_administration_control_edit_option.svg" },
                { id: "preview", label: "Preview", icon: "preview.svg" }
            ]
            delegate: ToolButton {
                id: toggle
                required property var modelData
                property bool selected: root.visiblePanels[modelData.id] === true
                implicitHeight: 25
                implicitWidth: labelText.implicitWidth + 32
                hoverEnabled: true
                padding: 0
                onClicked: root.toggleRequested(modelData.id)
                contentItem: RowLayout {
                    spacing: 4
                    Image {
                        source: "qrc:/engine/assets/icons/" + toggle.modelData.icon
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        sourceSize: Qt.size(24, 24)
                    }
                    Label {
                        id: labelText
                        text: toggle.modelData.label
                        font.pixelSize: 10
                        color: toggle.selected ? Theme.colors.text : Theme.colors.muted
                    }
                }
                background: Rectangle {
                    radius: 3
                    color: toggle.selected ? Theme.colors.selection : toggle.hovered ? Theme.colors.hover : "transparent"
                    border.width: toggle.selected ? 1 : 0
                    border.color: Theme.colors.accent
                }
                ToolTip.visible: toggle.hovered
                ToolTip.text: toggle.selected ? "Hide " + toggle.modelData.label : "Show " + toggle.modelData.label
                ToolTip.delay: 650
            }
        }
        Item { Layout.fillWidth: true }
        ToolButton {
            id: editorFocusButton
            text: root.focusPanel === "editor" ? "Restore" : "Focus editor"
            implicitHeight: 25
            hoverEnabled: true
            onClicked: root.focusEditorRequested()
            contentItem: Label { text: editorFocusButton.text; font.pixelSize: 10; color: Theme.colors.text; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { radius: 3; color: editorFocusButton.hovered ? Theme.colors.hover : "transparent" }
        }
        ToolButton {
            id: presetsButton
            text: "Layouts ▾"
            implicitHeight: 25
            hoverEnabled: true
            onClicked: presetsMenu.popup()
            contentItem: Label { text: presetsButton.text; font.pixelSize: 10; color: Theme.colors.text; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { radius: 3; color: presetsButton.hovered ? Theme.colors.hover : "transparent" }
            Menu {
                id: presetsMenu
                y: presetsButton.height
                MenuItem { text: "Default IDE"; onTriggered: root.presetRequested("default") }
                MenuItem { text: "Code Focus"; onTriggered: root.presetRequested("code") }
                MenuItem { text: "Preview & Design"; onTriggered: root.presetRequested("preview") }
                MenuItem { text: "Debug & Output"; onTriggered: root.presetRequested("debug") }
                MenuSeparator { }
                MenuItem { text: "Reset Workspace Layout"; onTriggered: root.resetRequested() }
            }
        }
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.colors.border }
}
