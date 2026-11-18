import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "WizardStyle.js" as S

Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    property string iconSource: ""
    property bool expanded: true
    property bool collapsible: true
    signal toggled()
    implicitHeight: 27
    color: S.surface
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 9
        anchors.rightMargin: 10
        spacing: 7
        Label { text: root.expanded ? "▾" : "▸"; visible: root.collapsible; color: S.muted; font.pixelSize: 11; Layout.preferredWidth: 10 }
        Image { source: root.iconSource; visible: root.iconSource.length > 0; Layout.preferredWidth: visible ? 14 : 0; Layout.preferredHeight: 14; sourceSize.width: 28; sourceSize.height: 28; fillMode: Image.PreserveAspectFit }
        Label { text: root.title; color: S.title; font.pixelSize: 11; font.weight: Font.DemiBold }
        Item { Layout.fillWidth: true }
        Label { text: root.subtitle; color: S.muted; font.pixelSize: 10; visible: root.subtitle.length > 0 }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.collapsible
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
