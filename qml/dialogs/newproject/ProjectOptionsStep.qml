import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles
import "WizardStyle.js" as S

Item {
    id: root
    required property string framework
    property string architecture: "standard"
    property bool initializeGit: false
    property bool layoutOpen: true
    property bool toolsOpen: true
    signal architectureEdited(string value)
    signal gitToggled(bool enabled)
    readonly property var choices: Profiles.architectureOptions(framework)

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            width: Math.max(0, root.width - 14)
            spacing: 6
            Label { text: "Project structure"; font.pixelSize: 19; font.weight: Font.DemiBold; color: S.title; Layout.topMargin: 5 }
            Label {
                text: "Select how the generator organizes your files. All layouts are editable."
                color: S.muted; font.pixelSize: 11
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                Layout.bottomMargin: 10
            }
            WizardSectionHeader {
                Layout.fillWidth: true
                title: "Architecture"
                iconSource: "qrc:/engine/assets/icons/tree.svg"
                subtitle: "Choose one"
                expanded: root.layoutOpen
                onToggled: root.layoutOpen = !root.layoutOpen
            }
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.layoutOpen
                Layout.topMargin: 6
                Layout.bottomMargin: 13
                spacing: 0
                Repeater {
                    model: root.choices
                    Item {
                        id: option
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 61
                        readonly property bool selected: root.architecture === modelData.id
                        Rectangle { anchors.fill: parent; color: option.selected ? S.selected : hover.containsMouse ? S.hover : "transparent" }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 14
                            spacing: 12
                            Rectangle {
                                Layout.preferredWidth: 15; Layout.preferredHeight: 15
                                radius: 8
                                color: option.selected ? S.accent : S.input
                                border.width: 1
                                border.color: option.selected ? S.accent : S.muted
                                Rectangle { anchors.centerIn: parent; width: 5; height: 5; radius: 3; color: "white"; visible: option.selected }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: option.modelData.name; font.pixelSize: 12; font.weight: option.selected ? Font.DemiBold : Font.Normal; color: S.title }
                                Label { text: option.modelData.detail; font.pixelSize: 11; color: S.muted; Layout.fillWidth: true; elide: Text.ElideRight }
                                Label { text: option.modelData.preview; font.pixelSize: 10; color: S.faint; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                        }
                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.architectureEdited(option.modelData.id)
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: S.line }
                    }
                }
            }
            WizardSectionHeader {
                Layout.fillWidth: true
                title: "Version Control"
                iconSource: "qrc:/engine/assets/icons/user_cog.svg"
                subtitle: "Git integration"
                expanded: root.toolsOpen
                onToggled: root.toolsOpen = !root.toolsOpen
            }
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.toolsOpen
                Layout.leftMargin: 12
                Layout.rightMargin: 8
                Layout.topMargin: 12
                spacing: 10
                WizardCheckRow {
                    Layout.fillWidth: true
                    title: "Create Git repository"
                    description: "Run git init after generating the project (if Git is installed)."
                    selected: root.initializeGit
                    onChanged: function(value) { root.gitToggled(value) }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Ignore rules"; font.pixelSize: 12; color: S.text; Layout.preferredWidth: 173 }
                    Label { text: root.framework === "html" ? "Manual" : "Bundled .gitignore"; font.pixelSize: 11; color: S.muted }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Project descriptor"; font.pixelSize: 12; color: S.text; Layout.preferredWidth: 173 }
                    Label { text: ".jeridi/project.json"; font.pixelSize: 11; color: S.muted }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line; Layout.topMargin: 18 }
            Label {
                Layout.fillWidth: true
                Layout.topMargin: 10
                text: "DEPENDENCIES  →  The next step lets you select packages, inspect their details and decide what to install."
                color: S.muted; font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
            Item { Layout.preferredHeight: 18 }
        }
    }
}
