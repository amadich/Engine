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

    orientation: Qt.Horizontal

    ComponentLibraryPanel {
        SplitView.preferredWidth: 260
        SplitView.minimumWidth: 180

        canAddComponent: root.canAddComponent
        onAddButtonRequested: root.addButtonRequested()
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

    InspectorPanel {
        SplitView.preferredWidth: 280
        SplitView.minimumWidth: 200
        fileDetails: root.selectedFileDetails
    }
}
