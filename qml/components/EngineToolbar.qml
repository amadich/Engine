import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolBar {
    id: root

    required property ApplicationWindow hostWindow

    property string projectName: ""
    property string projectPath: ""
    property bool busy: false
    property bool devServerActive: false

    property bool showProjectFiles: true
    property bool showOutput: true

    signal createProjectRequested()
    signal openProjectRequested()
    signal checkNpmRequested()
    signal generateReactRequested()
    signal installDependenciesRequested()
    signal runRequested()
    signal stopRequested()

    implicitHeight: 54
    padding: 0

    readonly property bool maximized:
        hostWindow.visibility === Window.Maximized

    function toggleMaximized() {
        if (maximized)
            hostWindow.showNormal()
        else
            hostWindow.showMaximized()
    }

    background: Item {}

    TextEdit {
        id: clipboardText
        visible: false
        text: root.projectPath
    }

    Dialog {
        id: aboutDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        title: "About Jeridi Engine"
        modal: true
        standardButtons: Dialog.Ok

        Label {
            text: "Jeridi Engine\nProject creation, live preview and component library."
            padding: 16
        }
    }

    component HeaderButton: Button {
        id: control

        implicitHeight: 30
        padding: 7
        font.pixelSize: 13

        contentItem: Text {
            text: control.text
            color: control.enabled ? "#E2E8F0" : "#64748B"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 7
            color: control.down ? "#334155"
                   : control.hovered ? "#243449"
                   : "#1A2536"
        }
    }

    contentItem: RowLayout {
        spacing: 6

        Item { Layout.preferredWidth: 10 }

        Image {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 32
            source: "qrc:/engine/assets/logos/engine_logo_blue.svg"
            sourceSize.width: 76
            sourceSize.height: 64
            fillMode: Image.PreserveAspectFit
        }

        MenuBar {
            id: mainMenu

            background: Item {}

            delegate: MenuBarItem {
                id: tab
                padding: 7

                contentItem: Text {
                    text: tab.text
                    color: "#CBD5E1"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 6
                    color: tab.highlighted || tab.hovered
                           ? "#243449" : "transparent"
                }
            }

            Menu {
                title: "File"

                MenuItem {
                    text: "New Project…"
                    enabled: !root.busy
                    onTriggered: root.createProjectRequested()
                }

                MenuItem {
                    text: "Open Project…"
                    enabled: !root.busy
                    onTriggered: root.openProjectRequested()
                }
            }

            Menu {
                title: "Edit"

                MenuItem {
                    text: "Copy Project Path"
                    enabled: root.projectPath !== ""

                    onTriggered: {
                        clipboardText.selectAll()
                        clipboardText.copy()
                        clipboardText.deselect()
                    }
                }
            }

            Menu {
                title: "View"

                MenuItem {
                    text: "Project Files"
                    checkable: true
                    checked: root.showProjectFiles
                    onTriggered: root.showProjectFiles = !root.showProjectFiles
                }

                MenuItem {
                    text: "Output"
                    checkable: true
                    checked: root.showOutput
                    onTriggered: root.showOutput = !root.showOutput
                }
            }

            Menu {
                title: "Tools"

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

            Menu {
                title: "Window"

                MenuItem {
                    text: "Minimize"
                    onTriggered: root.hostWindow.showMinimized()
                }

                MenuItem {
                    text: root.maximized ? "Restore" : "Maximize"
                    onTriggered: root.toggleMaximized()
                }

                MenuSeparator {}

                MenuItem {
                    text: "Close"
                    onTriggered: root.hostWindow.close()
                }
            }

            Menu {
                title: "Help"

                MenuItem {
                    text: "About Jeridi Engine"
                    onTriggered: aboutDialog.open()
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 36

            Label {
                anchors.fill: parent
                anchors.leftMargin: 10
                verticalAlignment: Text.AlignVCenter
                text: root.projectName || "No project open"
                color: "#94A3B8"
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                onPressed: root.hostWindow.startSystemMove()
            }
        }

        HeaderButton {
            Layout.preferredWidth: 64
            text: root.devServerActive ? "Stop" : "Run"
            enabled: root.devServerActive
                     || (root.projectPath !== "" && !root.busy)

            onClicked: {
                if (root.devServerActive)
                    root.stopRequested()
                else
                    root.runRequested()
            }
        }

        Item { Layout.preferredWidth: 6 }

        HeaderButton {
            Layout.preferredWidth: 30
            text: "−"
            Accessible.name: "Minimize"
            onClicked: root.hostWindow.showMinimized()
        }

        HeaderButton {
            Layout.preferredWidth: 30
            text: root.maximized ? "❐" : "□"
            Accessible.name: root.maximized ? "Restore" : "Maximize"
            onClicked: root.toggleMaximized()
        }

        HeaderButton {
            id: closeButton
            Layout.preferredWidth: 30
            text: "×"
            Accessible.name: "Close window"
            onClicked: root.hostWindow.close()

            background: Rectangle {
                radius: 7
                color: closeButton.hovered ? "#B8424D" : "#1A2536"
            }
        }

        Item { Layout.preferredWidth: 10 }
    }
}