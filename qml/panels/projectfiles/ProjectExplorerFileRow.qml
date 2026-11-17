import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine
import "ProjectExplorerFormat.js" as Format

// One file/folder row for both the native tree and flat search/favorites lists.
Rectangle {
    id: root
    property var details: ({})
    property int indentLevel: 0
    property bool nodeExpanded: false
    property bool nodeHasChildren: false
    property bool nodeSelected: false
    property bool nodeStarred: false
    property bool searchMode: false

    signal activated(var details)
    signal openRequested(var details)
    signal favoriteRequested(string relativePath)
    signal copyRequested(string text)
    signal externalRequested(url url)

    readonly property bool isFolder: !!(details && details.folder)
    readonly property string relative: String(details && details.relativePath || "")
    readonly property string fileName: String(details && details.name || "")

    implicitHeight: searchMode ? 38 : 28
    color: nodeSelected ? Theme.colors.selection
           : rowMouse.containsMouse ? Theme.colors.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 80 } }
    Rectangle {
        width: 2
        height: parent.height
        color: Theme.colors.accent
        visible: root.nodeSelected
    }

    RowLayout {
        z: 1
        anchors.fill: parent
        anchors.leftMargin: root.searchMode ? 9 : (7 + root.indentLevel * 14)
        anchors.rightMargin: 8
        spacing: 6
        Text {
            Layout.preferredWidth: 11
            text: root.searchMode || !root.isFolder || !root.nodeHasChildren
                  ? "" : root.nodeExpanded ? "▾" : "▸"
            color: Theme.colors.muted
            font.pixelSize: 10
        }
        Image {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            source: "qrc:/engine/assets/icons/" + Format.iconFor(root.fileName, root.isFolder)
            sourceSize: Qt.size(32, 32)
            fillMode: Image.PreserveAspectFit
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label {
                Layout.fillWidth: true
                text: root.fileName
                font.pixelSize: 11
                color: Theme.colors.text
                elide: Text.ElideRight
            }
            Label {
                visible: root.searchMode
                Layout.fillWidth: true
                text: root.relative
                font.pixelSize: 9
                color: Theme.colors.muted
                elide: Text.ElideMiddle
            }
        }
        ProjectExplorerIconButton {
            id: starButton
            visible: true
            opacity: root.nodeStarred || rowMouse.containsMouse ? 1 : 0.4
            Layout.preferredWidth: 23
            Layout.preferredHeight: 23
            iconSource: "qrc:/engine/assets/icons/star.svg"
            iconSize: 14
            selected: root.nodeStarred
            hint: root.nodeStarred ? "Remove from starred" : "Star this file"
            onTriggered: root.favoriteRequested(root.relative)
        }
    }

    MouseArea {
        id: rowMouse
        z: 0
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.activated(root.details)
                contextMenu.x = mouse.x
                contextMenu.y = mouse.y
                contextMenu.open()
            } else {
                root.activated(root.details)
            }
        }
        onDoubleClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton && (!root.isFolder || root.searchMode))
                root.openRequested(root.details)
        }
    }

    Menu {
        id: contextMenu
        MenuItem {
            text: root.isFolder ? "Open folder in system" : "Open file in editor"
            onTriggered: root.openRequested(root.details)
        }
        MenuItem {
            text: "Copy relative path"
            enabled: root.relative.length > 0
            onTriggered: root.copyRequested(root.relative)
        }
        MenuItem {
            text: "Copy absolute path"
            enabled: !!root.details.absolutePath
            onTriggered: root.copyRequested(String(root.details.absolutePath || ""))
        }
        MenuSeparator {}
        MenuItem {
            text: root.nodeStarred ? "Remove star" : "Add to starred"
            onTriggered: root.favoriteRequested(root.relative)
        }
        MenuItem {
            text: "Open in system app"
            enabled: !!root.details.url
            onTriggered: root.externalRequested(root.details.url)
        }
    }
    ToolTip.visible: rowMouse.containsMouse && root.relative.length > 0
    ToolTip.delay: 650
    ToolTip.text: root.relative
}
