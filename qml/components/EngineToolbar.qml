import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// The toolbar owns window chrome and the menu surface; commands are routed by Main.qml.
ToolBar {
    id: root
    required property ApplicationWindow hostWindow

    property string projectName: ""
    property string projectPath: ""
    property string projectFramework: ""
    property var recentProjects: []
    property bool hasEditor: false
    property bool hasDirty: false
    property bool busy: false
    property bool devServerActive: false
    property bool showProjectFiles: true
    property bool showOutput: true

    readonly property bool maximized: hostWindow.visibility === Window.Maximized

    signal menuCommandRequested(string command, var payload)
    signal runRequested()
    signal stopRequested()

    implicitHeight: 48
    padding: 0
    background: Rectangle { color: Theme.colors.control }

    function toggleMaximized() {
        if (root.maximized) hostWindow.showNormal()
        else hostWindow.showMaximized()
    }

    component ChromeButton: Button {
        id: button
        implicitWidth: 30
        implicitHeight: 28
        padding: 0
        hoverEnabled: true
        contentItem: Label {
            text: button.text
            font.pixelSize: 12
            color: button.enabled ? Theme.colors.text : Theme.colors.disabled
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 4
            color: button.down ? Theme.colors.selection
                 : button.hovered ? Theme.colors.hover : "transparent"
        }
    }

    contentItem: RowLayout {
        spacing: 4
        Item { Layout.preferredWidth: 8 }
        Image {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            source: "qrc:/engine/assets/logos/engine_logo_orange.svg"
            sourceSize: Qt.size(60, 60)
            fillMode: Image.PreserveAspectFit
        }

        EngineMenuBar {
            id: menuBar
            Layout.preferredHeight: 34
            busy: root.busy
            menuActive: root.visible
            devServerActive: root.devServerActive
            hasProject: root.projectPath !== ""
            hasEditor: root.hasEditor
            hasDirty: root.hasDirty
            showProjectFiles: root.showProjectFiles
            showOutput: root.showOutput
            projectFramework: root.projectFramework
            recentProjects: root.recentProjects
            onCommandRequested: function(command, payload) {
                root.menuCommandRequested(command, payload)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 20
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 7
                Label {
                    Layout.fillWidth: true
                    text: root.projectName || "No project open"
                    color: Theme.colors.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    visible: root.busy
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.colors.accent
                }
            }
            MouseArea {
                anchors.fill: parent
                onPressed: root.hostWindow.startSystemMove()
            }
        }

        ChromeButton {
            implicitWidth: 64
            text: root.devServerActive ? "■ Stop" : "▶ Run"
            enabled: root.devServerActive || (root.projectPath !== "" && !root.busy)
            onClicked: {
                if (root.devServerActive) root.stopRequested()
                else root.runRequested()
            }
            ToolTip.visible: hovered
            ToolTip.text: root.devServerActive ? "Stop process (Shift+F5)" : "Run project (Ctrl+F5)"
        }
        Item { Layout.preferredWidth: 6 }
        ChromeButton {
            text: "−"
            Accessible.name: "Minimize"
            onClicked: root.hostWindow.showMinimized()
        }
        ChromeButton {
            text: root.maximized ? "❐" : "□"
            Accessible.name: root.maximized ? "Restore" : "Maximize"
            onClicked: root.toggleMaximized()
        }
        ChromeButton {
            id: closeButton
            text: "×"
            Accessible.name: "Close window"
            onClicked: root.hostWindow.close()
            background: Rectangle {
                radius: 4
                color: closeButton.hovered ? Theme.colors.closeHover : "transparent"
            }
        }
        Item { Layout.preferredWidth: 8 }
    }
}
