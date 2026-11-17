import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine
import "ProjectExplorerFormat.js" as Format

// Read-only selection inspector. Mutations are intentionally absent.
Rectangle {
    id: root
    property var details: ({})
    property bool starred: false
    readonly property bool hasSelection: !!(details && details.name)
    signal openRequested(var details)
    signal copyRequested(string text)
    signal favoriteRequested(string relativePath)
    signal closeRequested()

    radius: 6
    color: Theme.colors.panel
    border.width: 1
    border.color: Theme.colors.border

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 7
        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Image {
                Layout.preferredWidth: 17
                Layout.preferredHeight: 17
                source: "qrc:/engine/assets/icons/" + Format.iconFor(root.details.name, root.details.folder)
                sourceSize: Qt.size(34, 34)
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Label {
                    Layout.fillWidth: true
                    text: root.hasSelection ? root.details.name : "No file selected"
                    color: Theme.colors.text
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideMiddle
                }
                Label {
                    text: Format.fileKind(root.details)
                    color: Theme.colors.muted
                    font.pixelSize: 9
                }
            }
            ProjectExplorerIconButton {
                iconSource: "qrc:/engine/assets/icons/star.svg"
                iconSize: 14
                selected: root.starred
                hint: root.starred ? "Unstar" : "Star"
                actionEnabled: root.hasSelection
                onTriggered: root.favoriteRequested(String(root.details.relativePath || ""))
            }
            ProjectExplorerIconButton {
                iconSource: "qrc:/engine/assets/icons/close.svg"
                iconSize: 11
                hint: "Close details"
                onTriggered: root.closeRequested()
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            Label { text: "PATH"; font.pixelSize: 9; color: Theme.colors.muted }
            Label {
                Layout.fillWidth: true
                text: root.hasSelection ? String(root.details.relativePath || "") : "Select an item in the tree"
                font.pixelSize: 10
                color: Theme.colors.text
                elide: Text.ElideMiddle
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Label {
                Layout.fillWidth: true
                text: "Size  " + (root.hasSelection && !root.details.folder ? Format.formatBytes(root.details.size) : "—")
                font.pixelSize: 9
                color: Theme.colors.muted
            }
            Label {
                text: "Modified  " + (root.hasSelection ? String(root.details.modified || "—") : "—")
                font.pixelSize: 9
                color: Theme.colors.muted
            }
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            ProjectExplorerActionButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 29
                label: root.details.folder ? "Open folder" : "Open file"
                iconSource: "qrc:/engine/assets/icons/preview.svg"
                actionEnabled: root.hasSelection
                primary: true
                hint: root.details.folder ? "Open folder in system" : "Open in editor"
                onTriggered: root.openRequested(root.details)
            }
            ProjectExplorerActionButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 29
                label: "Copy path"
                iconSource: "qrc:/engine/assets/icons/copy.svg"
                actionEnabled: root.hasSelection
                hint: "Copy project-relative path"
                onTriggered: root.copyRequested(String(root.details.relativePath || ""))
            }
        }
    }
}
