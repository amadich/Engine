import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import JeridiEngine

Dialog {
    id: root

    required property ProjectController controller

    readonly property bool usesReactVite:
        frontendBox.currentValue === "react-vite"
    readonly property bool emptyProject:
        frontendBox.currentValue === "none"

    readonly property bool supportedStack:
        (usesReactVite || emptyProject)
        && backendBox.currentValue === "none"
        && architectureBox.currentValue === "default"

    title: "New Project"
    modal: true
    anchors.centerIn: parent
    width: Math.min(640, parent.width - 32)
    padding: 20

    onOpened: projectNameInput.forceActiveFocus()

    FolderDialog {
        id: folderPicker
        title: "Choose a parent folder"
    }

    contentItem: ColumnLayout {
        spacing: 14

        Label {
            text: "PROJECT"
            font.bold: true
        }

        TextField {
            id: projectNameInput
            Layout.fillWidth: true
            placeholderText: "Project name, e.g. my-website"
            Accessible.name: "Project name"
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                Layout.fillWidth: true
                text: folderPicker.selectedFolder.toString()
                      || "Choose where to create the project"
                elide: Text.ElideMiddle
            }

            Button {
                text: "Browse…"
                onClicked: folderPicker.open()
            }
        }

        Label {
            text: "STACK"
            font.bold: true
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 8

            Label { text: "Frontend" }

            ComboBox {
                id: frontendBox
                Layout.fillWidth: true
                Accessible.name: "Frontend"
                textRole: "label"
                valueRole: "key"

                model: [
                    { label: "React + Vite + TypeScript", key: "react-vite" },
                    { label: "Next.js", key: "next" },
                    { label: "Angular", key: "angular" },
                    { label: "None", key: "none" }
                ]
            }

            Label { text: "Backend" }

            ComboBox {
                id: backendBox
                Layout.fillWidth: true
                Accessible.name: "Backend"
                textRole: "label"
                valueRole: "key"

                model: [
                    { label: "None", key: "none" },
                    { label: "Node.js + Express", key: "express" },
                    { label: "Apollo Server + Express", key: "apollo-express" },
                    { label: "NestJS", key: "nestjs" },
                    { label: "Spring Boot", key: "spring-boot" }
                ]
            }
        }

        Label {
            text: "ARCHITECTURE"
            font.bold: true
        }

        ComboBox {
            id: architectureBox
            Layout.fillWidth: true
            Accessible.name: "Architecture"
            textRole: "label"
            valueRole: "key"

            model: [
                { label: "Default project layout", key: "default" },
                { label: "Feature-based", key: "feature-based" },
                { label: "Layered", key: "layered" },
                { label: "Full-stack workspace", key: "full-stack" }
            ]
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap

            text: {
                if (!root.supportedStack) {
                    return "A generator is not available for this combination yet."
                }

                if (root.emptyProject) {
                    return "Creates an empty project folder."
                }

                return "Creates a Vite project with src/, public/, and package.json."
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            Button {
                text: "Cancel"
                onClicked: root.close()
            }

            Button {
                text: "Create"
                enabled: root.supportedStack
                         && !root.controller.busy
                         && projectNameInput.text.trim().length > 0
                         && folderPicker.selectedFolder.toString() !== ""

                onClicked: {
                    if (!root.controller.createProject(
                            projectNameInput.text,
                            folderPicker.selectedFolder)) {
                        return
                    }

                    if (root.usesReactVite) {
                        root.controller.generateReact()
                    }

                    root.close()
                }
            }
        }
    }
}