import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles
import "WizardStyle.js" as S

Rectangle {
    id: root
    property string framework: "react-vite"
    signal frameworkSelected(string id)
    color: S.side

    component FrameworkEntry: Item {
        id: entry
        required property var definition
        property bool active: false
        property bool matchesSearch: true
        signal chosen(string id)
        width: parent.width
        height: visible ? 43 : 0
        visible: matchesSearch
        Rectangle { anchors.fill: parent; color: entry.active ? S.selected : hit.containsMouse ? S.hover : "transparent" }
        Rectangle { width: 3; height: parent.height; color: S.accent; visible: entry.active }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10
            WizardFrameworkIcon {
                framework: entry.definition.id
                Layout.preferredWidth: 23
                Layout.preferredHeight: 23
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: entry.definition.name
                    font.pixelSize: 12
                    font.weight: entry.active ? Font.DemiBold : Font.Normal
                    color: entry.active ? "#ffffff" : S.text
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Label {
                    text: entry.definition.detail
                    font.pixelSize: 10
                    color: S.muted
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
        MouseArea {
            id: hit
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: entry.chosen(entry.definition.id)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 41
            color: S.side
            Label {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "PROJECT TEMPLATES"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.7
                color: S.muted
            }
        }
        WizardInput {
            id: search
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.bottomMargin: 9
            placeholderText: "Search templates..."
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            Column {
                width: root.width
                spacing: 0
                Item { width: parent.width; height: 12 }
                Label {
                    x: 13
                    text: "FRONTEND"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                    color: S.faint
                    height: 25
                }
                Repeater {
                    model: Profiles.frontend
                    FrameworkEntry {
                        required property var modelData
                        definition: modelData
                        active: root.framework === modelData.id
                        matchesSearch: search.text.trim() === "" || (modelData.name + " " + modelData.detail).toLowerCase().includes(search.text.trim().toLowerCase())
                        onChosen: function(id) { root.frameworkSelected(id) }
                    }
                }
                Item { width: parent.width; height: 15 }
                Label {
                    x: 13
                    text: "BACKEND"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                    color: S.faint
                    height: 25
                }
                Repeater {
                    model: Profiles.backend
                    FrameworkEntry {
                        required property var modelData
                        definition: modelData
                        active: root.framework === modelData.id
                        matchesSearch: search.text.trim() === "" || (modelData.name + " " + modelData.detail).toLowerCase().includes(search.text.trim().toLowerCase())
                        onChosen: function(id) { root.frameworkSelected(id) }
                    }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 4
            RowLayout {
                spacing: 6
                Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 6; radius: 3; color: S.success }
                Label { text: "5 LOCAL GENERATORS"; color: S.text; font.pixelSize: 10; font.weight: Font.DemiBold }
            }
            Label {
                Layout.fillWidth: true
                text: "Templates are bundled with Jeridi Engine. Dependency downloads are optional."
                wrapMode: Text.WordWrap
                font.pixelSize: 10
                lineHeight: 1.15
                color: S.faint
            }
        }
    }
}
