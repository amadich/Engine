import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Reusable, searchable, collapsible Inspector group. Does not know package settings.
Rectangle {
    id: root
    default property alias sectionContent: body.data

    property string title: "Properties"
    property string description: ""
    property string iconSource: "qrc:/engine/assets/icons/cube.svg"
    property string tag: ""
    property bool expanded: true
    property bool filterAllowed: true
    property string filterQuery: ""
    property string filterKeywords: ""
    readonly property string normalizedQuery: filterQuery.trim().toLowerCase()
    readonly property bool sectionTitleMatches: normalizedQuery.length > 0
        && (title.toLowerCase().indexOf(normalizedQuery) >= 0
            || description.toLowerCase().indexOf(normalizedQuery) >= 0)
    readonly property bool matchesFilter: normalizedQuery.length === 0
        || sectionTitleMatches || filterKeywords.toLowerCase().indexOf(normalizedQuery) >= 0

    Layout.fillWidth: true
    implicitHeight: sectionLayout.implicitHeight
    visible: filterAllowed && matchesFilter
    color: "transparent"

    ColumnLayout {
        id: sectionLayout
        width: root.width
        spacing: 0

        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 29
            color: headerMouse.containsMouse ? Theme.colors.hover : Theme.colors.control

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 9
                spacing: 6

                Text {
                    text: root.expanded || root.normalizedQuery.length > 0 ? "▾" : "▸"
                    font.pixelSize: 11
                    color: Theme.colors.muted
                    Layout.preferredWidth: 9
                }
                Image {
                    source: root.iconSource
                    sourceSize: Qt.size(26, 26)
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    fillMode: Image.PreserveAspectFit
                }
                Label {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.colors.text
                    font.pixelSize: 10
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    visible: root.tag.length > 0
                    text: root.tag
                    color: Theme.colors.muted
                    font.pixelSize: 8
                }
                Label {
                    visible: root.description.length > 0
                    text: "ⓘ"
                    color: Theme.colors.muted
                    font.pixelSize: 11
                }
            }
            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
            ToolTip.visible: headerMouse.containsMouse
            ToolTip.text: root.description.length > 0 ? root.description
                          : (root.expanded ? "Collapse " : "Expand ") + root.title
            ToolTip.delay: 500
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.leftMargin: 9
            Layout.rightMargin: 9
            Layout.topMargin: visible ? 8 : 0
            Layout.bottomMargin: visible ? 10 : 0
            spacing: 6
            visible: root.expanded || root.normalizedQuery.length > 0
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.colors.border
            opacity: 0.65
        }
    }
}
