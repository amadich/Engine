import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine
import "OutputFormat.js" as Format

// A single console event. Only this component controls the row appearance.
Rectangle {
    id: root

    property int sequence: 0
    property string timestamp: ""
    property string level: "info"
    property string origin: "engine"
    property string message: ""
    property bool showTimestamp: true
    property bool wrapText: true
    property bool selected: false
    signal selectedRequested(int sequence)
    signal copyRequested(string content)

    readonly property color tone: Format.levelColor(level)
    readonly property bool detailsFit: width >= 590

    HoverHandler { id: rowHover }

    height: Math.max(28, messageText.implicitHeight + 10)
    color: selected ? Theme.colors.selection
           : rowHover.hovered ? Theme.colors.hover
           : (sequence % 2 === 0 ? Theme.colors.surface : Theme.colors.panel)

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.selectedRequested(root.sequence)
        onDoubleClicked: root.copyRequested(root.message)
        cursorShape: Qt.IBeamCursor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 7
        anchors.rightMargin: 8
        spacing: 7

        Label {
            Layout.preferredWidth: 39
            text: String(root.sequence).padStart(3, "0")
            font.family: "Menlo"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignRight
            color: Theme.colors.disabled
        }

        Rectangle {
            Layout.preferredWidth: 2
            Layout.fillHeight: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            radius: 1
            color: root.tone
        }

        Label {
            visible: root.showTimestamp && root.detailsFit
            Layout.preferredWidth: visible ? 57 : 0
            text: root.timestamp
            font.family: "Menlo"
            font.pixelSize: 10
            color: Theme.colors.disabled
        }

        Rectangle {
            visible: root.detailsFit
            Layout.preferredWidth: visible ? 59 : 0
            Layout.preferredHeight: 18
            radius: 4
            color: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.10)
            border.width: 1
            border.color: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.25)

            Label {
                anchors.centerIn: parent
                text: Format.levelLabel(root.level)
                font.pixelSize: 9
                font.bold: true
                color: root.tone
            }
        }

        Text {
            id: messageText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            text: root.message === "" ? " " : root.message
            textFormat: Text.PlainText
            font.family: "Menlo"
            font.pixelSize: 11
            color: root.level === "error" ? "#F6A1A7"
                 : root.level === "warning" ? "#E9C98D" : Theme.colors.text
            wrapMode: root.wrapText ? Text.WrapAnywhere : Text.NoWrap
            elide: root.wrapText ? Text.ElideNone : Text.ElideRight
            maximumLineCount: root.wrapText ? 10000 : 1
            ToolTip.visible: !root.wrapText && rowHover.hovered && truncated
            ToolTip.text: root.message
            ToolTip.delay: 650
        }

        OutputIconButton {
            visible: rowHover.hovered || root.selected
            Layout.preferredWidth: visible ? 22 : 0
            Layout.preferredHeight: 22
            iconSize: 12
            iconSource: "qrc:/engine/assets/icons/copy.svg"
            hint: "Copy this message"
            onClicked: root.copyRequested(root.message)
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.colors.border
        opacity: 0.28
    }
}
