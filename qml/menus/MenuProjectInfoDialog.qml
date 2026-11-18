import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Dialog {
    id: root
    required property ProjectController controller
    title: "Project Information"
    modal: true
    popupType: Popup.Window
    anchors.centerIn: parent
    width: Math.min(520, parent.width - 32)
    padding: 16
    standardButtons: Dialog.Close
    background: Rectangle {
        radius: 7
        color: Theme.colors.panel
        border.width: 1
        border.color: Theme.colors.border
    }
    contentItem: ColumnLayout {
        spacing: 12
        RowLayout {
            spacing: 12
            Image { source: "qrc:/engine/assets/icons/cube_blue.svg"; Layout.preferredWidth: 34; Layout.preferredHeight: 34 }
            ColumnLayout {
                spacing: 2
                Label { text: root.controller.activeProjectName; color: Theme.colors.text; font.bold: true; font.pixelSize: 17 }
                Label { text: "JERIDI PROJECT PROFILE"; color: Theme.colors.muted; font.pixelSize: 10 }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }
        Repeater {
            model: [
                {label:"Project type", value:root.controller.projectKind || "Not specified"},
                {label:"Framework", value:root.controller.projectFramework || "Not specified"},
                {label:"Architecture", value:root.controller.projectArchitecture || "Not specified"},
                {label:"Location", value:root.controller.activeProjectPath || "No project open"}
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 12
                Label { Layout.preferredWidth: 115; text: modelData.label; color: Theme.colors.muted; font.pixelSize: 12 }
                Label { Layout.fillWidth: true; text: modelData.value; color: Theme.colors.text; font.pixelSize: 12; wrapMode: Text.WrapAnywhere }
            }
        }
        Label {
            Layout.fillWidth: true
            text: "Component Library filters packages using this project's detected profile."
            wrapMode: Text.WordWrap
            color: Theme.colors.muted
            font.pixelSize: 11
        }
    }
}
