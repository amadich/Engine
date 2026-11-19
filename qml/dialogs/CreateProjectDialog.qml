import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import JeridiEngine
import "ProjectProfiles.js" as Profiles
import "WizardStyle.js" as S

// Native IDE project wizard. Project creation and validation stay in C++.
// The UI only edits a declarative configuration map.
Dialog {
    id: root
    required property ProjectController controller

    property int step: 0
    property string framework: "react-vite"
    property string projectName: ""
    property url parentFolder: ""
    property string packageName: "com.example.demo"
    property string javaVersion: "17"
    property string description: ""
    property string serverPort: "3000"
    property string architecture: "standard"
    property var dependencies: []
    property bool initializeGit: false
    property bool installNow: false
    property string selectedDependency: "router"
    property string inlineError: ""

    readonly property bool detailsValid:
        /^[a-z][a-z0-9_-]{0,63}$/.test(projectName.trim())
        && parentFolder.toString() !== ""
        && (framework !== "spring-boot" || /^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$/.test(packageName.trim()))
        && (!Profiles.isBackend(framework) || (/^\d+$/.test(serverPort) && Number(serverPort) >= 1024 && Number(serverPort) <= 65535))

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(1240, parent ? parent.width - 24 : 1240)
    height: Math.min(780, parent ? parent.height - 24 : 780)
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape
    header: Item { implicitHeight: 0 }
    footer: Item { implicitHeight: 0 }
    background: Rectangle {
        color: S.window
        radius: 4
        border.width: 1
        border.color: "#52555a"
    }

    function selectFramework(id) {
        if (framework === id) return
        framework = id
        architecture = Profiles.isBackend(id) ? "layered" : "standard"
        dependencies = []
        serverPort = id === "spring-boot" ? "8080" : id === "express-ts" ? "4000" : "3000"
        const packages = Profiles.dependencyOptions(id)
        selectedDependency = packages.length ? packages[0].key : ""
        installNow = false
        inlineError = ""
        step = 0
    }

    function toggleDependency(id, checked) {
        const next = dependencies.slice()
        const index = next.indexOf(id)
        if (checked && index < 0) next.push(id)
        else if (!checked && index >= 0) next.splice(index, 1)
        dependencies = next
        selectedDependency = id
    }

    function createProject() {
        inlineError = ""
        if (!detailsValid) {
            step = 0
            inlineError = "Enter a valid name, location, Java package and server port."
            return
        }
        const success = controller.createConfiguredProject({
            name: projectName.trim(),
            parentFolder: parentFolder,
            framework: framework,
            architecture: architecture,
            packageName: packageName.trim(),
            javaVersion: javaVersion,
            description: description.trim(),
            serverPort: Profiles.isBackend(framework) ? Number(serverPort) : 0,
            dependencies: dependencies,
            initializeGit: initializeGit
        })
        if (!success) {
            inlineError = controller.lastProjectError
            return
        }
        root.close()
        if (installNow && framework !== "html") controller.installDependencies()
    }

    onOpened: { step = 0; inlineError = "" }

    FolderDialog {
        id: parentPicker
        title: "Choose the parent folder for the new project"
        onAccepted: root.parentFolder = selectedFolder
    }

    contentItem: ColumnLayout {
        spacing: 0
        // Compact title bar: native-tool feel, no decorative cards.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: S.surface
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 13
                spacing: 10
                Image {
                    source: "qrc:/engine/assets/icons/package.svg"
                    sourceSize.width: 22
                    sourceSize.height: 22
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    fillMode: Image.PreserveAspectFit
                }
                Label { text: "New Project"; color: S.title; font.pixelSize: 16; font.weight: Font.DemiBold }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 17; color: S.line; Layout.leftMargin: 7; Layout.rightMargin: 5 }
                Label { text: "JERIDI ENGINE  /  PROJECT GENERATOR"; color: S.muted; font.pixelSize: 10; font.letterSpacing: 0.6 }
                Item { Layout.fillWidth: true }
                Label { text: "v" + Qt.application.version; color: S.faint; font.pixelSize: 10 }
                WizardActionButton {
                    text: "✕"
                    Layout.preferredWidth: 28
                    implicitWidth: 28
                    onClicked: root.reject()
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line }
        // Main body: template explorer | settings/package manager | contextual inspector.
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            ProjectTypeSidebar {
                Layout.preferredWidth: 213
                Layout.fillHeight: true
                supportedFrameworks: root.controller.supportedProjectFrameworks || []
                framework: root.framework
                onFrameworkSelected: function(id) { root.selectFramework(id) }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: S.line }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: S.window
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 12
                        spacing: 3
                        Repeater {
                            model: ["PROJECT", "STRUCTURE", "PACKAGES", "REVIEW"]
                            Item {
                                id: tab
                                required property int index
                                required property string modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Rectangle {
                                    anchors.fill: parent
                                    color: tab.index === root.step ? "#34383d" : "transparent"
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 2
                                    color: S.accent
                                    visible: tab.index === root.step
                                }
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 7
                                    Label {
                                        text: String(tab.index + 1)
                                        color: tab.index === root.step ? S.accent : S.faint
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                    Label {
                                        text: tab.modelData
                                        color: tab.index === root.step ? S.title : S.muted
                                        font.pixelSize: 10
                                        font.weight: tab.index === root.step ? Font.DemiBold : Font.Normal
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: tab.index < root.step
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: { root.inlineError = ""; root.step = tab.index }
                                }
                            }
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line }
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 17
                    Layout.rightMargin: 17
                    Layout.topMargin: 14
                    Layout.bottomMargin: 10
                    currentIndex: root.step
                    ProjectDetailsStep {
                        framework: root.framework
                        projectName: root.projectName
                        parentFolder: root.parentFolder
                        packageName: root.packageName
                        javaVersion: root.javaVersion
                        description: root.description
                        serverPort: root.serverPort
                        onNameEdited: function(value) { root.projectName = value }
                        onPackageEdited: function(value) { root.packageName = value }
                        onJavaVersionEdited: function(value) { root.javaVersion = value }
                        onDescriptionEdited: function(value) { root.description = value }
                        onServerPortEdited: function(value) { root.serverPort = value }
                        onBrowseRequested: parentPicker.open()
                    }
                    ProjectOptionsStep {
                        framework: root.framework
                        architecture: root.architecture
                        initializeGit: root.initializeGit
                        onArchitectureEdited: function(value) { root.architecture = value }
                        onGitToggled: function(value) { root.initializeGit = value }
                    }
                    ProjectDependenciesStep {
                        framework: root.framework
                        dependencies: root.dependencies
                        selectedDependency: root.selectedDependency
                        onDependencyToggled: function(id, checked) { root.toggleDependency(id, checked) }
                        onPackageFocused: function(id) { root.selectedDependency = id }
                    }
                    ProjectReviewStep {
                        framework: root.framework
                        projectName: root.projectName
                        parentFolder: root.parentFolder
                        architecture: root.architecture
                        packageName: root.packageName
                        javaVersion: root.javaVersion
                        description: root.description
                        serverPort: root.serverPort
                        dependencies: root.dependencies
                        initializeGit: root.initializeGit
                        installNow: root.installNow
                        onInstallNowToggled: function(value) { root.installNow = value }
                    }
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: S.line }
            ProjectWizardInspector {
                Layout.preferredWidth: 242
                Layout.fillHeight: true
                framework: root.framework
                projectName: root.projectName
                architecture: root.architecture
                packageName: root.packageName
                javaVersion: root.javaVersion
                dependencies: root.dependencies
                step: root.step
                selectedDependency: root.selectedDependency
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 55
            color: S.surface
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 8
                Rectangle {
                    Layout.preferredWidth: 7; Layout.preferredHeight: 7
                    radius: 4
                    color: root.inlineError ? S.error : root.detailsValid ? S.success : S.warning
                }
                Label {
                    Layout.fillWidth: true
                    text: root.inlineError || (root.detailsValid
                        ? "Ready  ·  " + Profiles.displayName(root.framework) + "  ·  " + root.dependencies.length + " optional packages"
                        : "Enter a valid project name and choose a location to continue.")
                    color: root.inlineError ? S.error : S.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                WizardActionButton { text: "Cancel"; onClicked: root.reject() }
                WizardActionButton {
                    text: "Back"
                    enabled: root.step > 0
                    onClicked: { root.inlineError = ""; root.step-- }
                }
                WizardActionButton {
                    primary: true
                    implicitWidth: root.step === 3 ? 137 : 96
                    text: root.step === 3 ? "Create Project" : "Next  →"
                    enabled: (root.step !== 0 || root.detailsValid) && !root.controller.busy
                    onClicked: {
                        root.inlineError = ""
                        if (root.step === 3) root.createProject()
                        else root.step++
                    }
                }
            }
        }
    }
}
