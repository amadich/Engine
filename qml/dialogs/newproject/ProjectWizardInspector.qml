import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles
import "WizardStyle.js" as S

Rectangle {
    id: root
    required property string framework
    property string projectName: ""
    property string architecture: "standard"
    property string packageName: ""
    property string javaVersion: "17"
    property var dependencies: []
    property int step: 0
    property string selectedDependency: ""
    color: S.side
    readonly property var selectedPackage: {
        const all = Profiles.dependencyOptions(framework)
        for (let i = 0; i < all.length; i++)
            if (all[i].key === selectedDependency) return all[i]
        return null
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 39
            color: S.side
            Label { anchors.left: parent.left; anchors.leftMargin: 13; anchors.verticalCenter: parent.verticalCenter; text: root.step === 2 ? "PACKAGE DETAILS" : "PROJECT INSPECTOR"; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.7; color: S.muted }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                width: Math.max(0, root.width - 1)
                spacing: 0
                Item { Layout.preferredHeight: 16 }
                RowLayout {
                    visible: root.step !== 2
                    Layout.fillWidth: true
                    Layout.leftMargin: 13
                    Layout.rightMargin: 12
                    spacing: 10
                    WizardFrameworkIcon { framework: root.framework; Layout.preferredWidth: 30; Layout.preferredHeight: 30 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: Profiles.displayName(root.framework); color: S.title; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                        Label { text: Profiles.get(root.framework).runtime; color: S.muted; font.pixelSize: 10 }
                    }
                }
                Label {
                    visible: root.step === 2
                    Layout.fillWidth: true
                    Layout.leftMargin: 13
                    Layout.rightMargin: 10
                    text: root.selectedPackage ? root.selectedPackage.name : "Select a package"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: S.title
                    wrapMode: Text.WordWrap
                }
                Label {
                    visible: root.step === 2
                    Layout.fillWidth: true
                    Layout.leftMargin: 13
                    Layout.rightMargin: 10
                    Layout.topMargin: 8
                    text: root.selectedPackage ? root.selectedPackage.group : "Choose a package in the list to inspect its purpose."
                    color: S.muted
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line; Layout.topMargin: 17; Layout.bottomMargin: 10 }
                Label { Layout.leftMargin: 13; text: root.step === 2 ? "ARTIFACT / PACKAGE" : "CURRENT CONFIGURATION"; color: S.muted; font.pixelSize: 10; font.weight: Font.DemiBold }
                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 13
                    Layout.rightMargin: 12
                    Layout.topMargin: 9
                    text: root.step === 2
                        ? (root.selectedPackage ? root.selectedPackage.artifact : "—")
                        : (root.projectName || "Untitled project") + "\n" + root.architecture + "\n" + (Profiles.isBackend(root.framework) ? "Backend" : "Frontend")
                    color: S.text
                    font.pixelSize: 11
                    lineHeight: 1.45
                    wrapMode: Text.WrapAnywhere
                }
                Label {
                    visible: root.step === 2
                    Layout.fillWidth: true
                    Layout.leftMargin: 13
                    Layout.rightMargin: 12
                    Layout.topMargin: 13
                    text: root.selectedPackage ? root.selectedPackage.description : "Package descriptions and dependencies appear here."
                    color: S.muted
                    font.pixelSize: 11
                    lineHeight: 1.3
                    wrapMode: Text.WordWrap
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line; Layout.topMargin: 19; Layout.bottomMargin: 10 }
                Label {
                    Layout.leftMargin: 13
                    text: root.step === 2 ? "INSTALLATION" : "GENERATED FILES"
                    color: S.muted; font.pixelSize: 10; font.weight: Font.DemiBold
                }
                Label {
                    visible: root.step === 2
                    Layout.fillWidth: true
                    Layout.leftMargin: 13
                    Layout.rightMargin: 10
                    Layout.topMargin: 10
                    text: root.selectedPackage && root.dependencies.indexOf(root.selectedPackage.key) !== -1 ? "✓  Included in project" : "○  Not selected"
                    color: root.selectedPackage && root.dependencies.indexOf(root.selectedPackage.key) !== -1 ? S.success : S.muted
                    font.pixelSize: 11
                }
                Repeater {
                    model: root.step === 2 ? [] : Profiles.previewPaths(root.framework, root.architecture, root.packageName)
                    Label {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: 13
                        Layout.rightMargin: 8
                        Layout.topMargin: 7
                        text: "▸  " + String(modelData)
                        font.family: "Menlo"
                        font.pixelSize: 10
                        color: S.muted
                        elide: Text.ElideMiddle
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line; Layout.topMargin: 17; Layout.bottomMargin: 12 }
                Label { Layout.leftMargin: 13; text: "JERIDI PROJECT PROFILE"; color: S.faint; font.pixelSize: 10; font.weight: Font.DemiBold }
                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 13
                    Layout.rightMargin: 12
                    Layout.topMargin: 7
                    text: "The .jeridi/project.json manifest records framework, architecture and selected packages for context-aware components."
                    color: S.faint
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                }
                Item { Layout.preferredHeight: 18 }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            Layout.leftMargin: 12
            spacing: 6
            Rectangle { width: 6; height: 6; radius: 3; color: S.success }
            Label { text: "LOCAL GENERATOR"; font.pixelSize: 10; color: S.muted }
        }
    }
}
