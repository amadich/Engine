import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    property bool projectOpen: false
    property bool treeMode: true
    property bool showHidden: false
    property bool detailsVisible: false
    property string sectionLabel: "PROJECT TREE"
    property string countLabel: ""
    signal expandRequested()
    signal collapseRequested()
    signal refreshRequested()
    signal hiddenToggled()
    signal detailsToggled()

    implicitHeight: 28
    color: Theme.colors.surface
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.colors.border }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: 8
        spacing: 2
        Image {
            Layout.preferredWidth: 13
            Layout.preferredHeight: 13
            source: "qrc:/engine/assets/icons/folder.svg"
            sourceSize: Qt.size(26, 26)
        }
        Label {
            Layout.fillWidth: true
            text: root.sectionLabel
            color: Theme.colors.muted
            font.pixelSize: 9
            font.bold: true
            elide: Text.ElideRight
        }
        Label {
            text: root.countLabel
            color: Theme.colors.muted
            font.pixelSize: 9
        }
        ProjectExplorerIconButton {
            glyph: "⊞"
            hint: "Expand folders (two levels)"
            actionEnabled: root.projectOpen && root.treeMode
            disabledReason: "Available in tree view only"
            onTriggered: root.expandRequested()
        }
        ProjectExplorerIconButton {
            glyph: "⊟"
            hint: "Collapse all folders"
            actionEnabled: root.projectOpen && root.treeMode
            disabledReason: "Available in tree view only"
            onTriggered: root.collapseRequested()
        }
        ProjectExplorerIconButton {
            iconSource: "qrc:/engine/assets/icons/preview.svg"
            iconSize: 13
            hint: "Show or hide file details"
            selected: root.detailsVisible
            actionEnabled: root.projectOpen
            onTriggered: root.detailsToggled()
        }
        ProjectExplorerIconButton {
            glyph: "◉"
            hint: "Show or hide dotfiles"
            selected: root.showHidden
            actionEnabled: root.projectOpen
            onTriggered: root.hiddenToggled()
        }
        ProjectExplorerIconButton {
            iconSource: "qrc:/engine/assets/icons/redo.svg"
            iconSize: 13
            hint: "Refresh file tree"
            actionEnabled: root.projectOpen
            onTriggered: root.refreshRequested()
        }
    }
}
