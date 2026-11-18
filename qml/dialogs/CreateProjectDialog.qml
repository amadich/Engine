import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import JeridiEngine
import "ProjectProfiles.js" as Profiles

// Multi-step project wizard. State and validation only; filesystem work stays in C++.
Dialog {
    id: root
    required property ProjectController controller

    property int step: 0
    property string framework: "react-vite"
    property string projectName: ""
    property url parentFolder: ""
    property string packageName: "com.example.demo"
    property string javaVersion: "17"
    property string architecture: "standard"
    property var dependencies: []
    property bool initializeGit: false
    property bool installNow: false
    property string inlineError: ""

    readonly property bool detailsValid:
        /^[a-z][a-z0-9_-]{0,63}$/.test(projectName.trim())
        && parentFolder.toString() !== ""
        && (framework !== "spring-boot"
            || /^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$/.test(packageName.trim()))
    readonly property bool canProceed: step !== 0 || detailsValid

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(1010, parent ? parent.width - 28 : 1010)
    height: Math.min(710, parent ? parent.height - 28 : 710)
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape
    header: Item { implicitHeight: 0 }
    footer: Item { implicitHeight: 0 }
    background: Rectangle {
        radius: 13
        color: "#202229"
        border.color: "#464b57"
        border.width: 1
    }

    function selectFramework(id) {
        framework = id
        architecture = Profiles.isBackend(id) ? "layered" : "standard"
        dependencies = id === "spring-boot" ? ["security", "validation"] : []
        installNow = false
        inlineError = ""
        step = 0
    }

    function toggleDependency(id, checked) {
        const next = dependencies.slice()
        const index = next.indexOf(id)
        if (checked && index === -1) next.push(id)
        if (!checked && index >= 0) next.splice(index, 1)
        dependencies = next
    }

    function createProject() {
        inlineError = ""
        if (!detailsValid) {
            step = 0
            inlineError = "Check project name, location and Java package."
            return
        }
        const success = controller.createConfiguredProject({
            name: projectName.trim(),
            parentFolder: parentFolder,
            framework: framework,
            architecture: architecture,
            packageName: packageName.trim(),
            javaVersion: javaVersion,
            dependencies: dependencies,
            initializeGit: initializeGit
        })
        if (!success) {
            inlineError = controller.lastProjectError
            return
        }
        root.close()
        if (installNow && framework !== "html")
            controller.installDependencies()
    }

    onOpened: {
        step = 0
        inlineError = ""
    }

    FolderDialog {
        id: parentPicker
        title: "Where should the new project be created?"
        onAccepted: root.parentFolder = selectedFolder
    }

    component WizardButton: Button {
        id: button
        property bool emphasized: false
        implicitHeight: 36
        implicitWidth: 94
        contentItem: Text {
            text: button.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: button.enabled ? "#fff" : "#8b91a1"
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
        background: Rectangle {
            radius: 7
            color: !button.enabled ? "#30343e"
                 : button.down ? "#1d5397"
                 : button.emphasized ? (button.hovered ? "#4a91f7" : "#3479df")
                 : button.hovered ? "#424854" : "#343942"
            border.color: button.emphasized && button.enabled ? "#5e9bf0" : "#515766"
        }
    }

    contentItem: ColumnLayout {
        spacing: 0
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 63
            color: "#24272e"
            radius: 13
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 23
                anchors.rightMargin: 17
                spacing: 12
                Label { text: "✦"; color: "#a89aff"; font.pixelSize: 23 }
                Label { text: "New Project"; color: "#f8f9fc"; font.pixelSize: 19; font.weight: Font.DemiBold }
                Item { Layout.fillWidth: true }
                Label { text: "JERIDI ENGINE / PROJECT GENERATOR"; color: "#858c9c"; font.pixelSize: 10; font.letterSpacing: 1 }
                ToolButton {
                    id: closeButton
                    text: "✕"
                    onClicked: root.reject()
                    background: Rectangle { radius: 6; color: closeButton.hovered ? "#373a43" : "transparent" }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#3b3f49" }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            ProjectTypeSidebar {
                Layout.preferredWidth: 246
                Layout.fillHeight: true
                framework: root.framework
                onFrameworkSelected: function(id) { root.selectFramework(id) }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#373b45" }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 24
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Repeater {
                        model: ["PROJECT", "TOOLS", "REVIEW"]
                        RowLayout {
                            required property int index
                            required property string modelData
                            spacing: 6
                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 12
                                color: index <= root.step ? "#3b75d3" : "#3a3e49"
                                Label {
                                    anchors.centerIn: parent
                                    text: index < root.step ? "✓" : String(index + 1)
                                    font.pixelSize: 11
                                    color: "white"
                                }
                            }
                            Label {
                                text: modelData
                                color: index === root.step ? "#e8ecff" : "#818a9d"
                                font.pixelSize: 11
                                font.weight: index === root.step ? Font.Bold : Font.Normal
                            }
                            Item { Layout.preferredWidth: 10 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
                Item { Layout.preferredHeight: 20 }
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.step
                    ProjectDetailsStep {
                        framework: root.framework
                        projectName: root.projectName
                        parentFolder: root.parentFolder
                        packageName: root.packageName
                        javaVersion: root.javaVersion
                        onNameEdited: function(value) {
                            root.projectName = value
                        }
                        onPackageEdited: function(value) { root.packageName = value }
                        onJavaVersionEdited: function(value) { root.javaVersion = value }
                        onBrowseRequested: parentPicker.open()
                    }
                    ProjectOptionsStep {
                        framework: root.framework
                        architecture: root.architecture
                        dependencies: root.dependencies
                        initializeGit: root.initializeGit
                        onArchitectureEdited: function(value) { root.architecture = value }
                        onDependencyToggled: function(id, checked) { root.toggleDependency(id, checked) }
                        onGitToggled: function(value) { root.initializeGit = value }
                    }
                    ProjectReviewStep {
                        framework: root.framework
                        projectName: root.projectName
                        architecture: root.architecture
                        packageName: root.packageName
                        javaVersion: root.javaVersion
                        dependencies: root.dependencies
                        initializeGit: root.initializeGit
                        installNow: root.installNow
                        onInstallNowToggled: function(value) { root.installNow = value }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#41454f" }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 67
            color: "#24272e"
            radius: 12
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 19
                anchors.rightMargin: 19
                spacing: 10
                Label {
                    Layout.fillWidth: true
                    text: root.inlineError || (root.step === 0 && !root.detailsValid
                          ? "Select a destination and enter a valid project name." : "")
                    color: root.inlineError ? "#ff9b93" : "#8c95a8"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                WizardButton { text: "Cancel"; onClicked: root.reject() }
                WizardButton {
                    text: "Back"
                    enabled: root.step > 0
                    onClicked: { root.inlineError = ""; root.step-- }
                }
                WizardButton {
                    emphasized: true
                    enabled: root.canProceed && !root.controller.busy
                    text: root.step === 2 ? "Create Project" : "Next →"
                    implicitWidth: root.step === 2 ? 140 : 105
                    onClicked: {
                        root.inlineError = ""
                        if (root.step === 2) root.createProject()
                        else root.step++
                    }
                }
            }
        }
    }
}
