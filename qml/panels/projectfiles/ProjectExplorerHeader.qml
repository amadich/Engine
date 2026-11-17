import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Compact explorer toolbar. Parent owns all state and filesystem actions.
ColumnLayout {
    id: root
    property string projectName: ""
    property bool projectOpen: false
    property string searchText: ""
    property string filterMode: "all"
    property int favoriteCount: 0
    signal searchChanged(string value)
    signal filterRequested(string value)

    spacing: 0
    onSearchTextChanged: {
        if (searchField.text !== searchText) searchField.text = searchText
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 51
        color: Theme.colors.surface
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 11
            spacing: 9
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 7
                color: "Transparent" /*Theme.colors.control*/
                border.width: 0
                border.color: Theme.colors.border
                Image {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    source: "qrc:/engine/assets/icons/folder_1.svg"
                    sourceSize: Qt.size(38, 38)
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: "PROJECT EXPLORER"
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.colors.text
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    Layout.fillWidth: true
                    text: root.projectOpen ? (root.projectName || "Workspace") : "No project opened"
                    font.pixelSize: 10
                    color: Theme.colors.muted
                    elide: Text.ElideMiddle
                }
            }
            Rectangle {
                Layout.preferredWidth: 7
                Layout.preferredHeight: 7
                radius: 4
                color: root.projectOpen ? "#20BD89" : Theme.colors.disabled
                ToolTip.visible: statusHover.containsMouse
                ToolTip.text: root.projectOpen ? "Project connected" : "Open a project to browse"
                MouseArea { id: statusHover; anchors.fill: parent; hoverEnabled: true }
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            height: 1
            width: parent.width
            color: Theme.colors.border
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        color: Theme.colors.panel
        Rectangle {
            anchors.fill: parent
            anchors.margins: 9
            radius: 4
            color: Theme.colors.surface
            border.width: searchField.activeFocus ? 1.5 : 1
            border.color: searchField.activeFocus ? Theme.colors.accent : Theme.colors.border
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 5
                spacing: 6
                Image {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    source: "qrc:/engine/assets/icons/search.svg"
                    sourceSize: Qt.size(28, 28)
                    opacity: 0.75
                }
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: root.searchText
                    enabled: root.projectOpen
                    placeholderText: "Search project files…"
                    font.pixelSize: 10
                    color: Theme.colors.text
                    placeholderTextColor: Theme.colors.muted
                    leftPadding: 0
                    rightPadding: 0
                    selectByMouse: true
                    background: Item {}
                    onTextEdited: root.searchChanged(text)
                    Keys.onEscapePressed: root.searchChanged("")
                }
                ProjectExplorerIconButton {
                    visible: root.searchText.length > 0
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    iconSize: 11
                    iconSource: "qrc:/engine/assets/icons/close.svg"
                    hint: "Clear search"
                    onTriggered: root.searchChanged("")
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        color: Theme.colors.panel
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 5
            ProjectExplorerFilterChip {
                Layout.fillWidth: true
                label: "All"
                selected: root.filterMode === "all"
                onTriggered: root.filterRequested("all")
            }
            ProjectExplorerFilterChip {
                Layout.fillWidth: true
                label: "Code"
                selected: root.filterMode === "code"
                onTriggered: root.filterRequested("code")
            }
            ProjectExplorerFilterChip {
                Layout.fillWidth: true
                label: "Media"
                selected: root.filterMode === "media"
                onTriggered: root.filterRequested("media")
            }
            ProjectExplorerFilterChip {
                Layout.fillWidth: true
                label: "Starred"
                count: root.favoriteCount
                selected: root.filterMode === "starred"
                onTriggered: root.filterRequested("starred")
            }
        }
    }
}
