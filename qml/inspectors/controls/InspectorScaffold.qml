import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Shared Inspector shell. Only the shell controls scrolling, search, status and actions.
// Package inspectors own their actual settings and persistence behavior.
Rectangle {
    id: root
    default property alias inspectorContent: properties.data

    required property ProjectController controller
    required property ComponentManager componentManager
    required property string componentId

    property string componentName: "Component"
    property string description: "React component package"
    property string statusMessage: ""
    property bool statusIsError: false
    property bool installed: false
    property bool dirty: false
    property int changeCount: 0
    property bool canApply: false
    property bool canReload: true
    property bool showApply: true
    property bool showReload: true
    property bool previewVisible: true
    readonly property string filterText: filterInput.text.trim().toLowerCase()
    readonly property bool hasSearch: filterText.length > 0

    signal applyRequested()
    signal reloadRequested()

    color: Theme.colors.panel

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 63
            color: Theme.colors.surface
            border.width: 0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.colors.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 8
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 31
                    Layout.preferredHeight: 31
                    radius: 6
                    color: Theme.colors.control
                    border.width: 1
                    border.color: Theme.colors.border
                    Image {
                        anchors.centerIn: parent
                        width: 19
                        height: 19
                        source: "qrc:/engine/assets/icons/cube_blue.svg"
                        sourceSize: Qt.size(38, 38)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Label {
                            Layout.fillWidth: true
                            text: root.componentName
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.colors.text
                            elide: Text.ElideRight
                        }
                        Label {
                            text: "INSPECTOR"
                            font.pixelSize: 8
                            font.bold: true
                            color: Theme.colors.muted
                            visible: root.width >= 290
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.description
                        font.pixelSize: 9
                        color: Theme.colors.muted
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        spacing: 4
                        Rectangle {
                            Layout.preferredWidth: 5
                            Layout.preferredHeight: 5
                            radius: 3
                            color: root.installed ? "#24B47E" : Theme.colors.muted
                        }
                        Label {
                            text: root.installed ? "INSTALLED" : "PREVIEW"
                            font.pixelSize: 8
                            font.bold: true
                            color: Theme.colors.muted
                        }
                        Label {
                            visible: root.dirty
                            text: "  •  " + (root.changeCount > 0 ? root.changeCount + " CHANGED" : "MODIFIED")
                            font.pixelSize: 8
                            font.bold: true
                            color: Theme.colors.accent
                        }
                    }
                }

                InspectorActionButton {
                    Layout.preferredWidth: 29
                    Layout.preferredHeight: 27
                    buttonHeight: 27
                    text: ""
                    iconSource: "qrc:/engine/assets/icons/preview.svg"
                    iconSize: 15
                    variant: "subtle"
                    selected: root.previewVisible
                    hint: root.previewVisible ? "Hide component preview" : "Show component preview"
                    onClicked: root.previewVisible = !root.previewVisible
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: Theme.colors.panel
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                spacing: 6
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 25
                    radius: 4
                    color: Theme.colors.surface
                    border.width: 1
                    border.color: filterInput.activeFocus ? Theme.colors.accent : Theme.colors.border
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 6
                        spacing: 6
                        Image {
                            source: "qrc:/engine/assets/icons/search.svg"
                            Layout.preferredWidth: 13
                            Layout.preferredHeight: 13
                            sourceSize: Qt.size(26, 26)
                            opacity: 0.70
                        }
                        TextField {
                            id: filterInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            placeholderText: "Filter properties…"
                            font.pixelSize: 10
                            color: Theme.colors.text
                            placeholderTextColor: Theme.colors.muted
                            selectByMouse: true
                            leftPadding: 0
                            rightPadding: 0
                            background: Item {}
                        }
                        InspectorActionButton {
                            visible: filterInput.text.length > 0
                            Layout.preferredWidth: 19
                            Layout.preferredHeight: 19
                            buttonHeight: 19
                            text: ""
                            iconSource: "qrc:/engine/assets/icons/close.svg"
                            iconSize: 11
                            variant: "subtle"
                            hint: "Clear property filter"
                            onClicked: filterInput.clear()
                        }
                    }
                }
            }
        }

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: scroll.availableWidth
                spacing: 0

                ColumnLayout {
                    id: properties
                    Layout.fillWidth: true
                    spacing: 0
                }

                ComponentInstallationActions {
                    Layout.fillWidth: true
                    visible: !root.hasSearch || "project package install relocate move remove folder".indexOf(root.filterText) >= 0
                    controller: root.controller
                    componentManager: root.componentManager
                    componentId: root.componentId
                    hasUnsavedChanges: root.dirty
                }
                Item { Layout.preferredHeight: 6 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: footerColumn.implicitHeight + 15
            color: Theme.colors.surface
            border.width: 1
            border.color: Theme.colors.border
            visible: root.showApply || root.showReload || root.statusMessage.length > 0

            ColumnLayout {
                id: footerColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.showApply || root.showReload

                    InspectorActionButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 29
                        buttonHeight: 29
                        visible: root.showApply
                        text: "Apply Changes"
                        iconSource: "qrc:/engine/assets/icons/save.svg"
                        iconSize: 13
                        variant: "primary"
                        actionEnabled: root.canApply
                        hint: root.installed ? "Save changed settings to the installed package" : "Apply changes to the draft preview only"
                        disabledReason: !root.dirty ? "No pending changes"
                                        : "Finish editing valid fields, or wait for the project to be writable"
                        onClicked: root.applyRequested()
                    }
                    InspectorActionButton {
                        Layout.preferredWidth: 82
                        Layout.preferredHeight: 29
                        buttonHeight: 29
                        visible: root.showReload
                        text: "Reload"
                        iconSource: "qrc:/engine/assets/icons/undo.svg"
                        iconSize: 12
                        actionEnabled: root.canReload
                        hint: "Reload settings; discard un-applied edits"
                        disabledReason: "No configuration available to reload"
                        onClicked: root.reloadRequested()
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: root.statusMessage.length > 0
                    Image {
                        source: root.statusIsError ? "qrc:/engine/assets/icons/warning_2.svg"
                                                   : "qrc:/engine/assets/icons/file.svg"
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        sourceSize: Qt.size(24, 24)
                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.statusMessage
                        color: root.statusIsError ? Theme.colors.error : Theme.colors.muted
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
