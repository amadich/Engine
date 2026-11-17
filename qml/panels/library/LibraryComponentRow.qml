import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Package row: selection is preview-only. Favorite is a local preference.
Rectangle {
    id: root

    property var entry: ({})
    property bool selected: false
    property bool favorite: false
    property bool installed: false
    signal activated(string componentId)
    signal favoriteToggled(string componentId)

    implicitHeight: 34
    color: selected ? Theme.colors.selection
           : rowMouse.pressed ? Theme.colors.selection
           : rowMouse.containsMouse ? Theme.colors.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 95 } }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: Theme.colors.accent
        visible: root.selected
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) rowMenu.popup()
            else root.activated(String(root.entry.id || ""))
        }
    }


    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16 + Math.min(6, Number(root.entry.depth || 0)) * 13
        anchors.rightMargin: 7
        spacing: 7

        Image {
            Layout.preferredWidth: 15
            Layout.preferredHeight: 15
            source: root.selected
                    ? "qrc:/engine/assets/icons/cube_blue.svg"
                    : "qrc:/engine/assets/icons/cube.svg"
            sourceSize: Qt.size(30, 30)
            fillMode: Image.PreserveAspectFit
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 0
            Label {
                Layout.fillWidth: true
                text: String(root.entry.name || "")
                color: Theme.colors.text
                font.pixelSize: 11
                font.bold: root.selected
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                text: String(root.entry.id || "") + "  ·  "
                      + Number(root.entry.fileCount || 0) + " file"
                      + (Number(root.entry.fileCount || 0) === 1 ? "" : "s")
                color: Theme.colors.muted
                font.pixelSize: 8
                elide: Text.ElideRight
                visible: true
            }
        }
        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: 6
            radius: 3
            color: root.installed ? "#32C48D" : Theme.colors.disabled
            opacity: root.installed ? 1 : 0.55
        }
        LibraryIconButton {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 23
            visible: root.favorite || root.selected || rowMouse.containsMouse
            iconSource: "qrc:/engine/assets/icons/star.svg"
            iconSize: 13
            selected: root.favorite
            hint: root.favorite ? "Remove from favorites" : "Add to favorites"
            onTriggered: root.favoriteToggled(String(root.entry.id || ""))
        }
    }

    Menu {
        id: rowMenu
        MenuItem {
            text: "Inspect package"
            onTriggered: root.activated(String(root.entry.id || ""))
        }
        MenuItem {
            text: root.favorite ? "Remove from favorites" : "Add to favorites"
            onTriggered: root.favoriteToggled(String(root.entry.id || ""))
        }
    }

    ToolTip.visible: rowMouse.containsMouse && !root.selected
    ToolTip.delay: 850
    ToolTip.text: "Select " + String(root.entry.name || "") + " in Inspector"
}
