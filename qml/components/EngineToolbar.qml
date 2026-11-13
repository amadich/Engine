import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolBar {
    id: root

    property string projectName: ""
    property string projectPath: ""
    property bool busy: false

    signal createProjectRequested()
    signal checkNpmRequested()
    signal generateReactRequested()

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
            text: "Create Project"
            enabled: !root.busy
            onClicked: root.createProjectRequested()
        }

        Button {
            text: root.busy ? "Running..." : "Check npm"
            enabled: !root.busy
            onClicked: root.checkNpmRequested()
        }

        Button {
            text: "Generate React"
            enabled: root.projectPath !== "" && !root.busy
            onClicked: root.generateReactRequested()
        }

        Button {
            text: "Run"
            enabled: false
        }
    }
}
