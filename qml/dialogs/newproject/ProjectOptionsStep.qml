import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles

Item {
    id: root
    required property string framework
    property string architecture: ""
    property var dependencies: []
    property bool initializeGit: false
    signal architectureEdited(string value)
    signal dependencyToggled(string id, bool enabled)
    signal gitToggled(bool enabled)

    readonly property bool backend: Profiles.isBackend(framework)
    readonly property var architectureChoices: backend
        ? [{ key: "layered", label: "Layered", description: "controller / service / repository" },
           { key: "feature-based", label: "Feature-based", description: "features / shared modules" }]
        : [{ key: "standard", label: "Standard", description: "src / components / assets" },
           { key: "feature-based", label: "Feature-based", description: "features organized by domain" }]

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
        width: root.width - 12
        spacing: 13
        Label { text: "Architecture & tooling"; font.pixelSize: 23; font.weight: Font.DemiBold; color: "#f6f7fe" }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Choose a project layout and optional integrations. No dependencies are installed until you confirm."
            font.pixelSize: 12
            color: "#9ea5b7"
        }
        Item { Layout.preferredHeight: 7 }
        Label { text: "PROJECT ARCHITECTURE"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2; color: "#c7ccdc" }
        Repeater {
            model: root.architectureChoices
            Rectangle {
                id: architectureRow
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                radius: 8
                color: root.architecture === modelData.key ? "#253959" : "#1b1f2a"
                border.color: root.architecture === modelData.key ? "#4c83da" : "#3b414f"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 13; spacing: 11
                    Rectangle {
                        Layout.preferredWidth: 18; Layout.preferredHeight: 18
                        radius: 9
                        border.color: root.architecture === modelData.key ? "#75a8fd" : "#6c7183"
                        border.width: root.architecture === modelData.key ? 5 : 1
                        color: "#171b26"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Label { text: modelData.label; color: "#e9edfb"; font.weight: Font.DemiBold; font.pixelSize: 13 }
                        Label { text: modelData.description; color: "#9fa9bd"; font.pixelSize: 11 }
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.architectureEdited(modelData.key) }
            }
        }
        Item { Layout.preferredHeight: 8 }
        Label { text: "OPTIONAL DEPENDENCIES"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2; color: "#c7ccdc" }
        Repeater {
            model: Profiles.dependencyOptions(root.framework)
            CheckBox {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.name
                checked: root.dependencies.indexOf(modelData.key) !== -1
                font.pixelSize: 12
                onToggled: root.dependencyToggled(modelData.key, checked)
                ToolTip.visible: hovered
                ToolTip.text: modelData.detail
            }
        }
        Label {
            Layout.fillWidth: true
            visible: Profiles.dependencyOptions(root.framework).length === 0
            text: "Core dependencies are already defined by this template."
            color: "#929bae"
            font.pixelSize: 11
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#383d4a" }
        CheckBox {
            text: "Initialize a Git repository"
            checked: root.initializeGit
            font.pixelSize: 12
            onToggled: root.gitToggled(checked)
        }
        Item { Layout.fillHeight: true }
        }
    }
}
