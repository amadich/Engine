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
    color: "#0B1120"

    ProjectController {
        id: projectController
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

        WorkspaceView {
            SplitView.fillHeight: true
            SplitView.minimumHeight: 300
            previewUrl: projectController.previewUrl
            devServerActive: projectController.devServerActive
        }

        OutputPanel {
            id: outputPanel
            SplitView.preferredHeight: 200
            SplitView.minimumHeight: 100
        }
    }
}
