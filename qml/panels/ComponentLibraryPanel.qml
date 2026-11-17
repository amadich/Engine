import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import "LibraryModel.js" as LibraryModel
import JeridiEngine

// COMPONENT LIBRARY / explorer
// Pure UI: reads the package registry and installation status. Row selection NEVER installs.
// Installation goes only through ComponentManager.requestInstall -> existing confirmation dialog.
Rectangle {
    id: root

    // Kept for compatibility with existing WorkspaceView integrations.
    property bool canAddComponent: false
    property var componentManager: null
    property string selectedComponentId: ""
    signal componentSelected(string componentId)
    signal installComponentRequested(string componentId)

    readonly property bool projectOpen: !!(componentManager
                                      && componentManager.projectController
                                      && componentManager.projectController.activeProjectPath !== "")
    readonly property bool hasInstallDialog: !!(componentManager
                                             && typeof componentManager.requestInstall === "function")
    readonly property string activeId: selectedComponentId.length > 0
                                       ? selectedComponentId : localSelectedId
    readonly property var selectedDefinition: activeId.length > 0
                                              ? ComponentRegistry.component(activeId) : ({})

    property string localSelectedId: ""
    property string filterMode: "all"      // all | installed | favorites
    property string sortMode: "name"       // name | installed
    property string searchText: ""
    property var favorites: ({})
    property var installed: ({})
    property var expandedGroups: ({})
    property var visibleRows: []
    property int catalogCount: 0
    property int installedCount: 0
    property int favoriteCount: 0
    property int visibleComponentCount: 0

    color: Theme.colors.surface

    Settings {
        id: libraryPreferences
        category: "ComponentLibrary"
        property string favoriteIds: "[]"
    }

    function readFavorites() {
        const result = ({})
        try {
            const ids = JSON.parse(libraryPreferences.favoriteIds)
            if (Array.isArray(ids)) {
                for (let i = 0; i < ids.length; ++i) {
                    if (typeof ids[i] === "string")
                        result[ids[i]] = true
                }
            }
        } catch (error) {
            // Invalid user preferences are ignored; the project is never touched.
        }
        favorites = result
        updateCounts()
        rebuildRows()
    }

    function toggleFavorite(id) {
        if (!id) return
        const copy = Object.assign({}, favorites)
        if (copy[id]) delete copy[id]
        else copy[id] = true
        favorites = copy
        libraryPreferences.favoriteIds = JSON.stringify(Object.keys(copy))
        updateCounts()
        rebuildRows()
    }

    function refreshInstallations() {
        const result = ({})
        const all = ComponentRegistry.components || []
        if (projectOpen && componentManager) {
            for (let i = 0; i < all.length; ++i) {
                const id = String(all[i].id || "")
                if (id) result[id] = !!componentManager.isInstalled(id)
            }
        }
        installed = result
        updateCounts()
        rebuildRows()
    }

    function updateCounts() {
        const stats = LibraryModel.counts(ComponentRegistry.components || [], installed, favorites)
        catalogCount = stats.catalog
        installedCount = stats.installed
        favoriteCount = stats.favorites
    }

    function rebuildRows() {
        const view = LibraryModel.buildRows(ComponentRegistry.components || [],
                          installed, favorites, filterMode, sortMode, searchText,
                          expandedGroups)
        visibleRows = view.rows
        visibleComponentCount = view.matched
    }

    function toggleGroup(path) {
        if (searchText.trim().length > 0) return // Search expands results temporarily.
        const copy = Object.assign({}, expandedGroups)
        const row = visibleRows.find(function(item) {
            return item.kind === "category" && item.path === path
        })
        copy[path] = row ? !row.expanded : true
        expandedGroups = copy
        rebuildRows()
    }

    function setAllExpanded(expand) {
        expandedGroups = LibraryModel.expandAll(ComponentRegistry.components || [], expand)
        rebuildRows()
    }

    function activateComponent(id) {
        if (!id) return
        localSelectedId = id
        componentSelected(id) // Inspect only: never writes to project.
    }

    function activateRow(entry) {
        if (!entry) return
        if (entry.kind === "category") toggleGroup(entry.path)
        else if (entry.kind === "component") activateComponent(entry.id)
    }

    onFilterModeChanged: rebuildRows()
    onSortModeChanged: rebuildRows()
    onSearchTextChanged: rebuildRows()
    onComponentManagerChanged: refreshInstallations()
    onProjectOpenChanged: refreshInstallations()
    Component.onCompleted: { readFavorites(); refreshInstallations() }

    Connections {
        target: root.componentManager
        function onComponentInstalled(id) { root.refreshInstallations() }
        function onComponentMoved(id) { root.refreshInstallations() }
        function onComponentRemoved(id) { root.refreshInstallations() }
    }
    Connections {
        target: root.componentManager ? root.componentManager.projectController : null
        function onActiveProjectChanged() { root.refreshInstallations() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        LibraryToolbar {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            catalogCount: root.catalogCount
            installedCount: root.installedCount
            favoriteCount: root.favoriteCount
            visibleComponentCount: root.visibleComponentCount
            filterMode: root.filterMode
            sortMode: root.sortMode
            searchText: root.searchText
            onSearchChanged: function(text) { root.searchText = text }
            onFilterRequested: function(mode) { root.filterMode = mode }
            onExpandRequested: root.setAllExpanded(true)
            onCollapseRequested: root.setAllExpanded(false)
            onRefreshRequested: root.refreshInstallations()
            onSortRequested: root.sortMode = root.sortMode === "name" ? "installed" : "name"
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ListView {
                id: packageList
                anchors.fill: parent
                model: root.visibleRows
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 0
                activeFocusOnTab: true
                keyNavigationEnabled: true
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
                delegate: Item {
                    required property var modelData
                    width: packageList.width
                    height: modelData.kind === "category" ? 28 : 34

                    LibraryCategoryRow {
                        anchors.fill: parent
                        visible: modelData.kind === "category"
                        entry: modelData
                        onToggled: function(path) { root.toggleGroup(path) }
                    }
                    LibraryComponentRow {
                        anchors.fill: parent
                        visible: modelData.kind === "component"
                        entry: modelData
                        selected: root.activeId === String(modelData.id || "")
                        favorite: !!root.favorites[String(modelData.id || "")]
                        installed: !!root.installed[String(modelData.id || "")]
                        onActivated: function(id) { root.activateComponent(id) }
                        onFavoriteToggled: function(id) { root.toggleFavorite(id) }
                    }
                }
                Keys.onReturnPressed: root.activateRow(root.visibleRows[currentIndex])
                Keys.onEnterPressed: root.activateRow(root.visibleRows[currentIndex])
                Keys.onSpacePressed: root.activateRow(root.visibleRows[currentIndex])
            }
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.max(120, parent.width - 28)
                spacing: 8
                visible: root.visibleComponentCount === 0
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 25
                    Layout.preferredHeight: 25
                    source: "qrc:/engine/assets/icons/search.svg"
                    sourceSize: Qt.size(50, 50)
                    opacity: 0.5
                }
                Label {
                    Layout.fillWidth: true
                    text: root.filterMode === "favorites" && root.favoriteCount === 0
                          ? "No starred packages yet"
                          : root.filterMode === "installed" && root.installedCount === 0
                            ? "No installed packages" : "No matching components"
                    font.pixelSize: 11
                    color: Theme.colors.muted
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    text: "Try another search or filter."
                    font.pixelSize: 9
                    color: Theme.colors.disabled
                    horizontalAlignment: Text.AlignHCenter
                }
                LibraryIconButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 26
                    iconSource: "qrc:/engine/assets/icons/close.svg"
                    hint: "Clear search and filters"
                    onTriggered: { root.searchText = ""; root.filterMode = "all" }
                }
            }
        }

        LibraryDetails {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            selectedId: root.activeId
            definition: root.selectedDefinition
            installed: !!root.installed[root.activeId]
            favorite: !!root.favorites[root.activeId]
            projectOpen: root.projectOpen
            canInstall: root.canAddComponent
            hasInstallDialog: root.hasInstallDialog
            installedDirectory: root.projectOpen && root.componentManager
                                && root.activeId && root.installed[root.activeId]
                                ? root.componentManager.installedDirectory(root.activeId) : ""
            onInspectRequested: function(id) { root.activateComponent(id) }
            onFavoriteToggled: function(id) { root.toggleFavorite(id) }
            onInstallRequested: function(id) {
                if (root.hasInstallDialog && root.canAddComponent
                        && !root.installed[id]) {
                    // Existing ComponentManager dialog workflow. No direct file writes.
                    root.componentManager.requestInstall(id)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 23
            color: Theme.colors.panel
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6
                Rectangle {
                    Layout.preferredWidth: 5
                    Layout.preferredHeight: 5
                    radius: 3
                    color: root.projectOpen ? "#32C48D" : Theme.colors.disabled
                }
                Label {
                    Layout.fillWidth: true
                    text: root.projectOpen ? "Project connected" : "Preview mode · no project"
                    font.pixelSize: 9
                    color: Theme.colors.muted
                    elide: Text.ElideRight
                }
                Label {
                    text: root.visibleComponentCount + " / " + root.catalogCount
                    font.pixelSize: 9
                    color: Theme.colors.muted
                }
            }
        }
    }
}
