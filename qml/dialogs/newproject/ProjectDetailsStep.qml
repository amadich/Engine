import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles
import "WizardStyle.js" as S

Item {
    id: root
    required property string framework
    property string projectName: ""
    property url parentFolder: ""
    property string packageName: "com.example.demo"
    property string javaVersion: "17"
    property string description: ""
    property string serverPort: "8080"
    property bool generalOpen: true
    property bool runtimeOpen: true
    signal nameEdited(string value)
    signal packageEdited(string value)
    signal javaVersionEdited(string value)
    signal descriptionEdited(string value)
    signal serverPortEdited(string value)
    signal browseRequested()

    readonly property bool spring: framework === "spring-boot"
    readonly property bool backend: Profiles.isBackend(framework)
    readonly property string parentPath: parentFolder.toString() ? decodeURIComponent(parentFolder.toString().replace("file://", "")) : ""

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            width: Math.max(0, root.width - 14)
            spacing: 5
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 8
                spacing: 11
                WizardFrameworkIcon { framework: root.framework; Layout.preferredWidth: 30; Layout.preferredHeight: 30 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Label { text: Profiles.displayName(root.framework); font.pixelSize: 19; font.weight: Font.DemiBold; color: S.title }
                    Label { text: Profiles.get(root.framework).detail + "  ·  " + Profiles.get(root.framework).runtime; font.pixelSize: 11; color: S.muted }
                }
                Label { text: "OFFLINE TEMPLATE"; font.pixelSize: 9; color: S.success }
            }
            WizardSectionHeader {
                Layout.fillWidth: true
                title: "General Settings"
                iconSource: "qrc:/engine/assets/icons/cog_tool_administration_control_edit_option.svg"
                subtitle: "Project identity & location"
                expanded: root.generalOpen
                onToggled: root.generalOpen = !root.generalOpen
            }
            ColumnLayout {
                visible: root.generalOpen
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 7
                Layout.topMargin: 8
                Layout.bottomMargin: 10
                spacing: 7
                WizardFormRow {
                    label: "Project name"
                    WizardInput {
                        anchors.fill: parent
                        text: root.projectName
                        placeholderText: "my-project"
                        onTextEdited: root.nameEdited(text)
                    }
                }
                WizardFormRow {
                    label: "Location"
                    RowLayout {
                        anchors.fill: parent
                        spacing: 6
                        WizardInput {
                            Layout.fillWidth: true
                            readOnly: true
                            text: root.parentPath
                            placeholderText: "Select a parent directory..."
                            ToolTip.visible: hovered && root.parentPath.length > 0
                            ToolTip.text: root.parentPath
                        }
                        WizardActionButton {
                            text: "Browse..."
                            Layout.preferredWidth: 76
                            onClicked: root.browseRequested()
                        }
                    }
                }
                WizardFormRow {
                    label: "Description"
                    WizardInput {
                        anchors.fill: parent
                        text: root.description
                        placeholderText: "Optional project description"
                        onTextEdited: root.descriptionEdited(text)
                    }
                }
                WizardFormRow {
                    label: "Template"
                    RowLayout {
                        anchors.fill: parent
                        spacing: 7
                        WizardFrameworkIcon { framework: root.framework; Layout.preferredWidth: 18; Layout.preferredHeight: 18 }
                        Label { text: Profiles.displayName(root.framework); font.pixelSize: 12; color: S.text }
                        Item { Layout.fillWidth: true }
                        Label { text: Profiles.isBackend(root.framework) ? "Backend" : "Frontend"; font.pixelSize: 10; color: S.muted }
                    }
                }
            }
            WizardSectionHeader {
                Layout.fillWidth: true
                title: "Runtime & Build"
                iconSource: "qrc:/engine/assets/icons/server_square_update.svg"
                subtitle: root.spring ? "Java / Maven" : root.framework === "express-ts" ? "Node.js / TypeScript" : "Toolchain"
                expanded: root.runtimeOpen
                onToggled: root.runtimeOpen = !root.runtimeOpen
            }
            ColumnLayout {
                visible: root.runtimeOpen
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 7
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                spacing: 7
                WizardFormRow {
                    visible: root.spring
                    label: "Group / Package"
                    WizardInput {
                        anchors.fill: parent
                        text: root.packageName
                        placeholderText: "com.example.demo"
                        onTextEdited: root.packageEdited(text)
                    }
                }
                WizardFormRow {
                    visible: root.spring
                    label: "Java target"
                    RowLayout {
                        anchors.fill: parent
                        spacing: 8
                        WizardCombo {
                            Layout.preferredWidth: 130
                            model: ["Java 17 (LTS)", "Java 21 (LTS)"]
                            currentIndex: root.javaVersion === "21" ? 1 : 0
                            onActivated: function(index) { root.javaVersionEdited(index === 1 ? "21" : "17") }
                        }
                        Label { text: "Maven · JAR"; font.pixelSize: 11; color: S.muted }
                    }
                }
                WizardFormRow {
                    visible: root.backend
                    label: "Server port"
                    RowLayout {
                        anchors.fill: parent
                        spacing: 8
                        WizardInput {
                            Layout.preferredWidth: 130
                            text: root.serverPort
                            validator: IntValidator { bottom: 1024; top: 65535 }
                            inputMethodHints: Qt.ImhDigitsOnly
                            onTextEdited: root.serverPortEdited(text)
                        }
                        Label { text: "1024–65535"; font.pixelSize: 10; color: S.muted }
                    }
                }
                WizardFormRow {
                    label: "Build system"
                    Label {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: root.spring ? "Apache Maven" : root.framework === "html" ? "None (static)" : "npm"
                        font.pixelSize: 12
                        color: S.text
                    }
                }
                WizardFormRow {
                    label: "Generator"
                    Label {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: root.spring ? "Spring Boot 3.5.16" : root.framework === "html" ? "HTML5" : "Local TypeScript template"
                        font.pixelSize: 12
                        color: S.text
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line; Layout.topMargin: 8 }
            Label {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                text: "OUTPUT  " + (root.parentPath ? root.parentPath + "/" + (root.projectName || "<project>") : "Select a destination to preview the path")
                font.pixelSize: 10
                color: S.muted
                elide: Text.ElideMiddle
            }
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                text: "The generator never overwrites an existing project directory."
                font.pixelSize: 10
                color: S.faint
            }
            Item { Layout.preferredHeight: 14 }
        }
    }
}
