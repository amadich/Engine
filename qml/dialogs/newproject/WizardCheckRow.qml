import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "WizardStyle.js" as S

Item {
    id: root
    property string title: ""
    property string description: ""
    property bool selected: false
    signal changed(bool checked)
    implicitHeight: description.length ? 43 : 30
    RowLayout {
        anchors.fill: parent
        spacing: 9
        CheckBox {
            id: check
            checked: root.selected
            implicitWidth: 18
            implicitHeight: 25
            Layout.alignment: Qt.AlignTop
            indicator: Rectangle {
                x: 1; y: 5
                width: 15; height: 15; radius: 2
                color: check.checked ? S.accent : S.input
                border.color: check.checked ? S.accent : "#62666f"
                border.width: 1
                Text { anchors.centerIn: parent; text: "✓"; visible: check.checked; color: "white"; font.pixelSize: 11; font.weight: Font.Bold }
            }
            onClicked: root.changed(checked)
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label { text: root.title; color: S.text; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
            Label { text: root.description; color: S.muted; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight; visible: root.description.length > 0 }
        }
    }
    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: 24
        cursorShape: Qt.PointingHandCursor
        onClicked: root.changed(!root.selected)
    }
}
