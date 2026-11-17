import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Shared shell: a fixed header and action bar, scrollable component-specific properties.
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
    property bool canApply: false
    property bool canReload: true
    property bool showApply: true
    property bool showReload: true

    signal applyRequested()
    signal reloadRequested()

    color: Theme.colors.panel

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Theme.colors.surface
            border.color: Theme.colors.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 11
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 5
                    color: Theme.colors.control
                    Image {
                        anchors.centerIn: parent
                        width: 23
                        height: 23
                        source: "qrc:/engine/assets/icons/cube_blue.svg"
                        sourceSize: Qt.size(30, 30)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Label {
                        Layout.fillWidth: true
                        text: root.componentName
                        color: Theme.colors.text
                        font.bold: true
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.description
                        color: Theme.colors.muted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        spacing: 5
                        Rectangle {
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 6
                            radius: 3
                            color: root.installed ? "#42B883" : Theme.colors.muted
                        }
                        Label {
                            text: root.installed ? "INSTALLED" : "DRAFT / PREVIEW"
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.colors.muted
                        }
                        Label {
                            visible: root.dirty
                            text: "  •  MODIFIED"
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.colors.accent
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
                    controller: root.controller
                    componentManager: root.componentManager
                    componentId: root.componentId
                    hasUnsavedChanges: root.dirty
                }
                Item { Layout.preferredHeight: 8 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: footerColumn.implicitHeight + 14
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
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.showApply || root.showReload

                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        text: "Apply Changes"
                        font.pixelSize: 11
                        font.bold: true
                        visible: root.showApply
                        enabled: root.canApply
                        onClicked: root.applyRequested()
                        background: Rectangle {
                            radius: 3
                            color: parent.enabled ? Theme.colors.selection : Theme.colors.control
                            border.width: 1
                            border.color: parent.enabled ? Theme.colors.accent : Theme.colors.border
                        }
                    }
                    Button {
                        implicitWidth: 70
                        implicitHeight: 28
                        text: "Reload"
                        font.pixelSize: 11
                        visible: root.showReload
                        enabled: root.canReload
                        onClicked: root.reloadRequested()
                        background: Rectangle {
                            radius: 3
                            color: Theme.colors.control
                            border.width: 1
                            border.color: Theme.colors.border
                        }
                    }
                }
                Label {
                    Layout.fillWidth: true
                    visible: root.statusMessage.length > 0
                    text: root.statusMessage
                    color: root.statusIsError ? Theme.colors.error : Theme.colors.muted
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }
    }
}
