import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles

Rectangle {
    id: root
    property string framework: ""
    signal frameworkSelected(string id)

    color: "#181b23"

    component FrameworkEntry: Rectangle {
        id: entry
        required property var definition
        property bool active: false
        signal chosen(string id)

        width: parent.width
        height: 51
        radius: 7
        color: active ? "#2c466e" : hit.containsMouse ? "#292c38" : "transparent"
        border.color: active ? "#4779c6" : "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 11
            Label {
                text: String(entry.definition.icon)
                color: entry.active ? "#8dbdff" : "#939ab6"
                font.pixelSize: 20
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
            }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: String(entry.definition.name)
                    elide: Text.ElideRight
                    color: "#eef2ff"
                    font.pixelSize: 13
                    font.weight: entry.active ? Font.DemiBold : Font.Normal
                }
                Label {
                    text: String(entry.definition.detail)
                    color: "#8690a5"
                    font.pixelSize: 10
                }
            }
        }
        MouseArea {
            id: hit
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: entry.chosen(String(entry.definition.id))
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        Label { text: "PROJECT TYPES"; color: "#c6cadd"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6 }
        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "⌕  Search frameworks"
            font.pixelSize: 12
            selectByMouse: true
            color: "#f3f5fc"
            background: Rectangle { radius: 7; color: "#232631"; border.color: searchField.activeFocus ? "#497bd0" : "#3c404d" }
        }
        Item { Layout.preferredHeight: 8 }
        Label { text: "FRONTEND"; color: "#7e8cab"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.4 }
        Column {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: Profiles.frontend
                FrameworkEntry {
                    required property var modelData
                    definition: modelData
                    active: root.framework === String(modelData.id)
                    visible: searchField.text.trim() === "" ||
                             String(modelData.name).toLowerCase().includes(searchField.text.toLowerCase())
                    onChosen: function(id) { root.frameworkSelected(id) }
                }
            }
        }
        Item { Layout.preferredHeight: 12 }
        Label { text: "BACKEND"; color: "#7e8cab"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.4 }
        Column {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: Profiles.backend
                FrameworkEntry {
                    required property var modelData
                    definition: modelData
                    active: root.framework === String(modelData.id)
                    visible: searchField.text.trim() === "" ||
                             String(modelData.name).toLowerCase().includes(searchField.text.toLowerCase())
                    onChosen: function(id) { root.frameworkSelected(id) }
                }
            }
        }
        Item { Layout.fillHeight: true }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#373b47" }
        Label {
            Layout.fillWidth: true
            text: "Templates are stored locally. Package downloads are optional."
            color: "#8b92a8"
            font.pixelSize: 10
            wrapMode: Text.WordWrap
        }
    }
}
