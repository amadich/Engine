import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import JeridiEngine

ApplicationWindow {
    id: window

    width: 1400
    height: 900
    minimumWidth: 1000
    minimumHeight: 650

    visible: true
    title: "Jeridi Engine"
    color: "#0B1120"

    property string activeProjectName: ""
    property string activeProjectPath: ""

    function appendOutputLog(message) {
        const needsNewLine = outputArea.length > 0
                             && !outputArea.text.endsWith("\n")

        const prefix = needsNewLine ? "\n" : ""

        outputArea.insert(
            outputArea.length,
            prefix + message + "\n"
        )

        outputArea.cursorPosition = outputArea.length
    }

    ProjectController {
        id: projectController

        onLogMessage: function(message) {
            window.appendOutputLog(message)
        }

        onProjectCreated: function(projectName, projectPath) {
            window.activeProjectName = projectName
            window.activeProjectPath = projectPath
        }
    }

    ProcessRunner {
        id: processRunner

        onLogMessage: function(message) {
            window.appendOutputLog(message)
        }

        onOutputReceived: function(text) {
            outputArea.insert(outputArea.length, text)
            outputArea.cursorPosition = outputArea.length
        }
    }

    FolderDialog {
        id: parentFolderDialog
        title: "Choose where to create your project"
    }

    Dialog {
        id: createProjectDialog

        title: "Create Project"
        modal: true
        width: 460
        anchors.centerIn: parent

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

                    onClicked: createProjectDialog.close()
                }

                Button {
                    text: "Create"

                    enabled: projectNameInput.text.trim().length > 0
                             && parentFolderDialog.selectedFolder.toString() !== ""

                    onClicked: {
                        const success = projectController.createProject(
                            projectNameInput.text,
                            parentFolderDialog.selectedFolder
                        )

                        if (success) {
                            createProjectDialog.close()
                        }
                    }
                }
            }
        }
    }

    // شريط الأدوات أعلى النافذة
    header: ToolBar {
        background: Rectangle {
            color: "#111827"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 16

            Label {
                text: "JERIDI ENGINE"
                color: "#38BDF8"
                font.bold: true
                font.pixelSize: 16
            }

            ToolSeparator {}

            Label {
                text: window.activeProjectName === ""
                      ? "No project open"
                      : window.activeProjectName

                color: "#94A3B8"

                ToolTip.visible: projectNameHover.hovered
                ToolTip.text: window.activeProjectPath

                HoverHandler {
                    id: projectNameHover
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Create Project"
                enabled: !processRunner.running
                onClicked: createProjectDialog.open()
            }

            Button {
                text: processRunner.running ? "Running..." : "Check npm"
                enabled: !processRunner.running

                onClicked: {
                    processRunner.run("npm", ["--version"])
                }
            }

            Button {
                text: "Generate React"

                enabled: window.activeProjectPath !== ""
                         && !processRunner.running

                onClicked: {
                    processRunner.createReactProject(window.activeProjectPath)
                }
            }

            Button {
                text: "Run"
                enabled: false
            }
        }
    }

    // تقسيم رأسي بين مساحة العمل واللوحة السفلية
    SplitView {
        anchors.fill: parent
        orientation: Qt.Vertical

        // مساحة العمل بثلاثة أعمدة
        SplitView {
            orientation: Qt.Horizontal

            SplitView.fillHeight: true
            SplitView.minimumHeight: 300

            Rectangle {
                color: "#111827"

                SplitView.preferredWidth: 260
                SplitView.minimumWidth: 180

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Label {
                        text: "COMPONENT LIBRARY"
                        color: "#E2E8F0"
                        font.bold: true
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: "Search components..."
                        enabled: false
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Your components will appear here."
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            Rectangle {
                color: "#0B1120"

                SplitView.fillWidth: true
                SplitView.minimumWidth: 360

                Label {
                    anchors.centerIn: parent
                    text: "Project preview"
                    color: "#64748B"
                    font.pixelSize: 24
                }
            }

            Rectangle {
                color: "#111827"

                SplitView.preferredWidth: 280
                SplitView.minimumWidth: 200

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Label {
                        text: "INSPECTOR"
                        color: "#E2E8F0"
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Select a component to edit its properties."
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }

        // سجل العمليات، وسنربطه لاحقًا بـ C++
        Rectangle {
            color: "#0F172A"

            SplitView.preferredHeight: 200
            SplitView.minimumHeight: 100

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Label {
                    text: "OUTPUT"
                    color: "#38BDF8"
                    font.bold: true
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        id: outputArea
                        readOnly: true
                        selectByMouse: true
                        text: "Jeridi Engine ready."
                        color: "#CBD5E1"
                        font.family: "monospace"
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText

                        background: Rectangle {
                            color: "transparent"
                        }
                    }
                }
            }
        }
    }
}