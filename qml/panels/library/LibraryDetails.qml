import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Selected package summary. Never writes files. Install requests go to the existing dialog.
Rectangle {
    id: root

    property string selectedId: ""
    property var definition: ({})
    property bool installed: false
    property bool favorite: false
    property bool projectOpen: false
    property bool canInstall: false
    property bool hasInstallDialog: false
    property string installedDirectory: ""

    signal inspectRequested(string componentId)
    signal installRequested(string componentId)
    signal favoriteToggled(string componentId)

    implicitHeight: selectedId.length > 0 ? 150 : 68
    color: Theme.colors.surface
    border.width: 0

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.colors.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Image {
                Layout.preferredWidth: 15
                Layout.preferredHeight: 15
                source: "qrc:/engine/assets/icons/preview.svg"
                sourceSize: Qt.size(30, 30)
            }
            Label {
                Layout.fillWidth: true
                text: root.selectedId.length > 0 ? "PACKAGE DETAILS" : "SELECTION"
                font.pixelSize: 9
                font.bold: true
                color: Theme.colors.accent
            }
            Label {
                text: root.selectedId.length > 0 ? "READ ONLY" : "IDLE"
                font.pixelSize: 8
                color: Theme.colors.muted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: root.selectedId.length === 0
            Label {
                Layout.fillWidth: true
                text: "Select a component to inspect"
                font.pixelSize: 10
                color: Theme.colors.muted
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7
            visible: root.selectedId.length > 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                Image {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    source: "qrc:/engine/assets/icons/cube_blue.svg"
                    sourceSize: Qt.size(48, 48)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 1
                    Label {
                        Layout.fillWidth: true
                        text: String(root.definition.name || root.selectedId)
                        color: Theme.colors.text
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: (root.definition.category || []).join(" / ")
                        color: Theme.colors.muted
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }
                LibraryIconButton {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    iconSource: "qrc:/engine/assets/icons/star.svg"
                    selected: root.favorite
                    hint: root.favorite ? "Remove favorite" : "Favorite component"
                    onTriggered: root.favoriteToggled(root.selectedId)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                Rectangle {
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: root.installed ? "#32C48D" : Theme.colors.disabled
                }
                Label {
                    Layout.fillWidth: true
                    text: !root.projectOpen ? "Open a project to see installation status"
                          : root.installed ? "Installed · " + root.installedDirectory
                          : "Not installed in this project"
                    color: Theme.colors.muted
                    font.pixelSize: 9
                    elide: Text.ElideMiddle
                }
                Label {
                    text: String((root.definition.files || []).length) + " FILES"
                    color: Theme.colors.muted
                    font.pixelSize: 8
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Rectangle {
                    id: inspectButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: 4
                    color: inspectMouse.containsMouse ? Theme.colors.hover : Theme.colors.control
                    border.width: 1
                    border.color: inspectMouse.containsMouse ? Theme.colors.accent : Theme.colors.border
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Image {
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            source: "qrc:/engine/assets/icons/preview.svg"
                            sourceSize: Qt.size(24, 24)
                        }
                        Label {
                            text: "Inspect"
                            color: Theme.colors.text
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                    MouseArea {
                        id: inspectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.inspectRequested(root.selectedId)
                    }
                }
                Rectangle {
                    id: installButton
                    readonly property bool allowed: !root.installed && root.canInstall
                                                    && root.hasInstallDialog
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: 4
                    color: !allowed ? Theme.colors.surface
                           : installMouse.containsMouse ? Theme.colors.hover : Theme.colors.selection
                    border.width: 1
                    border.color: allowed && installMouse.containsMouse
                                  ? Theme.colors.accent : Theme.colors.border
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Image {
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            source: "qrc:/engine/assets/icons/cube_blue.svg"
                            sourceSize: Qt.size(24, 24)
                            opacity: installButton.allowed ? 1 : 0.35
                        }
                        Label {
                            text: root.installed ? "Installed" : "Install…"
                            font.pixelSize: 10
                            color: installButton.allowed ? Theme.colors.text : Theme.colors.disabled
                        }
                    }
                    MouseArea {
                        id: installMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: installButton.allowed ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: { if (installButton.allowed) root.installRequested(root.selectedId) }
                    }
                    ToolTip.visible: installMouse.containsMouse
                    ToolTip.delay: 450
                    ToolTip.text: root.installed ? "Already installed. Use Inspector to relocate."
                                  : !root.projectOpen ? "Open a project first."
                                  : !root.hasInstallDialog ? "Install dialog is not connected."
                                  : !root.canInstall ? "Wait until the current operation finishes."
                                  : "Open the installation dialog; no files are written yet."
                }
            }
        }
    }
}
