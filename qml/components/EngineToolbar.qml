import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolBar {
    id: root

    property string projectName: ""
    property string projectPath: ""
    property bool busy: false
    property bool devServerActive: false

    signal createProjectRequested()
    signal checkNpmRequested()
    signal generateReactRequested()

    signal openProjectRequested()
    signal installDependenciesRequested()

    signal runRequested()
    signal stopRequested()

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
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.projectName === "" ? "No project open" : root.projectName
            color: "#94A3B8"
            elide: Text.ElideRight

            ToolTip.visible: projectNameHover.hovered && root.projectPath !== ""
            ToolTip.text: root.projectPath

            HoverHandler {
                id: projectNameHover
            }
        }

        Button {
            text: "New Project…"
            enabled: !root.busy
            onClicked: root.createProjectRequested()
        }

        Button {
            text: "Open…"
            enabled: !root.busy
            onClicked: root.openProjectRequested()
        }

        Button {
            id: toolsButton

            text: "Tools ▾"
            onClicked: toolsMenu.open()

            Menu {
                id: toolsMenu
                y: toolsButton.height

                MenuItem {
                    text: "Check npm"
                    enabled: !root.busy
                    onTriggered: root.checkNpmRequested()
                }

                MenuItem {
                    text: "Generate React"
                    enabled: root.projectPath !== "" && !root.busy
                    onTriggered: root.generateReactRequested()
                }

                MenuItem {
                    text: "Install Dependencies"
                    enabled: root.projectPath !== "" && !root.busy
                    onTriggered: root.installDependenciesRequested()
                }
            }
        }

        Button {
            text: root.devServerActive ? "Stop" : "Run"

            enabled: root.devServerActive
                     || (root.projectPath !== "" && !root.busy)

            onClicked: {
                if (root.devServerActive) {
                    root.stopRequested()
                } else {
                    root.runRequested()
                }
            }
        }
    }
}
