import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

    function copyToClipboard(value) {
        if (!value) return
        menuClipboard.text = value
        menuClipboard.selectAll()
        menuClipboard.copy()
        menuClipboard.deselect()
        menuClipboard.text = ""
    }

    function handleMenuCommand(command, payload) {
        const editor = workspace.editorWorkspace
        switch (command) {
        case "newProject":
            if (canLeaveProject()) createProjectDialog.open()
            break
        case "openProject":
            if (canLeaveProject()) openProjectDialog.open()
            break
        case "openRecent":
            if (canLeaveProject()) {
                if (projectController.openProjectPath(payload)) {
                    startupService.rememberProject(projectController.projectFolderUrl)
                    window.launcherVisible = false
                }
            }
            break
        case "quickOpen":
            if (projectController.activeProjectPath !== "" && !quickOpen.visible)
                quickOpen.open()
            break
        case "save": editor.saveCurrent(); break
        case "saveAll": editor.saveAll(); break
        case "closeEditor": editor.closeCurrent(); break
        case "closeAllEditors": editor.closeAllEditors(); break
        case "closeProject":
            if (canLeaveProject()) projectController.closeProject()
            break
        case "welcome":
            if (!projectController.busy && canLeaveProject())
                window.launcherVisible = true
            break
        case "quit": window.close(); break
        case "undo": editor.undoEdit(); break
        case "redo": editor.redoEdit(); break
        case "cut": editor.cutSelection(); break
        case "copy": editor.copySelection(); break
        case "paste": editor.pasteClipboard(); break
        case "selectAll": editor.selectAllText(); break
        case "find": editor.openFind(); break
        case "findNext": editor.findNext(false); break
        case "goToLine": editor.openGoToLine(); break
        case "copyFilePath":
            copyToClipboard(projectController.localFilePath(editor.currentFileUrl))
            break
        case "copyProjectPath": copyToClipboard(projectController.activeProjectPath); break
        case "toggleProjectFiles": engineToolbar.showProjectFiles = !engineToolbar.showProjectFiles; break
        case "toggleOutput": engineToolbar.showOutput = !engineToolbar.showOutput; break
        case "showAllPanels": engineToolbar.showProjectFiles = true; engineToolbar.showOutput = true; break
        case "showOutput": engineToolbar.showOutput = true; break
        case "preview": editor.showPreview(); break
        case "nextTab": editor.nextTab(); break
        case "previousTab": editor.previousTab(); break
        case "zoomIn": editor.changeFontSize(1); break
        case "zoomOut": editor.changeFontSize(-1); break
        case "zoomReset": editor.editorFontSize = 14; break
        case "darkTheme": Theme.appearance = "dark"; break
        case "lightTheme": Theme.appearance = "light"; break
        case "run": projectController.startDevServer(); break
        case "stop": projectController.stopDevServer(); break
        case "installDependencies": projectController.installDependencies(); engineToolbar.showOutput = true; break
        case "checkNpm": projectController.checkNpm(); engineToolbar.showOutput = true; break
        case "generateReact": projectController.generateReact(); engineToolbar.showOutput = true; break
        case "clearOutput": outputPanel.clearOutput(); break
        case "copyOutput": outputPanel.copyLog(false); break
        case "revealProject": projectController.revealProjectFolder(); break
        case "projectInfo": projectInfoDialog.open(); break
        case "checkUpdates": updatesDialog.open(); startupService.checkUpdates(); break
        case "preferences": preferencesDialog.open(); break
        case "shortcuts": shortcutsDialog.open(); break
        case "about": aboutDialog.open(); break
        case "minimize": window.showMinimized(); break
        case "maximize": engineToolbar.toggleMaximized(); break
        default: console.warn("Unknown menu command:", command)
        }
    }

    TextEdit { id: menuClipboard; visible: false; width: 1; height: 1 }

    function closeEditorsAfterComponentChange() {
        // Saved tabs may still refer to the old paths after relocation/removal.
        window.selectedFileUrl = ""
        window.selectedFileDetails = ({})
        workspace.editorWorkspace.reset()
    }

    onClosing: function(close) {
        close.accepted = window.canLeaveProject()
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

    MenuShortcutsDialog {
        id: shortcutsDialog
        parent: Overlay.overlay
    }
    MenuProjectInfoDialog {
        id: projectInfoDialog
        parent: Overlay.overlay
        controller: projectController
    }
    MenuUpdatesDialog {
        id: updatesDialog
        parent: Overlay.overlay
        startup: startupService
    }
    Dialog {
        id: aboutDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 420
        title: "About Jeridi Engine"
        modal: true
        popupType: Popup.Window
        standardButtons: Dialog.Close
        padding: 18
        background: Rectangle { color: Theme.colors.panel; border.color: Theme.colors.border; radius: 7 }
        contentItem: ColumnLayout {
            spacing: 10
            Label { text: "JERIDI ENGINE"; color: Theme.colors.text; font.pixelSize: 21; font.bold: true }
            Label { text: "Version " + startupService.currentVersion(); color: Theme.colors.accent; font.pixelSize: 13 }
            Label { Layout.fillWidth: true; text: "Development workspace, project generator and context-aware component library."; color: Theme.colors.muted; font.pixelSize: 12; wrapMode: Text.WordWrap }
        }
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
        id: engineToolbar
        visible: !window.launcherVisible
        hostWindow: window
        projectName: projectController.activeProjectName
        projectPath: projectController.activeProjectPath
        projectFramework: projectController.projectFramework
        recentProjects: startupService.recentProjects
        busy: projectController.busy
        hasEditor: workspace.editorWorkspace.activeTab >= 0
        hasDirty: workspace.editorWorkspace.hasUnsavedChanges
        devServerActive: projectController.devServerActive
        onMenuCommandRequested: function(command, payload) {
            window.handleMenuCommand(command, payload)
        }
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
