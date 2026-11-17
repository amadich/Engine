import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Package-agnostic installation actions. This is UI only; C++ owns file operations.
Item {
    id: root
    required property ProjectController controller
    required property ComponentManager componentManager
    required property string componentId

    property bool installed: false
    property bool hasUnsavedChanges: false
    readonly property bool canWrite: controller.activeProjectPath !== ""
                                     && (!controller.busy || controller.devServerActive)

    implicitHeight: section.implicitHeight

    function refresh() { installed = componentManager.isInstalled(componentId) }
    Component.onCompleted: refresh()

    InspectorSection {
        id: section
        width: root.width
        title: "Project Package"
        iconSource: "qrc:/engine/assets/icons/folder.svg"
        tag: root.installed ? "ACTIVE" : "NOT INSTALLED"
        description: "Installation, relocation and removal affect project files only after confirmation."

        Label {
            Layout.fillWidth: true
            text: root.installed
                ? root.componentManager.installedDirectory(root.componentId)
                : "Not added to this project. The settings above are a draft."
            color: Theme.colors.muted
            font.pixelSize: 10
            wrapMode: Text.WrapAnywhere
        }

        Label {
            Layout.fillWidth: true
            visible: root.hasUnsavedChanges
            text: "Apply or reload modified settings before changing project files."
            font.pixelSize: 10
            color: Theme.colors.accent
            wrapMode: Text.WordWrap
        }

        Button {
            Layout.fillWidth: true
            implicitHeight: 28
            visible: !root.installed
            enabled: root.canWrite && !root.hasUnsavedChanges
            text: "Install to Project…"
            font.pixelSize: 11
            icon.source: "qrc:/engine/assets/icons/cube_blue.svg"
            icon.width: 14
            icon.height: 14
            onClicked: root.componentManager.requestInstall(root.componentId)
            background: Rectangle {
                radius: 3
                color: Theme.colors.control
                border.color: Theme.colors.border
                border.width: 1
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.installed
            enabled: root.canWrite && !root.hasUnsavedChanges
            spacing: 6
            Button {
                Layout.fillWidth: true
                implicitHeight: 28
                text: "Relocate…"
                font.pixelSize: 11
                icon.source: "qrc:/engine/assets/icons/folder.svg"
                icon.width: 14
                icon.height: 14
                onClicked: root.componentManager.requestMove(root.componentId)
                background: Rectangle {
                    radius: 3
                    color: Theme.colors.control
                    border.color: Theme.colors.border
                    border.width: 1
                }
            }
            Button {
                Layout.fillWidth: true
                implicitHeight: 28
                text: "Remove…"
                font.pixelSize: 11
                icon.source: "qrc:/engine/assets/icons/trash.svg"
                icon.width: 14
                icon.height: 14
                onClicked: root.componentManager.requestRemove(root.componentId)
                background: Rectangle {
                    radius: 3
                    color: Theme.colors.control
                    border.color: Theme.colors.border
                    border.width: 1
                }
            }
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
