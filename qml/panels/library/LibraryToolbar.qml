import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Stateless toolbar: search/filter/expand events are handled by the parent view-model.
Item {
    id: root
    property int catalogCount: 0
    property int installedCount: 0
    property int favoriteCount: 0
    property int visibleComponentCount: 0
    property string filterMode: "all"
    property string sortMode: "name"
    property string searchText: ""
    signal searchChanged(string text)
    signal filterRequested(string mode)
    signal expandRequested()
    signal collapseRequested()
    signal refreshRequested()
    signal sortRequested()
    implicitHeight: 163

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        // Header matches the Inspector's 63px compact language.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 57
            color: Theme.colors.surface
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.colors.border
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 11
                anchors.rightMargin: 10
                spacing: 8
                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 6
                    color: "Transparent" /*Theme.colors.control*/
                    border.width: 0
                    border.color: Theme.colors.border
                    Image {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: "qrc:/engine/assets/icons/cube_block.svg"
                        sourceSize: Qt.size(36, 36)
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 2
                    Label {
                        Layout.fillWidth: true
                        text: "COMPONENT LIBRARY"
                        color: Theme.colors.text
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: "Packages · Project explorer"
                        color: Theme.colors.muted
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }
                Rectangle {
                    Layout.preferredWidth: Math.max(24, totalLabel.implicitWidth + 11)
                    Layout.preferredHeight: 22
                    radius: 5
                    color: "Transparent" /*Theme.colors.control*/
                    border.width: 0
                    border.color: Theme.colors.border
                    Label {
                        id: totalLabel
                        anchors.centerIn: parent
                        text: String(root.catalogCount)
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.colors.accent
                    }
                }
            }
        }

        // Search input and clear action.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Theme.colors.panel
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                spacing: 0
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 27
                    radius: 4
                    color: Theme.colors.surface
                    border.width: 1
                    border.color: searchInput.activeFocus ? Theme.colors.accent : Theme.colors.border
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 4
                        spacing: 5
                        Image {
                            Layout.preferredWidth: 13
                            Layout.preferredHeight: 13
                            source: "qrc:/engine/assets/icons/search.svg"
                            sourceSize: Qt.size(26, 26)
                            opacity: 0.75
                        }
                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            placeholderText: "Find components, paths…"
                            color: Theme.colors.text
                            placeholderTextColor: Theme.colors.muted
                            font.pixelSize: 10
                            leftPadding: 0
                            rightPadding: 0
                            selectByMouse: true
                            background: Item {}
                            text: root.searchText
                            onTextEdited: root.searchChanged(text)
                            Keys.onEscapePressed: root.searchChanged("")
                        }
                        LibraryIconButton {
                            visible: searchInput.text.length > 0
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            iconSource: "qrc:/engine/assets/icons/close.svg"
                            iconSize: 11
                            hint: "Clear search"
                            onTriggered: root.searchChanged("")
                        }
                    }
                }
            }
        }

        // Compact filter bar. Counts come from ComponentRegistry and ComponentManager.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: Theme.colors.panel
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                spacing: 5
                LibraryFilterChip {
                    Layout.fillWidth: true
                    label: "All"
                    count: root.catalogCount
                    selected: root.filterMode === "all"
                    onTriggered: root.filterRequested("all")
                }
                LibraryFilterChip {
                    Layout.fillWidth: true
                    label: "Installed"
                    count: root.installedCount
                    selected: root.filterMode === "installed"
                    onTriggered: root.filterRequested("installed")
                }
                LibraryFilterChip {
                    Layout.fillWidth: true
                    label: "Starred"
                    count: root.favoriteCount
                    selected: root.filterMode === "favorites"
                    onTriggered: root.filterRequested("favorites")
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: Theme.colors.surface
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.colors.border
                opacity: 0.75
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 11
                anchors.rightMargin: 8
                spacing: 3
                Image {
                    Layout.preferredWidth: 13
                    Layout.preferredHeight: 13
                    source: "qrc:/engine/assets/icons/folder_1.svg"
                    sourceSize: Qt.size(26, 26)
                }
                Label {
                    Layout.fillWidth: true
                    text: "PACKAGE TREE"
                    font.pixelSize: 9
                    font.bold: true
                    color: Theme.colors.muted
                }
                Label {
                    text: String(root.visibleComponentCount)
                    font.pixelSize: 9
                    color: Theme.colors.muted
                }
                LibraryIconButton {
                    Layout.preferredWidth: 23
                    Layout.preferredHeight: 23
                    glyph: "⊞"
                    hint: "Expand all categories"
                    actionEnabled: root.searchText.trim().length === 0
                    disabledReason: "Search results are expanded automatically"
                    onTriggered: root.expandRequested()
                }
                LibraryIconButton {
                    Layout.preferredWidth: 23
                    Layout.preferredHeight: 23
                    glyph: "⊟"
                    hint: "Collapse all categories"
                    actionEnabled: root.searchText.trim().length === 0
                    disabledReason: "Clear search before collapsing"
                    onTriggered: root.collapseRequested()
                }
                LibraryIconButton {
                    Layout.preferredWidth: 23
                    Layout.preferredHeight: 23
                    iconSource: "qrc:/engine/assets/icons/redo.svg"
                    iconSize: 13
                    hint: "Refresh installation status from the project"
                    onTriggered: root.refreshRequested()
                }
                LibraryIconButton {
                    Layout.preferredWidth: 23
                    Layout.preferredHeight: 23
                    glyph: root.sortMode === "name" ? "A" : "↓"
                    selected: root.sortMode === "installed"
                    hint: root.sortMode === "name" ? "Sort: name. Click for installed first"
                                                   : "Sort: installed first. Click for name"
                    onTriggered: root.sortRequested()
                }
            }
        }

    }
}
