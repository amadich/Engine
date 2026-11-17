import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root

    signal componentSelected(string componentId)

    color: Theme.colors.surface

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Label {
            text: "COMPONENT LIBRARY"
            color: Theme.colors.text
            font.bold: true
        }

        TreeView {
            id: libraryTree

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            columnWidthProvider: function(column) {
                return libraryTree.width
            }

            ScrollBar.vertical: ScrollBar {}

            model: ComponentRegistry

            delegate: Rectangle {
                id: entry

                required property int row
                required property int depth
                required property bool expanded
                required property bool hasChildren
                required property string display
                required property string componentId
                required property string activation

                readonly property bool canActivate: hasChildren || componentId !== ""

                implicitHeight: 30
                implicitWidth: libraryTree.width

                color: rowTap.pressed ? Theme.colors.selection
                     : rowHover.hovered && entry.canActivate ? Theme.colors.hover
                     : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6 + entry.depth * 16
                    anchors.rightMargin: 6
                    spacing: 6

                    Label {
                        Layout.preferredWidth: 12
                        text: entry.hasChildren ? (entry.expanded ? "▾" : "▸") : ""
                        color: "#94A3B8"
                    }

                    Image {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16

                        source: "qrc:/engine/assets/icons/cube_blue.svg"
                        sourceSize.width: 24
                        sourceSize.height: 24
                        fillMode: Image.PreserveAspectFit
                        opacity: entry.canActivate ? 1 : 0.45
                    }

                    Label {
                        Layout.fillWidth: true
                        text: entry.display
                        elide: Text.ElideRight
                        font.bold: entry.hasChildren
                        color: entry.canActivate ? Theme.colors.text : Theme.colors.disabled
                    }
                }

                HoverHandler {
                    id: rowHover
                }

                TapHandler {
                    id: rowTap
                    enabled: entry.canActivate

                    onTapped: {
                        if (entry.hasChildren) {
                            libraryTree.toggleExpanded(entry.row)
                        } else if (entry.componentId !== "") {
                            root.componentSelected(entry.componentId)
                        }
                    }
                }
            }
        }
    }
}
