import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles

Item {
    id: root
    required property string framework
    property string projectName: ""
    property url parentFolder: ""
    property string packageName: ""
    property string javaVersion: "17"
    signal nameEdited(string value)
    signal packageEdited(string value)
    signal javaVersionEdited(string value)
    signal browseRequested()

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
        width: root.width - 12
        spacing: 15
        Label {
            text: "Configure " + Profiles.displayName(root.framework)
            color: "#f3f5fc"
            font.pixelSize: 23
            font.weight: Font.DemiBold
        }
        Label {
            text: "Set the basics of your project. Jeridi will generate the directory structure."
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: "#929bb0"
            font.pixelSize: 12
        }
        Item { Layout.preferredHeight: 5 }
        Label { text: "PROJECT NAME"; color: "#c5c9d7"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.1 }
        TextField {
            id: nameField
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            text: root.projectName
            selectByMouse: true
            placeholderText: "my-project"
            color: "white"
            background: Rectangle { color: "#191c25"; radius: 7; border.color: nameField.activeFocus ? "#5489e9" : "#424652" }
            onTextEdited: root.nameEdited(text)
        }
        Label { text: "LOCATION"; color: "#c5c9d7"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.1 }
        RowLayout {
            Layout.fillWidth: true
            spacing: 9
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 7
                color: "#191c25"
                border.color: "#424652"
                Label {
                    anchors.fill: parent
                    anchors.margins: 10
                    verticalAlignment: Text.AlignVCenter
                    text: root.parentFolder.toString()
                          ? decodeURIComponent(root.parentFolder.toString().replace("file://", ""))
                          : "Choose a parent directory…"
                    color: root.parentFolder.toString() ? "#e3e7f4" : "#777e91"
                    font.pixelSize: 12
                    elide: Text.ElideMiddle
                }
            }
            Button {
                text: "Browse…"
                onClicked: root.browseRequested()
            }
        }
        Label {
            Layout.fillWidth: true
            text: "The generated directory will be: " + (root.parentFolder.toString()
                  ? decodeURIComponent(root.parentFolder.toString().replace("file://", "")) + "/" + root.projectName : "—")
            color: "#7c879d"
            font.pixelSize: 10
            elide: Text.ElideMiddle
        }
        Item { Layout.preferredHeight: 4 }
        Label {
            visible: root.framework === "spring-boot"
            text: "JAVA PACKAGE / GROUP ID"
            color: "#c5c9d7"
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 1.1
        }
        TextField {
            id: groupField
            visible: root.framework === "spring-boot"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            text: root.packageName
            selectByMouse: true
            color: "white"
            placeholderText: "com.example.demo"
            background: Rectangle { color: "#191c25"; radius: 7; border.color: groupField.activeFocus ? "#5489e9" : "#424652" }
            onTextEdited: root.packageEdited(text)
        }
        Label {
            visible: root.framework === "spring-boot"
            text: "JAVA TARGET"
            color: "#c5c9d7"
            font.pixelSize: 10
            font.weight: Font.Bold
        }
        ComboBox {
            visible: root.framework === "spring-boot"
            Layout.preferredWidth: 180
            model: ["17 (LTS)", "21 (LTS)"]
            currentIndex: root.javaVersion === "21" ? 1 : 0
            onActivated: function(index) { root.javaVersionEdited(index === 1 ? "21" : "17") }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            radius: 8
            color: "#222837"
            border.color: "#303e53"
            RowLayout {
                anchors.fill: parent
                anchors.margins: 13
                spacing: 12
                Label { text: root.framework === "spring-boot" ? "☕" : root.framework === "express-ts" ? "◈" : "◆"; font.pixelSize: 24; color: "#8ab5ff" }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: root.framework === "spring-boot" ? "Java " + root.javaVersion + " · Maven · JAR · Spring Boot 3.5.16"
                                  : root.framework === "express-ts" ? "Node.js · TypeScript · Express 5"
                                  : Profiles.displayName(root.framework); font.pixelSize: 12; color: "#e4ebfd" }
                    Label { text: "Generated locally · editable project structure"; font.pixelSize: 10; color: "#939fb7" }
                }
            }
        }
        Item { Layout.fillHeight: true }
        }
    }
}
