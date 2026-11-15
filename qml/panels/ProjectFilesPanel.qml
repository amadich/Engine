import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root

    property url projectFolder: ""
    property url selectedFile: ""
    property string projectName: ""

    signal fileSelected(url file)
    signal fileOpenRequested(url file)

    color: Theme.colors.panel
    visible: engineToolbar.showProjectFiles
    SplitView.fillWidth: !engineToolbar.showOutput

    Component {
        id: filesTree

        TreeView {
            id: tree

            clip: true
            reuseItems: false
            boundsBehavior: Flickable.StopAtBounds
            editTriggers: TableView.NoEditTriggers

            model: ProjectFilesModel {
                id: projectFiles
            }

            Component.onCompleted: {
                rootIndex = projectFiles.openFolder(root.projectFolder)
            }

            columnWidthProvider: function(column) {
                return column === 0 ? width : 0
            }

            ScrollBar.vertical: ScrollBar {}

            delegate: Rectangle {
                id: entry

                required property int row
                required property int depth
                required property bool expanded
                required property bool hasChildren
                required property string display

                readonly property var fileIndex: tree.index(row, 0)
                readonly property url itemUrl: projectFiles.fileUrl(fileIndex)
                readonly property bool folder: projectFiles.isFolder(fileIndex)
                readonly property bool imageFile: !folder
                    && /\.(png|jpe?g|webp|gif|svg|bmp)$/i.test(display)

                implicitWidth: tree.width
                implicitHeight: 26

                color: entry.itemUrl.toString() !== ""
                       && entry.itemUrl.toString() === root.selectedFile.toString()
                       ? Theme.colors.selection
                       : rowHover.hovered ? Theme.colors.hover : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6 + entry.depth * 14
                    anchors.rightMargin: 10
                    spacing: 6

                    Label {
                        Layout.preferredWidth: 11
                        text: entry.folder && entry.hasChildren
                              ? (entry.expanded ? "▾" : "▸") : ""
                        color: Theme.colors.text
                    }

                    Image {
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                        source: "qrc:/engine/assets/icons/"
                                + (entry.folder ? "folder.svg"
                                   : entry.imageFile ? "image.svg" : "file.svg")
                        sourceSize.width: 30
                        sourceSize.height: 30
                        fillMode: Image.PreserveAspectFit
                    }

                    Label {
                        Layout.fillWidth: true
                        text: entry.display
                        font.pixelSize: 13
                        color: Theme.colors.text
                        elide: Text.ElideRight
                    }
                }

                HoverHandler { id: rowHover }

                TapHandler {
                    onTapped: {
                        if (entry.folder) {
                            tree.toggleExpanded(entry.row)
                        } else if (entry.itemUrl.toString() !== "") {
                            root.fileSelected(entry.itemUrl)
                        }
                    }
                    onDoubleTapped: {
                        if (!entry.folder && entry.itemUrl.toString() !== "")
                            root.fileOpenRequested(entry.itemUrl)
                    }
                }
            }
        }
    }

    // Recreate the tree when switching projects to reset expansion state.
    onProjectFolderChanged: {
        treeLoader.sourceComponent = null

        if (projectFolder.toString() !== "") {
            treeLoader.sourceComponent = filesTree
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        Label {
            text: "PROJECT FILES"
            color: Theme.colors.accent
            font.bold: true
        }

        Label {
            Layout.fillWidth: true
            text: root.projectName || "Open a project"
            color: Theme.colors.muted
            elide: Text.ElideRight
        }

        Loader {
            id: treeLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}