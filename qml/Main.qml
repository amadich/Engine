import QtQuick
import QtQuick.Controls
import JeridiEngine
import QtQuick.Dialogs

ApplicationWindow {
    id: window

    width: 1200
    height: 800
    minimumWidth: 1000
    minimumHeight: 650
    visible: true
    title: "Jeridi Engine"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    readonly property bool maximized: visibility === Window.Maximized
    property bool launcherVisible: true
    StartupService { id: startupService }

    property url selectedFileUrl: ""
    property var selectedFileDetails: ({})


    palette.window: Theme.colors.window
    palette.windowText: Theme.colors.text
    palette.base: Theme.colors.surface
    palette.alternateBase: Theme.colors.panel
    palette.text: Theme.colors.text
    palette.button: Theme.colors.control
    palette.buttonText: Theme.colors.text
    palette.placeholderText: Theme.colors.muted
    palette.highlight: Theme.colors.selection
    palette.highlightedText: Theme.colors.text


    function canLeaveProject() {
        if (!workspace.editorWorkspace.hasUnsavedChanges)
            return true

        workspace.editorWorkspace.statusMessage =
            "Save your open files before switching projects or closing."
        return false
    }

    function closeEditorsAfterComponentChange() {
        // Saved tabs may still refer to the old paths after relocation/removal.
        window.selectedFileUrl = ""
        window.selectedFileDetails = ({})
        workspace.editorWorkspace.reset()
    }

    onClosing: function(close) {
        close.accepted = window.canLeaveProject()
    }

    Shortcut {
        sequence: "Ctrl+P"
        enabled: projectController.activeProjectPath !== "" && !quickOpen.visible
        onActivated: quickOpen.open()
    }

    QuickOpenDialog {
        id: quickOpen
        parent: Overlay.overlay
        controller: projectController

        onFileChosen: function(file) {
            window.selectedFileUrl = file
            window.selectedFileDetails = projectController.inspectFile(file)
            workspace.editorWorkspace.openFile(file)
        }
    }

    background: Rectangle {
        radius: window.maximized ? 0 : 16
        border.width: window.maximized ? 0 : 1
        color: Theme.colors.window
        border.color: Theme.colors.border
    }

    PreferencesDialog {
        id: preferencesDialog
        parent: Overlay.overlay
    }



    ProjectController {
        id: projectController
        function onActiveProjectChanged() {
            window.selectedFileUrl = ""
            window.selectedFileDetails = ({})
            workspace.editorWorkspace.reset()
        }
        onProjectCreated: function(name, path) {
            startupService.rememberProject(Qt.resolvedUrl("file://" + encodeURI(path)))
        }
    }

    ComponentManager {
        id: componentManager
        projectController: projectController
        onLogMessage: function(message) { outputPanel.appendLog(message) }
        onInstallRequested: function(componentId) {
            componentInstallDialog.openForComponent(componentId)
        }
        onMoveRequested: function(componentId) {
            componentMoveDialog.openForComponent(componentId)
        }
        onRemoveRequested: function(componentId) {
            componentRemoveDialog.openForComponent(componentId)
        }
        onComponentMoved: function(componentId) { window.closeEditorsAfterComponentChange() }
        onComponentRemoved: function(componentId) { window.closeEditorsAfterComponentChange() }
    }

    ComponentInstallDialog {
        id: componentInstallDialog
        controller: projectController
        componentManager: componentManager
    }

    ComponentMoveDialog {
        id: componentMoveDialog
        controller: projectController
        componentManager: componentManager
        hasUnsavedChanges: workspace.editorWorkspace.hasUnsavedChanges
    }

    ComponentRemoveDialog {
        id: componentRemoveDialog
        controller: projectController
        componentManager: componentManager
        hasUnsavedChanges: workspace.editorWorkspace.hasUnsavedChanges
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
        visible: !window.launcherVisible
        id: engineToolbar
        hostWindow: window
        projectName: projectController.activeProjectName
        projectPath: projectController.activeProjectPath
        busy: projectController.busy

        onCreateProjectRequested: {
            if (window.canLeaveProject())
                createProjectDialog.open()
        }
        onCheckNpmRequested: projectController.checkNpm()
        onGenerateReactRequested: projectController.generateReact()

        onOpenProjectRequested: {
            if (window.canLeaveProject())
                openProjectDialog.open()
        }
        onInstallDependenciesRequested: projectController.installDependencies()

        devServerActive: projectController.devServerActive

        onRunRequested: projectController.startDevServer()
        onStopRequested: projectController.stopDevServer()

        onPreferencesRequested: preferencesDialog.open()
    }

    CreateProjectDialog {
        id: createProjectDialog
        parent: Overlay.overlay
        controller: projectController
    }

    FolderDialog {
        id: openProjectDialog
        title: "Open project folder"

        onAccepted: {
            if (projectController.openProject(selectedFolder)) {
                startupService.rememberProject(selectedFolder)
                window.launcherVisible = false
            }
        }
    }

    SplitView {
        visible: !window.launcherVisible
        anchors.fill: parent
        orientation: Qt.Vertical
        anchors.margins: window.maximized ? 0 : 8
        anchors.topMargin: 0

        WorkspaceView {
            id: workspace
            controller: projectController
            componentManager: componentManager

            SplitView.fillHeight: true
            SplitView.minimumHeight: 300
            previewUrl: projectController.previewUrl
            devServerActive: projectController.devServerActive

            selectedFileDetails: window.selectedFileDetails


        }

        SplitView {
            orientation: Qt.Horizontal

            SplitView.preferredHeight: 260
            SplitView.minimumHeight: 140

            ProjectFilesPanel {
                SplitView.preferredWidth: 340
                SplitView.minimumWidth: 220
                visible: engineToolbar.showProjectFiles
                SplitView.fillWidth: !engineToolbar.showOutput

                projectFolder: projectController.projectFolderUrl
                projectName: projectController.activeProjectName
                selectedFile: window.selectedFileUrl

                onFileSelected: function(file) {
                    window.selectedFileUrl = file
                    window.selectedFileDetails = projectController.inspectFile(file)
                }

                onFileOpenRequested: function(file) {
                    workspace.editorWorkspace.openFile(file)
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
    StartupLauncher {
        id: startupLauncher
        anchors.fill: parent
        z: 1000
        visible: window.launcherVisible
        startup: startupService
        onEnterWorkspaceRequested: window.launcherVisible = false
        onNewProjectRequested: {
            window.launcherVisible = false
            createProjectDialog.open()
        }
        onOpenProjectRequested: function(folder) {
            if (projectController.openProject(folder)) {
                startupService.rememberProject(folder)
                window.launcherVisible = false
            }
        }
    }
}
