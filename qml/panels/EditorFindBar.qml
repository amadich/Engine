import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    property alias query: findInput.text
    property alias replacement: replaceInput.text
    property bool matchCase: false
    property bool replaceVisible: false
    property int matchCount: 0
    signal searchRequested(bool backwards)
    signal replaceRequested()
    signal replaceAllRequested()
    signal closeRequested()
    function focusSearch() { findInput.forceActiveFocus(); findInput.selectAll() }

    color: Theme.colors.control
    implicitHeight: replaceVisible ? 70 : 37
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.colors.border }
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 3
        anchors.bottomMargin: 4
        spacing: 2
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 29
            spacing: 5
            Image { source: "qrc:/engine/assets/icons/search.svg"; Layout.preferredWidth: 15; Layout.preferredHeight: 15 }
            TextField {
                id: findInput
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                implicitHeight: 27
                font.pixelSize: 12
                placeholderText: "Find in current file"
                selectByMouse: true
                onAccepted: root.searchRequested(false)
                Keys.onEscapePressed: function(event) { root.closeRequested(); event.accepted = true }
            }
            Label {
                text: root.query ? root.matchCount + " matches" : ""
                color: Theme.colors.muted
                font.pixelSize: 10
                Layout.preferredWidth: 65
                horizontalAlignment: Text.AlignRight
            }
            ToolButton {
                text: "Aa"
                checkable: true
                checked: root.matchCase
                implicitWidth: 30
                implicitHeight: 27
                ToolTip.text: "Match case"
                ToolTip.visible: hovered
                onClicked: root.matchCase = checked
            }
            ToolButton { text: "↑"; implicitWidth: 27; implicitHeight: 27; onClicked: root.searchRequested(true); ToolTip.text: "Previous"; ToolTip.visible: hovered }
            ToolButton { text: "↓"; implicitWidth: 27; implicitHeight: 27; onClicked: root.searchRequested(false); ToolTip.text: "Next"; ToolTip.visible: hovered }
            ToolButton {
                text: root.replaceVisible ? "−" : "+"
                implicitWidth: 27
                implicitHeight: 27
                onClicked: root.replaceVisible = !root.replaceVisible
                ToolTip.text: "Toggle replace"
                ToolTip.visible: hovered
            }
            ToolButton { text: "×"; implicitWidth: 27; implicitHeight: 27; onClicked: root.closeRequested() }
        }
        RowLayout {
            visible: root.replaceVisible
            Layout.fillWidth: true
            Layout.preferredHeight: 29
            spacing: 5
            Label { text: "REPLACE"; font.pixelSize: 10; color: Theme.colors.muted; Layout.preferredWidth: 52 }
            TextField {
                id: replaceInput
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                implicitHeight: 27
                font.pixelSize: 12
                placeholderText: "Replace with…"
                onAccepted: root.replaceRequested()
            }
            Button { text: "Replace"; implicitHeight: 27; onClicked: root.replaceRequested() }
            Button { text: "All"; implicitHeight: 27; onClicked: root.replaceAllRequested() }
            Item { Layout.fillWidth: true }
        }
    }
}
