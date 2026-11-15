import QtQuick
import QtQuick.Controls
import JeridiEngine
import QtQuick.Dialogs

ApplicationWindow {
    id: window

    width: 1400
    height: 900
    minimumWidth: 1000
    minimumHeight: 650
    visible: true
    title: "Jeridi Engine"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    readonly property bool maximized: visibility === Window.Maximized
    property url selectedFileUrl: ""
    property var selectedFileDetails: ({})

    background: Rectangle {
        radius: window.maximized ? 0 : 16
        color: "#111827"
        border.width: window.maximized ? 0 : 1
        border.color: "#344256"
    }



    ProjectController {
        id: projectController
        function onActiveProjectChanged() {
            window.selectedFileUrl = ""
            window.selectedFileDetails = ({})
        }
    }

    Connections {
        target: projectController

        function onLogMessage(message) {
            outputPanel.appendLog(message)
        }

        function onOutputReceived(text) {
            outputPanel.appendOutput(text)
        }
    }

    header: EngineToolbar {
        id: engineToolbar
        hostWindow: window
        projectName: projectController.activeProjectName
        projectPath: projectController.activeProjectPath
        busy: projectController.busy

        onCreateProjectRequested: createProjectDialog.open()
        onCheckNpmRequested: projectController.checkNpm()
        onGenerateReactRequested: projectController.generateReact()

        onOpenProjectRequested: openProjectDialog.open()
        onInstallDependenciesRequested: projectController.installDependencies()

        devServerActive: projectController.devServerActive

        onRunRequested: projectController.startDevServer()
        onStopRequested: projectController.stopDevServer()
    }

    CreateProjectDialog {
        id: createProjectDialog
        parent: Overlay.overlay
        controller: projectController
    }

    FolderDialog {
        id: openProjectDialog
        title: "Open npm project folder"

        onAccepted: projectController.openProject(selectedFolder)
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Vertical
        anchors.margins: window.maximized ? 0 : 8
        anchors.topMargin: 0

        WorkspaceView {
            SplitView.fillHeight: true
            SplitView.minimumHeight: 300
            previewUrl: projectController.previewUrl
            devServerActive: projectController.devServerActive

            canAddComponent: projectController.activeProjectPath !== ""
                             && (!projectController.busy
                                 || projectController.devServerActive)

            onAddButtonRequested: projectController.addButtonComponent()
            selectedFileDetails: window.selectedFileDetails


        }

        SplitView {
            orientation: Qt.Horizontal

            SplitView.preferredHeight: 260
            SplitView.minimumHeight: 140

            ProjectFilesPanel {
                SplitView.preferredWidth: 340
                SplitView.minimumWidth: 220

                projectFolder: projectController.projectFolderUrl
                projectName: projectController.activeProjectName
                selectedFile: window.selectedFileUrl

                onFileSelected: function(file) {
                    window.selectedFileUrl = file
                    window.selectedFileDetails = projectController.inspectFile(file)
                }
            }

            OutputPanel {
                id: outputPanel

                SplitView.fillWidth: true
                SplitView.minimumWidth: 240
            }
        }

        MouseArea {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 14
            height: 14
            z: 10
            visible: !window.maximized
            cursorShape: Qt.SizeFDiagCursor

            onPressed: window.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
        }
    }
}
