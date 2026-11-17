import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// One category row. No assumptions about category names or depth.
Rectangle {
    id: root

    property var entry: ({})
    signal toggled(string path)

    implicitHeight: 28
    color: rowMouse.pressed ? Theme.colors.selection
           : rowMouse.containsMouse ? Theme.colors.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 90 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 9 + Math.min(6, Number(root.entry.depth || 0)) * 13
        anchors.rightMargin: 9
        spacing: 6

        Text {
            Layout.preferredWidth: 9
            text: root.entry.expanded ? "▾" : "▸"
            color: Theme.colors.muted
            font.pixelSize: 10
        }
        Image {
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            source: "qrc:/engine/assets/icons/folder.svg"
            sourceSize: Qt.size(28, 28)
            fillMode: Image.PreserveAspectFit
        }
        Label {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: String(root.entry.name || "")
            font.pixelSize: 11
            font.bold: Number(root.entry.depth || 0) === 0
            color: Theme.colors.text
            elide: Text.ElideRight
        }
        Rectangle {
            Layout.preferredWidth: Math.max(19, countLabel.implicitWidth + 10)
            Layout.preferredHeight: 17
            radius: 4
            color: Theme.colors.control
            Label {
                id: countLabel
                anchors.centerIn: parent
                text: String(root.entry.count || 0)
                color: Theme.colors.muted
                font.pixelSize: 9
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(String(root.entry.path || ""))
    }

    ToolTip.visible: rowMouse.containsMouse
    ToolTip.delay: 800
    ToolTip.text: (root.entry.expanded ? "Collapse " : "Expand ")
                  + String(root.entry.name || "")
}
