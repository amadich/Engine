import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel

Rectangle {
    id: root

    property url projectFolder: ""
    property url currentFolder: projectFolder
    property url selectedFile: ""

    signal fileSelected(url file)

    onProjectFolderChanged: currentFolder = projectFolder

    color: "#111827"

    FolderListModel {
        id: files

        folder: root.currentFolder
        rootFolder: root.projectFolder
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Label {
                Layout.fillWidth: true
                text: "PROJECT FILES"
                color: "#38BDF8"
                font.bold: true
            }

            Button {
                text: "Up"
                enabled: root.currentFolder.toString()
                         !== root.projectFolder.toString()
                         && files.parentFolder.toString() !== ""
                onClicked: root.currentFolder = files.parentFolder
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.currentFolder.toString() || "Open a project"
            color: "#94A3B8"
            elide: Text.ElideMiddle
        }

        ListView {
            id: fileList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            model: root.projectFolder.toString() === "" ? null : files
            ScrollBar.vertical: ScrollBar {}

            delegate: ItemDelegate {
                required property string fileName
                required property bool fileIsDir
                required property url fileUrl

                width: fileList.width
                visible: !(fileIsDir && fileName === "node_modules")
                height: visible ? implicitHeight : 0

                text: fileIsDir ? fileName + "/" : fileName
                highlighted: fileUrl.toString() === root.selectedFile.toString()

                onClicked: {
                    if (fileIsDir) {
                        root.currentFolder = fileUrl
                    } else {
                        root.fileSelected(fileUrl)
                    }
                }
            }
        }
    }
}