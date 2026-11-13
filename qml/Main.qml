import QtQuick
import QtQuick.Controls
import JeridiEngine

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
    }

    CreateProjectDialog {
        id: createProjectDialog
        parent: Overlay.overlay
        controller: projectController
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Vertical

        WorkspaceView {
            SplitView.fillHeight: true
            SplitView.minimumHeight: 300
        }

        OutputPanel {
            id: outputPanel
            SplitView.preferredHeight: 200
            SplitView.minimumHeight: 100
        }
    }
}
