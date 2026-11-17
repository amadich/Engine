import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Compact, collapsible property group. Children go into body, not the header.
Rectangle {
    id: root
    default property alias sectionContent: body.data

    property string title: "Properties"
    property string description: ""
    property string iconSource: "qrc:/engine/assets/icons/cube.svg"
    property string tag: ""
    property bool expanded: true

    implicitHeight: sectionLayout.implicitHeight
    color: "transparent"

    ColumnLayout {
        id: sectionLayout
        width: root.width
        spacing: 0

        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: headerMouse.containsMouse ? Theme.colors.hover : Theme.colors.control

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 9
                spacing: 7

                Text {
                    text: root.expanded ? "▾" : "▸"
                    font.pixelSize: 12
                    color: Theme.colors.muted
                    Layout.preferredWidth: 9
                }
                Image {
                    source: root.iconSource
                    sourceSize: Qt.size(22, 22)
                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 15
                    fillMode: Image.PreserveAspectFit
                }
                Label {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.colors.text
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    visible: root.tag !== ""
                    text: root.tag
                    color: Theme.colors.muted
                    font.pixelSize: 9
                }
                Label {
                    visible: root.description !== ""
                    text: "?"
                    font.pixelSize: 11
                    color: Theme.colors.muted
                }
            }

            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
            ToolTip.visible: headerMouse.containsMouse && root.description.length > 0
            ToolTip.text: root.description
            ToolTip.delay: 550
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: root.expanded ? 9 : 0
            Layout.bottomMargin: root.expanded ? 11 : 0
            spacing: 7
            visible: root.expanded
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.colors.border
            opacity: 0.65
        }
    }
}
