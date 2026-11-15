
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

ToolBar {
    id: root

    // ==================================================
    // Properties
    // ==================================================

    required property ApplicationWindow hostWindow

    property string projectName: ""
    property string projectPath: ""

    property bool busy: false
    property bool devServerActive: false

    property bool showProjectFiles: true
    property bool showOutput: true

    readonly property bool maximized:
        hostWindow.visibility === Window.Maximized

    // ==================================================
    // Signals
    // ==================================================

    signal createProjectRequested()
    signal openProjectRequested()
    signal checkNpmRequested()
    signal generateReactRequested()
    signal installDependenciesRequested()
    signal runRequested()
    signal stopRequested()
    signal preferencesRequested()

    // ==================================================
    // Toolbar configuration
    // ==================================================

    implicitHeight: 54
    padding: 0

    background: Rectangle {
        color: Theme.colors.control
    }

    function toggleMaximized() {
        if (root.maximized)
            hostWindow.showNormal()
        else
            hostWindow.showMaximized()
    }

    // ==================================================
    // Reusable components
    // ==================================================

    component HeaderButton: Button {
        id: button

        implicitHeight: 30
        padding: 7

        contentItem: Text {
            text: button.text
            font.pixelSize: 13

            color: button.enabled
                   ? Theme.colors.text
                   : Theme.colors.disabled

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 7

            color: button.down
                   ? Theme.colors.selection
                   : button.hovered
                     ? Theme.colors.hover
                     : Theme.colors.control
        }
    }

    component ThemeMenu: Menu {
        id: menu

        property int menuWidth: 200

        implicitWidth: menuWidth
        padding: 5

        popupType: Popup.Window

        background: Rectangle {
            implicitWidth: menu.menuWidth
            radius: 8
            color: Theme.colors.control
            border.width: 0
        }
    }

    component ThemeMenuItem: MenuItem {
        id: item

        implicitHeight: 34

        leftPadding: 12
        rightPadding: 12
        topPadding: 4
        bottomPadding: 4

        // Disable Qt's default check indicator
        indicator: Item {
            implicitWidth: 0
            implicitHeight: 0
        }

        contentItem: RowLayout {
            spacing: 12

            Text {
                Layout.fillWidth: true

                text: item.text
                font.pixelSize: 13
                elide: Text.ElideRight

                color: item.enabled
                       ? Theme.colors.text
                       : Theme.colors.disabled

                verticalAlignment: Text.AlignVCenter
            }

            Text {
                Layout.preferredWidth: 18

                visible: item.checkable
                text: item.checked ? "✓" : ""

                font.pixelSize: 14
                color: Theme.colors.text

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        background: Rectangle {
            radius: 5

            color: !item.enabled
                   ? "transparent"
                   : item.down
                     ? Theme.colors.selection
                     : item.highlighted || item.hovered
                       ? Theme.colors.hover
                       : "transparent"
        }
    }

    // ==================================================
    // Clipboard helper
    // ==================================================

    TextEdit {
        id: clipboardText

        visible: false
        text: root.projectPath
    }

    // ==================================================
    // About dialog
    // ==================================================

    Dialog {
        id: aboutDialog

        parent: Overlay.overlay
        anchors.centerIn: parent

        width: 420
        title: "About Jeridi Engine"

        modal: true
        padding: 16

        popupType: Popup.Window
        standardButtons: Dialog.Ok

        palette.windowText: Theme.colors.text
        palette.buttonText: Theme.colors.text

        background: Rectangle {
            color: Theme.colors.control
            radius: 10
            border.width: 0
        }

        contentItem: Label {
            text: "Jeridi Engine\nProject creation, live preview and component library."

            color: Theme.colors.text
            wrapMode: Text.WordWrap
        }
    }

    // ==================================================
    // Toolbar layout
    // ==================================================

    contentItem: RowLayout {
        spacing: 6

        Item {
            Layout.preferredWidth: 10
        }

        // Logo
        Image {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 32

            source: "qrc:/engine/assets/logos/engine_logo_orange.svg"

            sourceSize.width: 76
            sourceSize.height: 64

            fillMode: Image.PreserveAspectFit
        }

        // ==============================================
        // Menu bar
        // ==============================================

        MenuBar {
            id: mainMenu

            background: Item {}

            delegate: MenuBarItem {
                id: tab

                padding: 7

                contentItem: Text {
                    text: tab.text
                    font.pixelSize: 13
                    color: Theme.colors.text

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 6

                    color: tab.highlighted || tab.hovered
                           ? Theme.colors.hover
                           : "transparent"
                }
            }

            // ------------------------------------------
            // File
            // ------------------------------------------

            ThemeMenu {
                title: "File"

                ThemeMenuItem {
                    text: "New Project…"
                    enabled: !root.busy

                    onTriggered: root.createProjectRequested()
                }

                ThemeMenuItem {
                    text: "Open Project…"
                    enabled: !root.busy

                    onTriggered: root.openProjectRequested()
                }
            }

            // ------------------------------------------
            // Edit
            // ------------------------------------------

            ThemeMenu {
                title: "Edit"

                ThemeMenuItem {
                    text: "Copy Project Path"
                    enabled: root.projectPath !== ""

                    onTriggered: {
                        clipboardText.selectAll()
                        clipboardText.copy()
                        clipboardText.deselect()
                    }
                }

                MenuSeparator {}

                ThemeMenuItem {
                    text: "Preferences…"

                    onTriggered: root.preferencesRequested()
                }
            }

            // ------------------------------------------
            // View
            // ------------------------------------------

            ThemeMenu {
                title: "View"

                ThemeMenuItem {
                    text: "Project Files"
                    checkable: true
                    checked: root.showProjectFiles

                    onTriggered: {
                        root.showProjectFiles =
                                !root.showProjectFiles
                    }
                }

                ThemeMenuItem {
                    text: "Output"
                    checkable: true
                    checked: root.showOutput

                    onTriggered: {
                        root.showOutput = !root.showOutput
                    }
                }
            }

            // ------------------------------------------
            // Tools
            // ------------------------------------------

            ThemeMenu {
                title: "Tools"
                menuWidth: 220

                ThemeMenuItem {
                    text: "Check npm"
                    enabled: !root.busy

                    onTriggered: root.checkNpmRequested()
                }

                ThemeMenuItem {
                    text: "Generate React"

                    enabled: root.projectPath !== ""
                             && !root.busy

                    onTriggered: root.generateReactRequested()
                }

                ThemeMenuItem {
                    text: "Install Dependencies"

                    enabled: root.projectPath !== ""
                             && !root.busy

                    onTriggered: root.installDependenciesRequested()
                }
            }

            // ------------------------------------------
            // Window
            // ------------------------------------------

            ThemeMenu {
                title: "Window"

                ThemeMenuItem {
                    text: "Minimize"

                    onTriggered: root.hostWindow.showMinimized()
                }

                ThemeMenuItem {
                    text: root.maximized
                          ? "Restore"
                          : "Maximize"

                    onTriggered: root.toggleMaximized()
                }

                MenuSeparator {}

                ThemeMenuItem {
                    text: "Close"

                    onTriggered: root.hostWindow.close()
                }
            }

            // ------------------------------------------
            // Help
            // ------------------------------------------

            ThemeMenu {
                title: "Help"

                ThemeMenuItem {
                    text: "About Jeridi Engine"

                    onTriggered: aboutDialog.open()
                }
            }
        }

        // ==============================================
        // Project title / Drag area
        // ==============================================

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 36

            Label {
                anchors.fill: parent
                anchors.leftMargin: 10

                text: root.projectName || "No project open"

                color: Theme.colors.disabled
                elide: Text.ElideRight

                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent

                onPressed: root.hostWindow.startSystemMove()
            }
        }

        // ==============================================
        // Run / Stop
        // ==============================================

        HeaderButton {
            Layout.preferredWidth: 64

            text: root.devServerActive ? "Stop" : "Run"

            enabled: root.devServerActive ||
                     (root.projectPath !== "" && !root.busy)

            onClicked: {
                if (root.devServerActive)
                    root.stopRequested()
                else
                    root.runRequested()
            }
        }

        Item {
            Layout.preferredWidth: 6
        }

        // ==============================================
        // Window controls
        // ==============================================

        HeaderButton {
            Layout.preferredWidth: 30
            text: "−"

            Accessible.name: "Minimize"

            onClicked: root.hostWindow.showMinimized()
        }

        HeaderButton {
            Layout.preferredWidth: 30

            text: root.maximized ? "❐" : "□"

            Accessible.name:
                root.maximized ? "Restore" : "Maximize"

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

                color: closeButton.hovered
                       ? Theme.colors.closeHover
                       : Theme.colors.control
            }
        }

        Item {
            Layout.preferredWidth: 10
        }
    }
}
