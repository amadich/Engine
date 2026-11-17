import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    property bool frozen: false
    property int unseen: 0
    color: Theme.colors.surface
    implicitHeight: 46

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        spacing: 9

        Rectangle {
            Layout.preferredWidth: 31
            Layout.preferredHeight: 31
            radius: 7
            color: "Transparent" /*Theme.colors.control*/
            border.color: Theme.colors.border
            border.width: 0
            Image {
                anchors.centerIn: parent
                width: 17
                height: 17
                source: "qrc:/engine/assets/icons/file.svg"
                sourceSize: Qt.size(34, 34)
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label {
                text: "OUTPUT CONSOLE"
                color: Theme.colors.text
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 0.5
            }
            Label {
                Layout.fillWidth: true
                text: root.frozen ? "View paused · capture continues"
                      : "Build, processes & engine activity"
                color: Theme.colors.muted
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
        Rectangle {
            Layout.preferredWidth: 7
            Layout.preferredHeight: 7
            radius: 4
            color: root.frozen ? "#E6B86B" : "#24C292"
        }
        Label {
            text: root.frozen ? "PAUSED" : "LIVE"
            font.pixelSize: 9
            font.bold: true
            color: root.frozen ? "#E6B86B" : "#44CFA5"
        }
        Rectangle {
            visible: root.unseen > 0
            Layout.preferredHeight: visible ? 20 : 0
            Layout.preferredWidth: visible ? unseenLabel.implicitWidth + 12 : 0
            radius: 5
            color: Theme.colors.selection
            Label {
                id: unseenLabel
                anchors.centerIn: parent
                text: "+" + root.unseen
                color: Theme.colors.accent
                font.pixelSize: 10
                font.bold: true
            }
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.colors.border
    }
}
