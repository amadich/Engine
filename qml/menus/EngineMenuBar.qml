import QtQuick
import QtQuick.Controls
import QtQml.Models
import JeridiEngine

// All menu actions and global keyboard shortcuts live here.
// The parent decides what each command does; menus never touch editor internals.
MenuBar {
    id: root

    property bool busy: false
    property bool menuActive: true
    property bool devServerActive: false
    property bool hasProject: false
    property bool hasEditor: false
    property bool hasTextEditor: false
    property bool hasDirty: false
    property bool showProjectFiles: true
    property bool showOutput: true
    property bool showComponents: true
    property bool showInspector: true
    property bool showPreviewDock: false
    property string projectFramework: ""
    property var recentProjects: []

    signal commandRequested(string command, var payload)

    function dispatch(command, payload) {
        commandRequested(command, payload === undefined ? "" : payload)
    }
    function key(mac, other) { return Qt.platform.os === "osx" ? mac : other }

    background: Item { }
    delegate: MenuBarItem {
        id: tab
        implicitHeight: 32
        leftPadding: 9
        rightPadding: 9
        topPadding: 0
        bottomPadding: 0
        contentItem: Label {
            text: tab.text
            font.pixelSize: 12
            color: Theme.colors.text
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        background: Rectangle {
            radius: 4
            color: tab.highlighted || tab.hovered ? Theme.colors.hover : "transparent"
        }
    }

    // Shortcuts are declared once, independently of the popup's visibility.
    // Text editing's native Undo/Cut/Copy/Paste/Select All keys stay with TextArea.
    Shortcut { sequence: "Ctrl+Shift+N"; enabled: root.menuActive && !root.busy; onActivated: root.dispatch("newProject") }
    Shortcut { sequence: "Ctrl+O"; enabled: root.menuActive && !root.busy; onActivated: root.dispatch("openProject") }
    Shortcut { sequence: "Ctrl+P"; enabled: root.menuActive && root.hasProject; onActivated: root.dispatch("quickOpen") }
    Shortcut { sequence: "Ctrl+S"; enabled: root.menuActive && root.hasTextEditor; onActivated: root.dispatch("save") }
    Shortcut { sequence: "Ctrl+Shift+S"; enabled: root.menuActive && root.hasEditor; onActivated: root.dispatch("saveAll") }
    Shortcut { sequence: "Ctrl+W"; enabled: root.menuActive && root.hasEditor; onActivated: root.dispatch("closeEditor") }
    Shortcut { sequence: "Ctrl+Shift+W"; enabled: root.menuActive && root.hasProject && !root.busy; onActivated: root.dispatch("closeProject") }
    Shortcut { sequence: "Ctrl+Q"; enabled: root.menuActive; onActivated: root.dispatch("quit") }
    Shortcut { sequence: "Ctrl+F"; enabled: root.menuActive && root.hasTextEditor; onActivated: root.dispatch("find") }
    Shortcut { sequence: "Ctrl+G"; enabled: root.menuActive && root.hasTextEditor; onActivated: root.dispatch("findNext") }
    Shortcut { sequence: "Ctrl+L"; enabled: root.menuActive && root.hasTextEditor; onActivated: root.dispatch("goToLine") }
    Shortcut { sequence: "Ctrl+Alt+C"; enabled: root.menuActive && root.hasEditor; onActivated: root.dispatch("copyFilePath") }
    Shortcut { sequence: "Ctrl+,"; enabled: root.menuActive; onActivated: root.dispatch("preferences") }
    Shortcut { sequence: "Ctrl+1"; enabled: root.menuActive; onActivated: root.dispatch("toggleProjectFiles") }
    Shortcut { sequence: "Ctrl+2"; enabled: root.menuActive; onActivated: root.dispatch("toggleOutput") }
    Shortcut { sequence: "Ctrl+3"; enabled: root.menuActive; onActivated: root.dispatch("toggleComponents") }
    Shortcut { sequence: "Ctrl+4"; enabled: root.menuActive; onActivated: root.dispatch("toggleInspector") }
    Shortcut { sequence: "Ctrl+5"; enabled: root.menuActive; onActivated: root.dispatch("togglePreviewDock") }
    Shortcut { sequence: "Ctrl+Shift+0"; enabled: root.menuActive; onActivated: root.dispatch("showAllPanels") }
    Shortcut { sequence: Qt.platform.os === "osx" ? "Meta+Tab" : "Ctrl+Tab"; enabled: root.menuActive && root.hasEditor; onActivated: root.dispatch("nextTab") }
    Shortcut { sequence: Qt.platform.os === "osx" ? "Meta+Shift+Tab" : "Ctrl+Shift+Tab"; enabled: root.menuActive && root.hasEditor; onActivated: root.dispatch("previousTab") }
    Shortcut { sequence: "Ctrl+Plus"; enabled: root.menuActive && root.hasTextEditor; onActivated: root.dispatch("zoomIn") }
    Shortcut { sequence: "Ctrl+Minus"; enabled: root.menuActive && root.hasTextEditor; onActivated: root.dispatch("zoomOut") }
    Shortcut { sequence: "Ctrl+0"; enabled: root.menuActive && root.hasTextEditor; onActivated: root.dispatch("zoomReset") }
    Shortcut { sequence: Qt.platform.os === "osx" ? "Meta+F5" : "Ctrl+F5"; enabled: root.menuActive && root.hasProject && !root.busy; onActivated: root.dispatch("run") }
    Shortcut { sequence: "Shift+F5"; enabled: root.menuActive && root.devServerActive; onActivated: root.dispatch("stop") }
    Shortcut { sequence: "Ctrl+Shift+K"; enabled: root.menuActive; onActivated: root.dispatch("shortcuts") }

    EngineMenu {
        title: "File"
        EngineMenuSection { text: "PROJECT" }
        EngineMenuItem { text: "New Project…"; iconName: "cube_blue.svg"; shortcutLabel: root.key("⇧⌘N", "Ctrl+Shift+N"); enabled: !root.busy; onTriggered: root.dispatch("newProject") }
        EngineMenuItem { text: "Open Project…"; iconName: "folder.svg"; shortcutLabel: root.key("⌘O", "Ctrl+O"); enabled: !root.busy; onTriggered: root.dispatch("openProject") }
        EngineMenu {
            id: recentMenu
            title: "Open Recent"
            menuWidth: 290
            EngineMenuItem { text: "No recent projects"; enabled: false; visible: root.recentProjects.length === 0 }
            Instantiator {
                model: root.recentProjects
                delegate: EngineMenuItem {
                    required property var modelData
                    text: modelData.name
                    iconName: "folder.svg"
                    enabled: !root.busy
                    onTriggered: root.dispatch("openRecent", modelData.path)
                }
                onObjectAdded: function(index, object) { recentMenu.insertItem(index, object) }
                onObjectRemoved: function(index, object) { recentMenu.removeItem(object) }
            }
        }
        EngineMenuDivider { }
        EngineMenuSection { text: "EDITOR" }
        EngineMenuItem { text: "Quick Open File…"; iconName: "search.svg"; shortcutLabel: root.key("⌘P", "Ctrl+P"); enabled: root.hasProject; onTriggered: root.dispatch("quickOpen") }
        EngineMenuItem { text: "Save File"; iconName: "save.svg"; shortcutLabel: root.key("⌘S", "Ctrl+S"); enabled: root.hasTextEditor; onTriggered: root.dispatch("save") }
        EngineMenuItem { text: "Save All"; iconName: "check_badge.svg"; shortcutLabel: root.key("⇧⌘S", "Ctrl+Shift+S"); enabled: root.hasEditor && root.hasDirty; onTriggered: root.dispatch("saveAll") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Close Editor"; iconName: "close.svg"; shortcutLabel: root.key("⌘W", "Ctrl+W"); enabled: root.hasEditor; onTriggered: root.dispatch("closeEditor") }
        EngineMenuItem { text: "Close All Editors"; iconName: "file.svg"; enabled: root.hasEditor; onTriggered: root.dispatch("closeAllEditors") }
        EngineMenuItem { text: "Close Project"; iconName: "folder_1.svg"; shortcutLabel: root.key("⇧⌘W", "Ctrl+Shift+W"); enabled: root.hasProject && !root.busy; onTriggered: root.dispatch("closeProject") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Welcome Screen"; iconName: "world.svg"; enabled: !root.busy; onTriggered: root.dispatch("welcome") }
        EngineMenuItem { text: "Quit Jeridi Engine"; iconName: "close.svg"; shortcutLabel: root.key("⌘Q", "Ctrl+Q"); onTriggered: root.dispatch("quit") }
    }

    EngineMenu {
        title: "Edit"
        EngineMenuSection { text: "HISTORY" }
        EngineMenuItem { text: "Undo"; iconName: "undo.svg"; shortcutLabel: root.key("⌘Z", "Ctrl+Z"); enabled: root.hasTextEditor; onTriggered: root.dispatch("undo") }
        EngineMenuItem { text: "Redo"; iconName: "redo.svg"; shortcutLabel: root.key("⇧⌘Z", "Ctrl+Shift+Z"); enabled: root.hasTextEditor; onTriggered: root.dispatch("redo") }
        EngineMenuDivider { }
        EngineMenuSection { text: "CLIPBOARD" }
        EngineMenuItem { text: "Cut"; iconName: "cut.svg"; shortcutLabel: root.key("⌘X", "Ctrl+X"); enabled: root.hasTextEditor; onTriggered: root.dispatch("cut") }
        EngineMenuItem { text: "Copy"; iconName: "copy.svg"; shortcutLabel: root.key("⌘C", "Ctrl+C"); enabled: root.hasTextEditor; onTriggered: root.dispatch("copy") }
        EngineMenuItem { text: "Paste"; iconName: "paste.svg"; shortcutLabel: root.key("⌘V", "Ctrl+V"); enabled: root.hasTextEditor; onTriggered: root.dispatch("paste") }
        EngineMenuItem { text: "Select All"; iconName: "select-all.svg"; shortcutLabel: root.key("⌘A", "Ctrl+A"); enabled: root.hasTextEditor; onTriggered: root.dispatch("selectAll") }
        EngineMenuDivider { }
        EngineMenuSection { text: "SEARCH & NAVIGATE" }
        EngineMenuItem { text: "Find in File…"; iconName: "search.svg"; shortcutLabel: root.key("⌘F", "Ctrl+F"); enabled: root.hasTextEditor; onTriggered: root.dispatch("find") }
        EngineMenuItem { text: "Find and Replace…"; iconName: "search.svg"; shortcutLabel: root.key("⌘R", "Ctrl+R"); enabled: root.hasTextEditor; onTriggered: root.dispatch("replace") }
        EngineMenuItem { text: "Find Next"; iconName: "search.svg"; shortcutLabel: root.key("⌘G", "Ctrl+G"); enabled: root.hasTextEditor; onTriggered: root.dispatch("findNext") }
        EngineMenuItem { text: "Toggle Line Comment"; iconName: "file.svg"; shortcutLabel: root.key("⌘/", "Ctrl+/"); enabled: root.hasTextEditor; onTriggered: root.dispatch("toggleComment") }
        EngineMenuItem { text: "Code Completion"; iconName: "cube.svg"; shortcutLabel: root.key("⌃Space", "Ctrl+Space"); enabled: root.hasTextEditor; onTriggered: root.dispatch("complete") }
        EngineMenuItem { text: "Go to Line…"; iconName: "file.svg"; shortcutLabel: root.key("⌘L", "Ctrl+L"); enabled: root.hasTextEditor; onTriggered: root.dispatch("goToLine") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Copy File Path"; iconName: "copy.svg"; shortcutLabel: root.key("⌥⌘C", "Ctrl+Alt+C"); enabled: root.hasEditor; onTriggered: root.dispatch("copyFilePath") }
        EngineMenuItem { text: "Copy Project Path"; iconName: "folder.svg"; enabled: root.hasProject; onTriggered: root.dispatch("copyProjectPath") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Preferences…"; iconName: "cog_tool_administration_control_edit_option.svg"; shortcutLabel: root.key("⌘,", "Ctrl+,"); onTriggered: root.dispatch("preferences") }
    }

    EngineMenu {
        title: "View"
        EngineMenuSection { text: "WORKSPACE PANELS" }
        EngineMenuItem { text: "Component Library"; iconName: "cube.svg"; checkable: true; checked: root.showComponents; shortcutLabel: root.key("⌘3", "Ctrl+3"); onTriggered: root.dispatch("toggleComponents") }
        EngineMenuItem { text: "Project Explorer"; iconName: "tree.svg"; checkable: true; checked: root.showProjectFiles; shortcutLabel: root.key("⌘1", "Ctrl+1"); onTriggered: root.dispatch("toggleProjectFiles") }
        EngineMenuItem { text: "Output Console"; iconName: "file.svg"; checkable: true; checked: root.showOutput; shortcutLabel: root.key("⌘2", "Ctrl+2"); onTriggered: root.dispatch("toggleOutput") }
        EngineMenuItem { text: "Inspector"; iconName: "cog_tool_administration_control_edit_option.svg"; checkable: true; checked: root.showInspector; shortcutLabel: root.key("⌘4", "Ctrl+4"); onTriggered: root.dispatch("toggleInspector") }
        EngineMenuItem { text: "Live Preview Dock"; iconName: "preview.svg"; checkable: true; checked: root.showPreviewDock; shortcutLabel: root.key("⌘5", "Ctrl+5"); onTriggered: root.dispatch("togglePreviewDock") }
        EngineMenuDivider { }
        EngineMenuSection { text: "LAYOUT PRESETS" }
        EngineMenuItem { text: "Default IDE Layout"; iconName: "cube_block.svg"; onTriggered: root.dispatch("layoutDefault") }
        EngineMenuItem { text: "Code Focus"; iconName: "file.svg"; onTriggered: root.dispatch("layoutCode") }
        EngineMenuItem { text: "Preview & Design"; iconName: "preview.svg"; onTriggered: root.dispatch("layoutPreview") }
        EngineMenuItem { text: "Debug & Output"; iconName: "file.svg"; onTriggered: root.dispatch("layoutDebug") }
        EngineMenuItem { text: "Focus / Restore Editor"; iconName: "file.svg"; onTriggered: root.dispatch("focusEditor") }
        EngineMenuItem { text: "Show Core Panels"; iconName: "cube_block.svg"; shortcutLabel: root.key("⇧⌘0", "Ctrl+Shift+0"); onTriggered: root.dispatch("showAllPanels") }
        EngineMenuItem { text: "Reset Workspace Layout"; iconName: "redo.svg"; onTriggered: root.dispatch("resetWorkspace") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Preview"; iconName: "preview.svg"; enabled: root.hasProject; onTriggered: root.dispatch("preview") }
        EngineMenuSection { text: "EDITOR FONT" }
        EngineMenuItem { text: "Increase Font Size"; iconName: "file.svg"; shortcutLabel: root.key("⌘+", "Ctrl++"); enabled: root.hasTextEditor; onTriggered: root.dispatch("zoomIn") }
        EngineMenuItem { text: "Decrease Font Size"; iconName: "file.svg"; shortcutLabel: root.key("⌘−", "Ctrl+-"); enabled: root.hasTextEditor; onTriggered: root.dispatch("zoomOut") }
        EngineMenuItem { text: "Reset Font Size"; iconName: "redo.svg"; shortcutLabel: root.key("⌘0", "Ctrl+0"); enabled: root.hasTextEditor; onTriggered: root.dispatch("zoomReset") }
        EngineMenuDivider { }
        EngineMenuSection { text: "APPEARANCE" }
        EngineMenuItem { text: "Dark Theme"; iconName: "cog_tool_administration_control_edit_option.svg"; checkable: true; checked: Theme.appearance === "dark"; onTriggered: root.dispatch("darkTheme") }
        EngineMenuItem { text: "Light Theme"; iconName: "cog_tool_administration_control_edit_option.svg"; checkable: true; checked: Theme.appearance === "light"; onTriggered: root.dispatch("lightTheme") }
    }

    EngineMenu {
        title: "Navigate"
        EngineMenuSection { text: "PROJECT NAVIGATION" }
        EngineMenuItem { text: "Go to Import Target"; iconName: "file.svg"; shortcutLabel: root.key("⌘B / F12", "Ctrl+B / F12"); enabled: root.hasTextEditor; onTriggered: root.dispatch("goToImport") }
        EngineMenuItem { text: "File Imports"; iconName: "folder.svg"; enabled: root.hasTextEditor; onTriggered: root.dispatch("imports") }
        EngineMenuItem { text: "File Outline"; iconName: "tree.svg"; enabled: root.hasTextEditor; onTriggered: root.dispatch("outline") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Quick Open File…"; iconName: "search.svg"; shortcutLabel: root.key("⌘P", "Ctrl+P"); enabled: root.hasProject; onTriggered: root.dispatch("quickOpen") }
        EngineMenuItem { text: "Next Editor Tab"; iconName: "file.svg"; shortcutLabel: root.key("⌃⇥", "Ctrl+Tab"); enabled: root.hasEditor; onTriggered: root.dispatch("nextTab") }
        EngineMenuItem { text: "Previous Editor Tab"; iconName: "file.svg"; shortcutLabel: root.key("⌃⇧⇥", "Ctrl+Shift+Tab"); enabled: root.hasEditor; onTriggered: root.dispatch("previousTab") }
        EngineMenuItem { text: "Return to Preview"; iconName: "preview.svg"; enabled: root.hasProject; onTriggered: root.dispatch("preview") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Open Project Folder"; iconName: "folder.svg"; enabled: root.hasProject; onTriggered: root.dispatch("revealProject") }
        EngineMenuItem { text: "Project Information…"; iconName: "file.svg"; enabled: root.hasProject; onTriggered: root.dispatch("projectInfo") }
    }

    EngineMenu {
        title: "Run"
        EngineMenuSection { text: "EXECUTION" }
        EngineMenuItem { text: "Run Project"; iconName: "preview.svg"; shortcutLabel: root.key("⌃F5", "Ctrl+F5"); enabled: root.hasProject && !root.busy; onTriggered: root.dispatch("run") }
        EngineMenuItem { text: "Stop Process"; iconName: "close.svg"; shortcutLabel: "Shift+F5"; enabled: root.devServerActive; onTriggered: root.dispatch("stop") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Install Dependencies"; iconName: "install_options.svg"; enabled: root.hasProject && !root.busy; onTriggered: root.dispatch("installDependencies") }
        EngineMenuItem { text: "Show Output"; iconName: "file.svg"; onTriggered: root.dispatch("showOutput") }
        EngineMenuItem { text: "Copy Console Output"; iconName: "copy.svg"; onTriggered: root.dispatch("copyOutput") }
        EngineMenuItem { text: "Clear Console"; iconName: "trash.svg"; onTriggered: root.dispatch("clearOutput") }
    }

    EngineMenu {
        title: "Tools"
        EngineMenuSection { text: "PROJECT SETUP" }
        EngineMenuItem { text: "Project Generator…"; iconName: "cube_blue.svg"; shortcutLabel: root.key("⇧⌘N", "Ctrl+Shift+N"); enabled: !root.busy; onTriggered: root.dispatch("newProject") }
        EngineMenuItem { text: "Generate React in Empty Folder…"; iconName: "lang/react.svg"; enabled: root.hasProject && !root.busy; onTriggered: root.dispatch("generateReact") }
        EngineMenuItem { text: "Install Dependencies"; iconName: "install_options.svg"; enabled: root.hasProject && !root.busy; onTriggered: root.dispatch("installDependencies") }
        EngineMenuDivider { }
        EngineMenuSection { text: "ENVIRONMENT" }
        EngineMenuItem { text: "Check npm Version"; iconName: "server_square_update.svg"; enabled: !root.busy; onTriggered: root.dispatch("checkNpm") }
        EngineMenuItem { text: "Check for Engine Updates…"; iconName: "server_square_update.svg"; onTriggered: root.dispatch("checkUpdates") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Project Information…"; iconName: "file.svg"; enabled: root.hasProject; onTriggered: root.dispatch("projectInfo") }
        EngineMenuItem { text: "Preferences…"; iconName: "cog_tool_administration_control_edit_option.svg"; onTriggered: root.dispatch("preferences") }
    }

    EngineMenu {
        title: "Window"
        EngineMenuSection { text: "WINDOW MANAGEMENT" }
        EngineMenuItem { text: "Minimize"; iconName: "close.svg"; onTriggered: root.dispatch("minimize") }
        EngineMenuItem { text: "Maximize / Restore"; iconName: "cube_block.svg"; onTriggered: root.dispatch("maximize") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Welcome Screen"; iconName: "world.svg"; enabled: !root.busy; onTriggered: root.dispatch("welcome") }
        EngineMenuItem { text: "Close Window"; iconName: "close.svg"; onTriggered: root.dispatch("quit") }
    }

    EngineMenu {
        title: "Help"
        EngineMenuSection { text: "GETTING STARTED" }
        EngineMenuItem { text: "Keyboard Shortcuts…"; iconName: "select-all.svg"; shortcutLabel: root.key("⇧⌘K", "Ctrl+Shift+K"); onTriggered: root.dispatch("shortcuts") }
        EngineMenuItem { text: "Project Information…"; iconName: "file.svg"; enabled: root.hasProject; onTriggered: root.dispatch("projectInfo") }
        EngineMenuDivider { }
        EngineMenuItem { text: "Check for Updates…"; iconName: "server_square_update.svg"; onTriggered: root.dispatch("checkUpdates") }
        EngineMenuItem { text: "About Jeridi Engine…"; iconName: "cube_blue.svg"; onTriggered: root.dispatch("about") }
    }
}
