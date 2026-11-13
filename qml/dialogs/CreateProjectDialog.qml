import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import JeridiEngine

Dialog {
    id: root

    required property ProjectController controller

    title: "Create Project"
    modal: true
    width: 460
    anchors.centerIn: parent

    FolderDialog {
        id: parentFolderDialog
        title: "Choose where to create your project"
    }

    contentItem: ColumnLayout {
        spacing: 16

        Label {
            text: "Project name"
        }

        TextField {
            id: projectNameInput
            Layout.fillWidth: true
            placeholderText: "my-website"
        }

        Label {
            text: "Parent folder"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Label {
                Layout.fillWidth: true
                text: parentFolderDialog.selectedFolder.toString() === ""
                      ? "Choose a folder"
                      : parentFolderDialog.selectedFolder.toString()
                elide: Text.ElideMiddle
            }

            Button {
                text: "Browse"
                onClicked: parentFolderDialog.open()
            }
        }

        Label {
            Layout.fillWidth: true
            text: "A new folder will be created inside the selected folder."
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Cancel"
                onClicked: root.close()
            }

            Button {
                text: "Create"
                enabled: !root.controller.busy
                         && projectNameInput.text.trim().length > 0
                         && parentFolderDialog.selectedFolder.toString() !== ""

                onClicked: {
                    const success = root.controller.createProject(
                        projectNameInput.text,
                        parentFolderDialog.selectedFolder
                    )

                    if (success) {
                        root.close()
                    }
                }
            }
        }
    }
}
