import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import JeridiEngine
import "ProjectExplorerFormat.js" as Format

// PROJECT EXPLORER v1 — read-only UI. ProjectController remains responsible
// for opening and editing files. No filesystem mutations occur in this panel.
Rectangle {
    id: root

    // Existing public contract, preserved for Main.qml.
    property url projectFolder: ""
    property url selectedFile: ""
    property string projectName: ""
    signal fileSelected(url file)
    signal fileOpenRequested(url file)

    readonly property bool hasProject: projectFolder.toString().length > 0
    readonly property bool searching: searchText.trim().length > 0
    readonly property bool flatMode: searching || filterMode === "starred"
    readonly property var displayRows: searching ? searchRows : starredRows
    readonly property int favoriteCount: starredRows.length

    property string searchText: ""
    property string filterMode: "all" // all | code | media | starred
    property bool showHiddenFiles: false
    property bool treeEnabled: true
    property var activeDetails: ({})
    property var favorites: ({})
    property var starredRows: []
    property var searchRows: []
    property int searchScanned: 0
    property bool searchLimited: false

    color: Theme.colors.panel
    visible: engineToolbar.showProjectFiles
    SplitView.fillWidth: !engineToolbar.showOutput

    Settings {
        id: explorerSettings
        category: "ProjectExplorer"
        property string favoritesByProject: "{}"
        property bool hiddenFilesVisible: false
    }

    ProjectFilesModel {
        id: filesModel
        showHidden: root.showHiddenFiles
        typeFilter: root.filterMode === "code" || root.filterMode === "media"
                    ? root.filterMode : "all"
    }

    function restoreFavorites() {
        favorites = Format.safeFavorites(explorerSettings.favoritesByProject,
                                         projectFolder.toString())
        rebuildStarred()
    }

    function toggleFavorite(relative) {
        if (!relative || !hasProject) return
        const next = Object.assign({}, favorites)
        if (next[relative]) delete next[relative]
        else next[relative] = true
        favorites = next
        explorerSettings.favoritesByProject = Format.serializeFavorites(
                    explorerSettings.favoritesByProject, projectFolder.toString(), next)
        rebuildStarred()
        if (searching) performSearch()
    }

    function rebuildStarred() {
        const rows = []
        const keys = Object.keys(favorites).sort()
        for (let i = 0; i < keys.length; ++i) {
            const url = filesModel.urlForRelativePath(keys[i])
            const details = filesModel.detailsForUrl(url)
            if (details && details.name) rows.push(details)
        }
        starredRows = rows
    }

    function performSearch() {
        if (!hasProject || !searching) {
            searchRows = []
            searchLimited = false
            searchScanned = 0
            return
        }
        if (filterMode === "starred") {
            const needle = searchText.trim().toLowerCase()
            searchRows = starredRows.filter(function(entry) {
                return String(entry.relativePath || "").toLowerCase().indexOf(needle) >= 0
            })
            searchScanned = starredRows.length
            searchLimited = false
            return
        }
        const result = filesModel.searchFiles(searchText, filterMode, 120)
        searchRows = result.results || []
        searchScanned = Number(result.scanned || 0)
        searchLimited = !!result.limited
    }

    function selectEntry(details) {
        if (!details || !details.name) return
        activeDetails = details
        if (!details.folder && details.url)
            fileSelected(details.url)
    }

    function openEntry(details) {
        if (!details || !details.url) return
        if (details.folder) {
            Qt.openUrlExternally(details.url)
        } else {
            selectEntry(details)
            fileOpenRequested(details.url)
        }
    }

    function refreshTree() {
        if (!hasProject) return
        // A fresh TreeView resets expansion and asks QFileSystemModel for the root.
        treeEnabled = false
        filesModel.openFolder(projectFolder)
        treeEnabled = true
        rebuildStarred()
        if (searching) performSearch()
    }

    function reopenProject() {
        filesModel.openFolder(projectFolder)
        activeDetails = ({})
        searchText = ""
        filterMode = "all"
        restoreFavorites()
        refreshTree()
    }

    onProjectFolderChanged: Qt.callLater(root.reopenProject)
    onSelectedFileChanged: {
        if (selectedFile.toString().length > 0) {
            const details = filesModel.detailsForUrl(selectedFile)
            if (details && details.name) activeDetails = details
        }
    }
    onSearchTextChanged: {
        if (searching) searchTimer.restart()
        else { searchTimer.stop(); searchRows = []; searchLimited = false }
    }
    onFilterModeChanged: {
        rebuildStarred()
        if (searching) searchTimer.restart()
    }
    onShowHiddenFilesChanged: {
        explorerSettings.hiddenFilesVisible = showHiddenFiles
        rebuildStarred()
        if (searching) searchTimer.restart()
    }
    Component.onCompleted: {
        showHiddenFiles = explorerSettings.hiddenFilesVisible
        reopenProject()
    }

    Timer {
        id: searchTimer
        interval: 180
        repeat: false
        onTriggered: root.performSearch()
    }

    Component {
        id: treeComponent
        TreeView {
            id: tree
            clip: true
            reuseItems: false
            boundsBehavior: Flickable.StopAtBounds
            editTriggers: TableView.NoEditTriggers
            activeFocusOnTab: true
            model: filesModel
            rootIndex: filesModel.openFolder(root.projectFolder)
            columnWidthProvider: function(column) { return column === 0 ? width : 0 }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: ProjectExplorerFileRow {
                required property int row
                required property int depth
                required property bool expanded
                required property bool hasChildren
                required property string display

                readonly property var entryDetails: filesModel.fileDetails(tree.index(row, 0))
                width: tree.width
                height: 28
                details: entryDetails
                indentLevel: depth
                nodeExpanded: expanded
                nodeHasChildren: hasChildren
                nodeSelected: !!(root.activeDetails.absolutePath && entryDetails.absolutePath
                             && root.activeDetails.absolutePath === entryDetails.absolutePath)
                nodeStarred: Format.isFavorite(root.favorites, String(entryDetails.relativePath || ""))

                onActivated: function(details) {
                    root.selectEntry(details)
                    if (details.folder) tree.toggleExpanded(row)
                }
                onOpenRequested: function(details) { root.openEntry(details) }
                onFavoriteRequested: function(relative) { root.toggleFavorite(relative) }
                onCopyRequested: function(value) { filesModel.copyText(value) }
                onExternalRequested: function(url) { Qt.openUrlExternally(url) }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ProjectExplorerHeader {
            Layout.fillWidth: true
            projectName: root.projectName
            projectOpen: root.hasProject
            searchText: root.searchText
            filterMode: root.filterMode
            favoriteCount: root.favoriteCount
            onSearchChanged: function(value) { root.searchText = value }
            onFilterRequested: function(value) { root.filterMode = value }
        }

        ProjectExplorerActions {
            Layout.fillWidth: true
            projectOpen: root.hasProject
            treeMode: !root.flatMode
            showHidden: root.showHiddenFiles
            detailsVisible: detailsPopup.visible
            sectionLabel: root.searching ? "SEARCH RESULTS"
                          : root.filterMode === "starred" ? "STARRED FILES" : "PROJECT TREE"
            countLabel: root.searching ? root.searchRows.length + " found"
                        : root.filterMode === "starred" ? root.starredRows.length + " items" : "LIVE"
            onExpandRequested: {
                if (treeLoader.item) treeLoader.item.expandRecursively(-1, 2)
            }
            onCollapseRequested: {
                if (treeLoader.item) treeLoader.item.collapseRecursively()
            }
            onRefreshRequested: root.refreshTree()
            onHiddenToggled: {
                root.showHiddenFiles = !root.showHiddenFiles
                root.refreshTree()
            }
            onDetailsToggled: detailsPopup.visible ? detailsPopup.close() : detailsPopup.open()
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Loader {
                id: treeLoader
                anchors.fill: parent
                active: root.hasProject && root.treeEnabled
                visible: !root.flatMode
                sourceComponent: treeComponent
            }

            ListView {
                id: flatList
                anchors.fill: parent
                visible: root.hasProject && root.flatMode
                model: root.flatMode ? root.displayRows : []
                clip: true
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: ProjectExplorerFileRow {
                    required property var modelData
                    width: flatList.width
                    height: 38
                    searchMode: true
                    details: modelData
                    nodeSelected: !!(root.activeDetails.absolutePath && modelData.absolutePath
                                 && root.activeDetails.absolutePath === modelData.absolutePath)
                    nodeStarred: Format.isFavorite(root.favorites, String(modelData.relativePath || ""))
                    onActivated: function(details) { root.selectEntry(details) }
                    onOpenRequested: function(details) { root.openEntry(details) }
                    onFavoriteRequested: function(relative) { root.toggleFavorite(relative) }
                    onCopyRequested: function(value) { filesModel.copyText(value) }
                    onExternalRequested: function(url) { Qt.openUrlExternally(url) }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.max(130, parent.width - 24)
                spacing: 7
                visible: !root.hasProject || (root.flatMode && root.displayRows.length === 0)
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 25
                    Layout.preferredHeight: 25
                    source: root.hasProject ? "qrc:/engine/assets/icons/search.svg"
                                            : "qrc:/engine/assets/icons/folder.svg"
                    opacity: 0.5
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: !root.hasProject ? "Open a project to browse files"
                          : root.filterMode === "starred" ? "No starred files match"
                          : "No matching files"
                    font.pixelSize: 11
                    color: Theme.colors.muted
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 25
            color: Theme.colors.surface
            Rectangle { width: parent.width; height: 1; color: Theme.colors.border }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 6
                Rectangle {
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: root.hasProject ? "#20BD89" : Theme.colors.disabled
                }
                Label {
                    Layout.fillWidth: true
                    text: root.searching && root.searchLimited
                          ? "Partial results · refine search"
                          : root.searching ? root.searchRows.length + " matches · " + root.searchScanned + " scanned"
                          : root.hasProject ? "Read-only explorer · safe browsing" : "No active project"
                    font.pixelSize: 9
                    color: root.searchLimited ? Theme.colors.error : Theme.colors.muted
                    elide: Text.ElideRight
                }
                ProjectExplorerIconButton {
                    glyph: "ⓘ"
                    hint: "Selected item details"
                    actionEnabled: root.hasProject
                    selected: detailsPopup.visible
                    onTriggered: detailsPopup.visible ? detailsPopup.close() : detailsPopup.open()
                }
            }
        }
    }

    Popup {
        id: detailsPopup
        parent: root
        x: 7
        y: Math.max(3, root.height - height - 27)
        width: Math.max(200, root.width - 14)
        height: 180
        padding: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: "transparent" }
        contentItem: ProjectExplorerDetails {
            details: root.activeDetails
            starred: Format.isFavorite(root.favorites, String(root.activeDetails.relativePath || ""))
            onOpenRequested: function(details) { root.openEntry(details); detailsPopup.close() }
            onCopyRequested: function(value) { filesModel.copyText(value) }
            onFavoriteRequested: function(relative) { root.toggleFavorite(relative) }
            onCloseRequested: detailsPopup.close()
        }
    }
}
