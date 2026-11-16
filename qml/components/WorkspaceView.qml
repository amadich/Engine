import QtQuick
import QtQuick.Controls
import JeridiEngine

SplitView {
    id: root
    property url previewUrl: ""
    property bool devServerActive: false

    property bool canAddComponent: false
    signal addButtonRequested()

    property var selectedFileDetails: ({})

    required property ProjectController controller
    property alias editorWorkspace: editorWorkspace

    property string selectedComponentId: ""

    orientation: Qt.Horizontal

    ComponentLibraryPanel {
        SplitView.preferredWidth: 260
        SplitView.minimumWidth: 180

        canAddComponent: root.canAddComponent
        onAddButtonRequested: root.addButtonRequested()

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

    Loader {
        SplitView.preferredWidth: 320
        SplitView.minimumWidth: 220

        sourceComponent: root.selectedComponentId === "navbar"
                         ? navbarInspectorComponent : fileInspectorComponent
    }

    Component {
        id: navbarInspectorComponent

        NavbarInspector {
            controller: root.controller
        }
    }

    Component {
        id: fileInspectorComponent

        InspectorPanel {
            fileDetails: root.selectedFileDetails
        }
    }
}
