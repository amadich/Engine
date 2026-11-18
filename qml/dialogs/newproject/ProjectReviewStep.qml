import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles

Item {
    id: root
    required property string framework
    required property string projectName
    required property string architecture
    required property string packageName
    property string javaVersion: "17"
    property var dependencies: []
    property bool initializeGit: false
    property bool installNow: false
    signal installNowToggled(bool enabled)

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
        width: root.width - 12
        spacing: 18
        Label { text: "Ready to create"; color: "white"; font.pixelSize: 23; font.weight: Font.DemiBold }
        Label {
            Layout.fillWidth: true
            text: "Review the project before writing any files."
            font.pixelSize: 12
            color: "#9ca4b8"
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.framework === "spring-boot" ? 270 : 225
            color: "#1b202c"
            radius: 11
            border.color: "#3b4254"
            GridLayout {
                anchors.fill: parent
                anchors.margins: 18
                columns: 2
                columnSpacing: 25
                rowSpacing: 17
                Label { text: "Project"; color: "#8b98af"; font.pixelSize: 12 }
                Label { text: root.projectName; color: "#f2f4fc"; font.pixelSize: 13; font.weight: Font.DemiBold }
                Label { text: "Framework"; color: "#8b98af"; font.pixelSize: 12 }
                Label { text: Profiles.displayName(root.framework); color: "#f2f4fc"; font.pixelSize: 13 }
                Label { text: "Architecture"; color: "#8b98af"; font.pixelSize: 12 }
                Label { text: root.architecture; color: "#f2f4fc"; font.pixelSize: 13 }
                Label { text: "Java package"; visible: root.framework === "spring-boot"; color: "#8b98af"; font.pixelSize: 12 }
                Label { text: root.packageName; visible: root.framework === "spring-boot"; color: "#f2f4fc"; font.pixelSize: 12 }
                Label { text: "Java target"; visible: root.framework === "spring-boot"; color: "#8b98af"; font.pixelSize: 12 }
                Label { text: root.javaVersion + " / Maven / JAR"; visible: root.framework === "spring-boot"; color: "#f2f4fc"; font.pixelSize: 12 }
                Label { text: "Git"; color: "#8b98af"; font.pixelSize: 12 }
                Label { text: root.initializeGit ? "Initialize repository" : "Not initialized"; color: "#f2f4fc"; font.pixelSize: 12 }
                Label { text: "Extras"; color: "#8b98af"; font.pixelSize: 12 }
                Label { text: root.dependencies.length ? root.dependencies.join(", ") : "Core only"; color: "#f2f4fc"; font.pixelSize: 12 }
            }
        }
        CheckBox {
            visible: root.framework !== "html"
            text: "Download dependencies after creation"
            checked: root.installNow
            font.pixelSize: 13
            onToggled: root.installNowToggled(checked)
        }
        Label {
            Layout.fillWidth: true
            text: root.framework === "spring-boot"
                 ? "Uses Maven dependency:go-offline. This requires Maven, a JDK and internet access."
                 : root.framework === "html"
                   ? "No package manager is required for this static project."
                   : "Uses npm install. This requires Node.js and internet access."
            color: "#919aad"
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#233549"
            radius: 8
            border.color: "#385b79"
            Label {
                anchors.fill: parent
                anchors.margins: 13
                verticalAlignment: Text.AlignVCenter
                text: "✓ Templates are generated locally. Existing folders are never overwritten."
                wrapMode: Text.WordWrap
                color: "#b2ddff"
                font.pixelSize: 12
            }
        }
        Item { Layout.fillHeight: true }
        }
    }
}
