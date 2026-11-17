import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import JeridiEngine

// Coordinator only. Visual parts are in qml/launcher/.
Rectangle {
    id: root

    required property StartupService startup
    signal openProjectRequested(url folder)
    signal newProjectRequested()
    signal enterWorkspaceRequested()

    color: "#101117"
    clip: true

    property bool ready: false
    property bool showSettings: false
    property bool minimumSplashElapsed: false
    readonly property string engineVersion: startup.currentVersion()

    function proceedWhenReady() {
        if (!ready && minimumSplashElapsed && !startup.checking
                && startup.progress >= 100 && !welcomeDelay.running)
            welcomeDelay.start()
    }

    Component.onCompleted: {
        splashHold.start()
        startup.checkUpdates()
    }

    onShowSettingsChanged: {
        if (showSettings && !updatesPopup.opened)
            updatesPopup.open()
        else if (!showSettings && updatesPopup.opened)
            updatesPopup.close()
    }

    Connections {
        target: startup
        function onChanged() { root.proceedWhenReady() }
    }

    Timer {
        id: splashHold
        interval: 1750
        onTriggered: {
            root.minimumSplashElapsed = true
            root.proceedWhenReady()
        }
    }

    Timer {
        id: welcomeDelay
        interval: 380
        onTriggered: root.ready = true
    }

    FolderDialog {
        id: projectPicker
        title: "Open a project folder"
        onAccepted: root.openProjectRequested(selectedFolder)
    }

    LauncherArtwork {
        anchors.fill: parent
        compact: root.ready
    }

    LauncherSplash {
        anchors.fill: parent
        visible: !root.ready
        startup: root.startup
        engineVersion: root.engineVersion
        onSkipRequested: root.ready = true
    }

    LauncherWelcome {
        anchors.fill: parent
        visible: root.ready
        startup: root.startup
        engineVersion: root.engineVersion
        onNewProjectRequested: root.newProjectRequested()
        onOpenFolderRequested: projectPicker.open()
        onOpenProjectRequested: function(folder) {
            root.openProjectRequested(folder)
        }
        onEnterWorkspaceRequested: root.enterWorkspaceRequested()
        onUpdateSettingsRequested: root.showSettings = true
    }

    LauncherUpdatesPopup {
        id: updatesPopup
        parent: root
        startup: root.startup
        onDismissed: root.showSettings = false
    }
}

