import QtQuick
import QtQuick.Controls
import QtCore
import JeridiEngine
import "DockState.js" as DockState

// Jeridi Engine 0.6.2: five persistent tool windows + permanent editor.
// All content is created exactly once. Geometry is computed declaratively,
// without reparenting QML items or using nested SplitViews.
Item {
    id: root
    clip: true

    required property ProjectController controller
    required property ComponentManager componentManager
    property url previewUrl: ""
    property bool devServerActive: false
    property var selectedFileDetails: ({})
    property url selectedFileUrl: ""
    property string selectedComponentId: ""
    property bool canAddComponent: false
    property alias editorWorkspace: editorWorkspace
    property alias outputPanel: outputPanel
    property string focusPanelId: ""
    property var panels: DockState.defaults()
    property int layoutRevision: 0
    property real leftDockWidth: dockSettings.leftWidth
    property real rightDockWidth: dockSettings.rightWidth

    readonly property var visibilityMap: {
        var revision = root.layoutRevision
        var map = ({})
        for (var i = 0; i < root.panels.length; i++)
            map[root.panels[i].id] = root.panels[i].visible
        return map
    }
    readonly property var geometry: {
        var revision = root.layoutRevision
        var sizes = ({
            components: componentsDock.preferredDockHeight,
            files: filesDock.preferredDockHeight,
            output: outputDock.preferredDockHeight,
            inspector: inspectorDock.preferredDockHeight,
            preview: previewDock.preferredDockHeight
        })
        return DockState.calculate(root.width, root.height, dockBar.height,
                                      root.panels, root.focusPanelId,
                                      root.leftDockWidth, root.rightDockWidth, sizes)
    }

    signal fileActivated(url file)
    signal installComponentRequested(string componentId)

    Settings {
        id: dockSettings
        category: "WorkspaceDock_v06"
        property string layoutJson: ""
        property int leftWidth: 260
        property int rightWidth: 300
    }

    Connections {
        target: root.controller
        function onActiveProjectChanged() { root.selectedComponentId = "" }
    }

    function panelVisible(id) {
        var revision = root.layoutRevision
        return DockState.isVisible(root.panels, id)
    }

    function panelZone(id) {
        var revision = root.layoutRevision
        var p = root.panels.find(function(item) { return item.id === id })
        return p ? p.zone : "left"
    }

    function canReorder(id, direction) {
        var revision = root.layoutRevision
        var zone = panelZone(id)
        var order = DockState.orderedInZone(root.panels, zone)
        var index = order.indexOf(id)
        return index >= 0 && index + direction >= 0 && index + direction < order.length
    }

    function commit(next) {
        root.panels = DockState.parse(JSON.stringify(next))
        root.layoutRevision++
        dockSettings.layoutJson = JSON.stringify(root.panels)
    }

    function restoreLayout() {
        root.panels = DockState.parse(dockSettings.layoutJson)
        root.layoutRevision++
    }

    function setPanelVisible(id, value) {
        if (!DockState.validId(id)) return
        if (root.focusPanelId !== "") root.focusPanelId = ""
        commit(DockState.setVisible(root.panels, id, value))
    }

    function togglePanel(id) { setPanelVisible(id, !panelVisible(id)) }

    function movePanel(id, zone) {
        if (!DockState.validId(id) || !DockState.validZone(zone)) return
        root.focusPanelId = ""
        commit(DockState.move(root.panels, id, zone))
    }

    function reorderPanel(id, offset) {
        if (!DockState.validId(id)) return
        commit(DockState.reorder(root.panels, id, offset))
    }

    function focusPanel(id) {
        if (id !== "editor" && !DockState.validId(id)) return
        root.focusPanelId = (root.focusPanelId === id ? "" : id)
        if (root.focusPanelId !== "" && id !== "editor" && !panelVisible(id))
            commit(DockState.setVisible(root.panels, id, true))
    }

    function restoreFocus() { root.focusPanelId = "" }

    function resetLayout() {
        root.focusPanelId = ""
        commit(DockState.defaults())
    }

    function applyPreset(name) {
        root.focusPanelId = name === "code" ? "editor" : ""
        commit(DockState.preset(name))
    }

    Component.onCompleted: restoreLayout()

    Timer {
        id: geometryDiagnostics
        interval: 250
        repeat: false
        onTriggered: {
            console.info("[Jeridi Workspace 0.6.2] root:", root.width, "x", root.height,
                         "editor:", editorWorkspace.width, "x", editorWorkspace.height,
                         "library:", componentsDock.width, "x", componentsDock.height,
                         "visible:", editorWorkspace.visible, componentsDock.visible)
        }
    }
    onVisibleChanged: {
        if (visible) geometryDiagnostics.restart()
    }

    DockLayoutBar {
        id: dockBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 34
        z: 30
        visiblePanels: root.visibilityMap
        focusPanel: root.focusPanelId
        onToggleRequested: function(id) { root.togglePanel(id) }
        onPresetRequested: function(name) { root.applyPreset(name) }
        onResetRequested: root.resetLayout()
        onFocusEditorRequested: root.focusPanel("editor")
    }

    // Unlike a nested SplitView, the editor is always a direct child of this
    // workspace. No asynchronous insert, takeItem or parent reassignment.
    EditorWorkspace {
        id: editorWorkspace
        x: root.geometry.editor.x
        y: root.geometry.editor.y
        width: root.geometry.editor.width
        height: root.geometry.editor.height
        visible: root.geometry.editor.visible
        controller: root.controller
        previewUrl: root.previewUrl
        devServerActive: root.devServerActive
        onFileActivated: function(file) { root.restoreFocus(); root.fileActivated(file) }
    }

    DockFrame {
        id: componentsDock
        panelId: "components"
        panelTitle: "COMPONENT LIBRARY"
        iconName: "cube.svg"
        zone: root.panelZone(panelId)
        canMoveUp: root.canReorder(panelId, -1)
        canMoveDown: root.canReorder(panelId, 1)
        fillDock: root.geometry.components.fill
        x: root.geometry.components.x
        y: root.geometry.components.y
        width: root.geometry.components.width
        height: root.geometry.components.height
        visible: root.geometry.components.visible
        onMoveRequested: function(id, zone) { root.movePanel(id, zone) }
        onReorderRequested: function(id, offset) { root.reorderPanel(id, offset) }
        onHideRequested: function(id) { root.setPanelVisible(id, false) }
        onFocusRequested: function(id) { root.focusPanel(id) }
        ComponentLibraryPanel {
            anchors.fill: parent
            canAddComponent: root.canAddComponent
            componentManager: root.componentManager
            selectedComponentId: root.selectedComponentId
            onInstallComponentRequested: function(id) { root.installComponentRequested(id) }
            onComponentSelected: function(id) {
                root.selectedComponentId = id
                root.setPanelVisible("inspector", true)
            }
        }
    }

    DockFrame {
        id: filesDock
        panelId: "files"
        panelTitle: "PROJECT EXPLORER"
        iconName: "tree.svg"
        zone: root.panelZone(panelId)
        canMoveUp: root.canReorder(panelId, -1)
        canMoveDown: root.canReorder(panelId, 1)
        fillDock: root.geometry.files.fill
        x: root.geometry.files.x
        y: root.geometry.files.y
        width: root.geometry.files.width
        height: root.geometry.files.height
        visible: root.geometry.files.visible
        onMoveRequested: function(id, zone) { root.movePanel(id, zone) }
        onReorderRequested: function(id, offset) { root.reorderPanel(id, offset) }
        onHideRequested: function(id) { root.setPanelVisible(id, false) }
        onFocusRequested: function(id) { root.focusPanel(id) }
        ProjectFilesPanel {
            anchors.fill: parent
            projectFolder: root.controller.projectFolderUrl
            projectName: root.controller.activeProjectName
            selectedFile: root.selectedFileUrl
            onFileSelected: function(file) { root.fileActivated(file) }
            onFileOpenRequested: function(file) { root.restoreFocus(); editorWorkspace.openFile(file) }
        }
    }

    DockFrame {
        id: outputDock
        panelId: "output"
        panelTitle: "OUTPUT CONSOLE"
        iconName: "file.svg"
        zone: root.panelZone(panelId)
        canMoveUp: root.canReorder(panelId, -1)
        canMoveDown: root.canReorder(panelId, 1)
        fillDock: root.geometry.output.fill
        x: root.geometry.output.x
        y: root.geometry.output.y
        width: root.geometry.output.width
        height: root.geometry.output.height
        visible: root.geometry.output.visible
        onMoveRequested: function(id, zone) { root.movePanel(id, zone) }
        onReorderRequested: function(id, offset) { root.reorderPanel(id, offset) }
        onHideRequested: function(id) { root.setPanelVisible(id, false) }
        onFocusRequested: function(id) { root.focusPanel(id) }
        OutputPanel {
            id: outputPanel
            anchors.fill: parent
        }
    }

    DockFrame {
        id: inspectorDock
        panelId: "inspector"
        panelTitle: "INSPECTOR"
        iconName: "cog_tool_administration_control_edit_option.svg"
        zone: root.panelZone(panelId)
        canMoveUp: root.canReorder(panelId, -1)
        canMoveDown: root.canReorder(panelId, 1)
        fillDock: root.geometry.inspector.fill
        x: root.geometry.inspector.x
        y: root.geometry.inspector.y
        width: root.geometry.inspector.width
        height: root.geometry.inspector.height
        visible: root.geometry.inspector.visible
        onMoveRequested: function(id, zone) { root.movePanel(id, zone) }
        onReorderRequested: function(id, offset) { root.reorderPanel(id, offset) }
        onHideRequested: function(id) { root.setPanelVisible(id, false) }
        onFocusRequested: function(id) { root.focusPanel(id) }
        InspectorHost {
            anchors.fill: parent
            controller: root.controller
            componentManager: root.componentManager
            componentId: root.selectedComponentId
            fileDetails: root.selectedFileDetails
        }
    }

    DockFrame {
        id: previewDock
        panelId: "preview"
        panelTitle: "LIVE PREVIEW"
        iconName: "preview.svg"
        zone: root.panelZone(panelId)
        canMoveUp: root.canReorder(panelId, -1)
        canMoveDown: root.canReorder(panelId, 1)
        fillDock: root.geometry.preview.fill
        x: root.geometry.preview.x
        y: root.geometry.preview.y
        width: root.geometry.preview.width
        height: root.geometry.preview.height
        visible: root.geometry.preview.visible
        onMoveRequested: function(id, zone) { root.movePanel(id, zone) }
        onReorderRequested: function(id, offset) { root.reorderPanel(id, offset) }
        onHideRequested: function(id) { root.setPanelVisible(id, false) }
        onFocusRequested: function(id) { root.focusPanel(id) }
        PreviewPanel {
            anchors.fill: parent
            previewUrl: root.previewUrl
            devServerActive: root.devServerActive
            dockActive: previewDock.visible
        }
    }

    // Small handles for changing the left and right column widths.
    Rectangle {
        id: leftSplitter
        x: root.geometry.leftHandle.x
        y: root.geometry.leftHandle.y
        width: root.geometry.leftHandle.width
        height: root.geometry.leftHandle.height
        visible: root.geometry.leftHandle.visible
        z: 20
        color: leftResize.containsMouse ? Theme.colors.accent : Theme.colors.border
        MouseArea {
            id: leftResize
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SplitHCursor
            property real startX: 0
            property real startWidth: 0
            onPressed: function(mouse) {
                startX = mapToItem(root, mouse.x, mouse.y).x
                startWidth = root.leftDockWidth
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return
                var delta = mapToItem(root, mouse.x, mouse.y).x - startX
                root.leftDockWidth = Math.max(170, Math.min(680, startWidth + delta))
            }
            onReleased: dockSettings.leftWidth = Math.round(root.leftDockWidth)
        }
    }
    Rectangle {
        id: rightSplitter
        x: root.geometry.rightHandle.x
        y: root.geometry.rightHandle.y
        width: root.geometry.rightHandle.width
        height: root.geometry.rightHandle.height
        visible: root.geometry.rightHandle.visible
        z: 20
        color: rightResize.containsMouse ? Theme.colors.accent : Theme.colors.border
        MouseArea {
            id: rightResize
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SplitHCursor
            property real startX: 0
            property real startWidth: 0
            onPressed: function(mouse) {
                startX = mapToItem(root, mouse.x, mouse.y).x
                startWidth = root.rightDockWidth
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return
                var delta = mapToItem(root, mouse.x, mouse.y).x - startX
                root.rightDockWidth = Math.max(170, Math.min(680, startWidth - delta))
            }
            onReleased: dockSettings.rightWidth = Math.round(root.rightDockWidth)
        }
    }
}
