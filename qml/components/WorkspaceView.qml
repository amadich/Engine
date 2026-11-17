import QtQuick
import QtQuick.Controls
import JeridiEngine

SplitView {
    id: root
    property url previewUrl: ""
    property bool devServerActive: false

    property var selectedFileDetails: ({})

    required property ProjectController controller
    required property ComponentManager componentManager
    property alias editorWorkspace: editorWorkspace

    property string selectedComponentId: ""

    property bool canAddComponent: false

    orientation: Qt.Horizontal

    ComponentLibraryPanel {
        SplitView.preferredWidth: 260
        SplitView.minimumWidth: 180

        canAddComponent: root.canAddComponent
        componentManager: root.componentManager
        selectedComponentId: root.selectedComponentId
        onInstallComponentRequested: function(componentId) {
            root.installComponentRequested(componentId)
        }

        onComponentSelected: function(componentId) {
            root.selectedComponentId = componentId
        }
    }

    EditorWorkspace {
        id: editorWorkspace

        SplitView.fillWidth: true
        SplitView.minimumWidth: 360

        controller: root.controller
        previewUrl: root.previewUrl
        devServerActive: root.devServerActive
    }

    // PreviewPanel {
    //     SplitView.fillWidth: true
    //     SplitView.minimumWidth: 360
    //     previewUrl: root.previewUrl
    //     devServerActive: root.devServerActive
    // }

    InspectorHost {
        SplitView.preferredWidth: 320
        SplitView.minimumWidth: 220

        controller: root.controller
        componentManager: root.componentManager
        componentId: root.selectedComponentId
        fileDetails: root.selectedFileDetails
    }
}
