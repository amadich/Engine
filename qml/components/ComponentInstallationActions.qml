import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Package-agnostic file actions. All writes remain in ComponentManager / C++.
Item {
    id: root
    required property ProjectController controller
    required property ComponentManager componentManager
    required property string componentId

    property bool installed: false
    property bool hasUnsavedChanges: false
    readonly property bool canWrite: controller.activeProjectPath !== ""
                                     && (!controller.busy || controller.devServerActive)
    readonly property bool actionsReady: canWrite && !hasUnsavedChanges
    readonly property string blockedReason: controller.activeProjectPath === ""
        ? "Open a project first"
        : hasUnsavedChanges ? "Apply or reload pending Inspector edits first"
        : "Project is currently busy"

    implicitHeight: section.implicitHeight

    function refresh() { installed = componentManager.isInstalled(componentId) }
    Component.onCompleted: refresh()

    InspectorSection {
        id: section
        width: root.width
        title: "Project Package"
        iconSource: "qrc:/engine/assets/icons/folder.svg"
        tag: root.installed ? "ACTIVE" : "DRAFT"
        description: "Choose when and where to install, relocate or remove package files."

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Image {
                source: root.installed ? "qrc:/engine/assets/icons/folder_1.svg"
                                       : "qrc:/engine/assets/icons/cube_block.svg"
                sourceSize: Qt.size(28, 28)
                Layout.preferredWidth: 15
                Layout.preferredHeight: 15
            }
            Label {
                Layout.fillWidth: true
                text: root.installed ? root.componentManager.installedDirectory(root.componentId)
                                     : "Not installed — editing a draft"
                color: Theme.colors.muted
                font.pixelSize: 10
                wrapMode: Text.WrapAnywhere
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: warningText.implicitHeight + 12
            visible: root.hasUnsavedChanges
            radius: 3
            color: Theme.colors.control
            border.color: Theme.colors.border
            border.width: 1
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 7
                anchors.rightMargin: 7
                spacing: 5
                Image {
                    source: "qrc:/engine/assets/icons/warning_2.svg"
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                }
                Label {
                    id: warningText
                    Layout.fillWidth: true
                    text: "Save or reload changes before modifying project files."
                    color: Theme.colors.accent
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }
        }

        InspectorActionButton {
            Layout.fillWidth: true
            buttonHeight: 28
            visible: !root.installed
            text: "Install to Project…"
            iconSource: "qrc:/engine/assets/icons/cube_blue.svg"
            variant: "primary"
            actionEnabled: root.actionsReady
            hint: "Choose a destination before writing package files"
            disabledReason: root.blockedReason
            onClicked: root.componentManager.requestInstall(root.componentId)
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.installed
            spacing: 6
            InspectorActionButton {
                Layout.fillWidth: true
                buttonHeight: 28
                text: "Relocate…"
                iconSource: "qrc:/engine/assets/icons/folder.svg"
                actionEnabled: root.actionsReady
                hint: "Preview a safe move to another project directory"
                disabledReason: root.blockedReason
                onClicked: root.componentManager.requestMove(root.componentId)
            }
            InspectorActionButton {
                Layout.fillWidth: true
                buttonHeight: 28
                text: "Remove…"
                iconSource: "qrc:/engine/assets/icons/trash.svg"
                variant: "danger"
                actionEnabled: root.actionsReady
                hint: "Review references and move owned files to the project trash"
                disabledReason: root.blockedReason
                onClicked: root.componentManager.requestRemove(root.componentId)
            }
        }

        Label {
            Layout.fillWidth: true
            text: "Changes to project files always require confirmation."
            font.pixelSize: 9
            color: Theme.colors.muted
            wrapMode: Text.WordWrap
        }
    }

    Connections {
        target: root.componentManager
        function onComponentInstalled(id) { if (id === root.componentId) root.refresh() }
        function onComponentMoved(id) { if (id === root.componentId) root.refresh() }
        function onComponentRemoved(id) { if (id === root.componentId) root.refresh() }
    }
    Connections {
        target: root.controller
        function onActiveProjectChanged() { root.refresh() }
    }
}
