import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles
import "WizardStyle.js" as S

Item {
    id: root
    required property string framework
    required property string projectName
    required property string architecture
    required property string packageName
    property string javaVersion: "17"
    property string description: ""
    property string serverPort: "8080"
    property url parentFolder: ""
    property var dependencies: []
    property bool initializeGit: false
    property bool installNow: false
    signal installNowToggled(bool enabled)

    readonly property var rows: [
        { title: "Project", value: projectName || "—" },
        { title: "Template", value: Profiles.displayName(framework) },
        { title: "Architecture", value: architecture },
        { title: "Runtime", value: framework === "spring-boot" ? "Java " + javaVersion + " · Maven" : Profiles.get(framework).runtime },
        { title: "Group ID", value: framework === "spring-boot" ? packageName : "—" },
        { title: "Server port", value: Profiles.isBackend(framework) ? serverPort : "—" },
        { title: "Version control", value: initializeGit ? "Initialize Git" : "Not initialized" },
        { title: "Packages", value: dependencies.length ? dependencies.length + " optional" : "Core packages only" }
    ]
    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            width: Math.max(0, root.width - 14)
            spacing: 0
            Label { text: "Review configuration"; font.pixelSize: 19; font.weight: Font.DemiBold; color: S.title; Layout.topMargin: 5 }
            Label {
                text: "Verify the options before creating files on disk."
                font.pixelSize: 11; color: S.muted
                Layout.topMargin: 5; Layout.bottomMargin: 13
            }
            WizardSectionHeader { Layout.fillWidth: true; title: "Project Summary"; collapsible: false; iconSource: "qrc:/engine/assets/icons/check_badge.svg"; subtitle: "Read-only" }
            Repeater {
                model: root.rows
                Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 29
                    color: index % 2 === 0 ? "#292b2e" : "#2d2f33"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 12
                        Label { Layout.preferredWidth: 164; text: modelData.title; font.pixelSize: 11; color: S.muted }
                        Label { Layout.fillWidth: true; text: modelData.value; font.pixelSize: 11; color: S.title; elide: Text.ElideRight }
                    }
                }
            }
            WizardSectionHeader {
                Layout.fillWidth: true
                Layout.topMargin: 13
                title: "Optional Packages"
                collapsible: false
                iconSource: "qrc:/engine/assets/icons/package.svg"
                subtitle: root.dependencies.length + " selected"
            }
            Label {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 12
                Layout.leftMargin: 12
                text: root.dependencies.length ? root.dependencies.join("  ·  ") : "No optional packages selected"
                color: S.text; font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
            WizardSectionHeader { Layout.fillWidth: true; title: "After Generation"; collapsible: false; iconSource: "qrc:/engine/assets/icons/install_options.svg"; subtitle: "Execution options" }
            WizardCheckRow {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.leftMargin: 12
                visible: root.framework !== "html"
                title: "Download dependencies after creating project"
                description: root.framework === "spring-boot" ? "Runs Maven dependency:go-offline. Requires JDK, Maven and internet." : "Runs npm install. Requires Node.js and internet."
                selected: root.installNow
                onChanged: function(value) { root.installNowToggled(value) }
            }
            Label {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.leftMargin: 12
                text: "Files are generated from local templates. An existing project folder will not be overwritten."
                font.pixelSize: 11
                color: S.success
                wrapMode: Text.WordWrap
            }
            Label {
                visible: root.framework === "spring-boot" && root.dependencies.indexOf("data-jpa") !== -1
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.leftMargin: 12
                text: "Note: Spring Data JPA needs a configured database before the application can start."
                font.pixelSize: 11
                color: S.warning
                wrapMode: Text.WordWrap
            }
            Item { Layout.preferredHeight: 18 }
        }
    }
}
