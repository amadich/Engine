import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Project-scoped directory browser. Never performs file operations.
Rectangle {
    id: root

    required property ProjectController controller
    property string destinationPath: ""
    signal destinationEdited(string path)

    radius: 6
    color: Theme.colors.surface
    border.color: Theme.colors.border
    border.width: 1

    ProjectFolderModel {
        id: folders
        projectFolder: root.controller.projectFolderUrl
    }

    Timer {
        id: searchDelay
        interval: 200
        repeat: false
        onTriggered: folders.searchText = searchField.text
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 13
        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Image {
                source: "qrc:/engine/assets/icons/folder_1.svg"
                Layout.preferredWidth: 17
                Layout.preferredHeight: 17
                fillMode: Image.PreserveAspectFit
            }
            Label {
                text: "PROJECT EXPLORER"
                color: Theme.colors.text
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.5
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "DIRECTORIES"
                font.pixelSize: 10
                color: Theme.colors.muted
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }

        TextField {
            id: searchField
            Layout.fillWidth: true
            Layout.preferredHeight: 33
            placeholderText: "Filter directories…"
            selectByMouse: true
            font.pixelSize: 12
            color: Theme.colors.text
            placeholderTextColor: Theme.colors.muted
            leftPadding: 32
            rightPadding: 28
            background: Rectangle {
                radius: 4
                color: Theme.colors.panel
                border.color: searchField.activeFocus ? Theme.colors.accent : Theme.colors.border
            }
            Image {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 15
                height: 15
                source: "qrc:/engine/assets/icons/search.svg"
                opacity: 0.75
            }
            ToolButton {
                id: clearSearch
                visible: searchField.text.length > 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                onClicked: searchField.clear()
                background: Rectangle {
                    radius: 3
                    color: clearSearch.hovered ? Theme.colors.hover : "transparent"
                }
                contentItem: Label {
                    text: "×"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Theme.colors.muted
                    font.pixelSize: 17
                }
            }
            onTextChanged: searchDelay.restart()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Theme.colors.panel
            border.color: Theme.colors.border

            ListView {
                id: tree
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                spacing: 1
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                model: folders

                delegate: Rectangle {
                    id: entry
                    required property int index
                    required property string folderName
                    required property string folderPath
                    required property int folderLevel
                    required property bool folderExpanded
                    required property bool folderExpandable
                    required property bool searchResult

                    readonly property bool selected: root.destinationPath.trim() === folderPath
                    width: tree.width
                    height: 29
                    radius: 3
                    color: selected ? Theme.colors.selection
                          : rowMouse.containsMouse ? Theme.colors.hover : "transparent"

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.destinationEdited(entry.folderPath)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 5 + (entry.searchResult ? 0 : entry.folderLevel * 15)
                        anchors.rightMargin: 8
                        spacing: 6

                        ToolButton {
                            id: expander
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 24
                            enabled: entry.folderExpandable && !entry.searchResult
                            text: entry.folderExpandable && !entry.searchResult
                                  ? (entry.folderExpanded ? "▾" : "▸") : ""
                            font.pixelSize: 11
                            onClicked: folders.toggleExpanded(entry.folderPath)
                            background: Rectangle {
                                radius: 3
                                color: expander.hovered ? Theme.colors.control : "transparent"
                            }
                            contentItem: Label {
                                text: expander.text
                                color: Theme.colors.muted
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 11
                            }
                        }

                        Image {
                            Layout.preferredWidth: 15
                            Layout.preferredHeight: 15
                            source: "qrc:/engine/assets/icons/folder.svg"
                            fillMode: Image.PreserveAspectFit
                        }
                        Label {
                            Layout.fillWidth: true
                            text: entry.folderName
                            elide: Text.ElideMiddle
                            font.pixelSize: 12
                            color: entry.selected ? Theme.colors.text : Theme.colors.muted
                        }
                        Label {
                            visible: entry.selected
                            text: "✓"
                            color: Theme.colors.accent
                            font.pixelSize: 12
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: tree.count === 0
                    text: searchField.text ? "No matching folders" : "No project folders"
                    font.pixelSize: 12
                    color: Theme.colors.muted
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: folders.searchLimited
            text: "Search limit reached. Use a more specific folder name."
            wrapMode: Text.WordWrap
            font.pixelSize: 10
            color: Theme.dark ? "#E7B96B" : "#8A5C17"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Label {
                text: "DESTINATION PATH"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.colors.muted
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "PROJECT RELATIVE"
                font.pixelSize: 9
                color: Theme.colors.muted
            }
        }

        TextField {
            id: pathField
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            placeholderText: "src/components/new-folder"
            selectByMouse: true
            font.family: "Menlo"
            font.pixelSize: 11
            color: Theme.colors.text
            placeholderTextColor: Theme.colors.muted
            leftPadding: 10
            background: Rectangle {
                radius: 4
                color: Theme.colors.panel
                border.color: pathField.activeFocus ? Theme.colors.accent : Theme.colors.border
            }
            onTextChanged: {
                if (root.destinationPath !== text)
                    root.destinationEdited(text)
            }
        }

        Label {
            Layout.fillWidth: true
            text: "Select a folder, or type a new path. Use '.' for project root."
            font.pixelSize: 10
            color: Theme.colors.muted
            wrapMode: Text.WordWrap
        }
    }

    onDestinationPathChanged: {
        if (pathField && pathField.text !== destinationPath)
            pathField.text = destinationPath
    }
    Component.onCompleted: pathField.text = destinationPath
}
