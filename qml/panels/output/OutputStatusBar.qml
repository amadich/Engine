import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    color: Theme.colors.surface
    implicitHeight: 26

    property bool frozen: false
    property bool following: true
    property string notice: ""
    property int droppedCount: 0
    property int errors: 0
    property int warnings: 0

    Rectangle {
        anchors.top: parent.top
        height: 1
        width: parent.width
        color: Theme.colors.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        spacing: 7
        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: 6
            radius: 3
            color: root.frozen ? "#E6B86B" : "#24C292"
        }
        Label {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.notice || (root.frozen ? "View paused — still capturing"
                  : root.following ? "Following latest output" : "Scroll position locked")
            color: root.notice ? Theme.colors.accent : Theme.colors.muted
            font.pixelSize: 9
        }
        Label {
            visible: root.droppedCount > 0 && root.width > 580
            text: root.droppedCount + " old lines trimmed"
            color: "#E6B86B"
            font.pixelSize: 9
        }
        Label {
            text: "● " + root.errors + "   ⚠ " + root.warnings
            color: Theme.colors.muted
            font.pixelSize: 9
            font.family: "Menlo"
        }
    }
}
