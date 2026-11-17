import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import JeridiEngine

Item {
    id: welcome
    required property StartupService startup
    property string engineVersion: ""
    signal newProjectRequested()
    signal openFolderRequested()
    signal openProjectRequested(url folder)
    signal enterWorkspaceRequested()
    signal updateSettingsRequested()

    Column {
        x: 52
        y: 54
        spacing: 29
        Rectangle {
            width: 59; height: 59; radius: 15; color: "#1c1831"
            border.width: 1; border.color: "#c6abff"
            Text { anchors.centerIn: parent; text: "J"; color: "white"; font.family: "Arial"; font.pixelSize: 39; font.weight: Font.Black }
        }
        Column {
            spacing: -2
            Text { text: "JERIDI"; color: "white"; font.family: "Arial"; font.pixelSize: 44; font.weight: Font.Black; font.letterSpacing: -1.5 }
            Text { text: "ENGINE"; color: "white"; font.family: "Arial"; font.pixelSize: 44; font.weight: Font.Black; font.letterSpacing: -1.5 }
            Item { width: 1; height: 18 }
            Text { text: "v" + welcome.engineVersion; color: "#ffffff"; font.pixelSize: 23; font.weight: Font.DemiBold }
        }
    }
    Column {
        x: 52
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        spacing: 9
        Text { text: "CREATE MORE."; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 1.3 }
        Text { text: "BUILD  ·  DESIGN  ·  SHIP"; color: "#f6e9ff"; font.pixelSize: 10; font.letterSpacing: 2 }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.leftMargin: welcome.width * 0.39
        anchors.right: parent.right
        anchors.rightMargin: 48
        anchors.top: parent.top
        anchors.topMargin: 38
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Text { text: "J  /  HOME"; color: "#b3a4ff"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.5 }
            Item { Layout.fillWidth: true }
            Text { text: "v" + welcome.engineVersion; color: "#858a9f"; font.pixelSize: 12 }
            Rectangle {
                width: 38; height: 38; radius: 11
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                color: settingsHover.containsMouse ? "#343248" : "#222431"
                border.color: "#3d3e52"
                Text { anchors.centerIn: parent; text: "⚙"; font.pixelSize: 18; color: "#dcd9ec" }
                MouseArea {
                    id: settingsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: welcome.updateSettingsRequested()
                }
                ToolTip.visible: settingsHover.containsMouse
                ToolTip.text: "Update settings"
            }
        }

        Item { Layout.preferredHeight: 26 }
        Text { text: "Welcome to Jeridi."; color: "white"; font.family: "Arial"; font.pixelSize: 35; font.weight: Font.Bold }
        Item { Layout.preferredHeight: 8 }
        Text { text: "Start something new, or pick up where you left off."; color: "#999db2"; font.pixelSize: 13 }
        Item { Layout.preferredHeight: 27 }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 123
            spacing: 12
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: newMouse.containsMouse ? "#42305f" : "#302449"
                border.color: newMouse.containsMouse ? "#caadf9" : "#6b4b8f"
                Behavior on color { ColorAnimation { duration: 150 } }
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Text { text: "＋"; color: "#f2ccff"; font.pixelSize: 29 }
                    Text { text: "New project"; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold }
                    Text { text: "Start from scratch"; color: "#c3b3d2"; font.pixelSize: 11 }
                }
                Text { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; text: "↗"; color: "#bca1df"; font.pixelSize: 20 }
                MouseArea {
                    id: newMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: welcome.newProjectRequested()
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: openMouse.containsMouse ? "#2b354a" : "#232938"
                border.color: openMouse.containsMouse ? "#8ea9df" : "#474c63"
                Behavior on color { ColorAnimation { duration: 150 } }
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Text { text: "⌁"; color: "#a5c7fb"; font.pixelSize: 30; font.weight: Font.Bold }
                    Text { text: "Open project"; color: "white"; font.pixelSize: 15; font.weight: Font.DemiBold }
                    Text { text: "Browse your files"; color: "#a8b2c4"; font.pixelSize: 11 }
                }
                Text { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; text: "↗"; color: "#9eb2d4"; font.pixelSize: 20 }
                MouseArea {
                    id: openMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: welcome.openFolderRequested()
                }
            }
        }

        Item { Layout.preferredHeight: 25 }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "RECENT PROJECTS"; color: "#c6c9dc"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.5 }
            Item { Layout.fillWidth: true }
            Text { text: recentList.count + " PROJECTS"; color: "#71798f"; font.pixelSize: 10; font.letterSpacing: 1.2 }
        }
        Item { Layout.preferredHeight: 11 }
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 145
            radius: 13
            color: "#1b1d27"
            border.color: "#353747"
            clip: true
            ListView {
                id: recentList
                anchors.fill: parent
                anchors.margins: 5
                spacing: 2
                clip: true
                model: startup.recentProjects
                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 65
                    radius: 9
                    color: projectHover.containsMouse ? "#2b2e3f" : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 14
                        spacing: 13
                        Rectangle {
                            width: 38; height: 38; radius: 10; color: "#2d2d4c"
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            Text { anchors.centerIn: parent; text: "◇"; color: "#bca8ff"; font.pixelSize: 24 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: "#f9f8ff"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.path
                                color: "#858ca6"
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }
                        Text { text: "→"; color: projectHover.containsMouse ? "#f1e9ff" : "#72778b"; font.pixelSize: 19 }
                    }
                    MouseArea {
                        id: projectHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: welcome.openProjectRequested(
                            Qt.resolvedUrl("file://" + encodeURI(modelData.path)))
                    }
                }
            }
            Column {
                anchors.centerIn: parent
                visible: recentList.count === 0
                spacing: 9
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "◇"; color: "#8b78c3"; font.pixelSize: 29 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Your next great project starts here."; color: "#aeb4c8"; font.pixelSize: 13 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Create a new project or open an existing folder."; color: "#777f98"; font.pixelSize: 11 }
            }
        }

        Item { Layout.preferredHeight: 12 }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: startup.updateAvailable ? 48 : 30
            radius: 9
            color: startup.updateAvailable ? "#2b2536" : "transparent"
            border.color: startup.updateAvailable ? "#715579" : "transparent"
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: startup.updateAvailable ? 12 : 0
                anchors.rightMargin: startup.updateAvailable ? 12 : 0
                spacing: 8
                Rectangle {
                    Layout.preferredWidth: 7
                    Layout.preferredHeight: 7
                    radius: 3.5
                    color: startup.updateAvailable ? "#ffb78f" : "#64c5a7"
                }
                Text {
                    Layout.fillWidth: true
                    text: startup.updateAvailable ? "New version v" + startup.latestVersion + " available" : startup.status
                    color: startup.updateAvailable ? "#f4c6b3" : "#9098ac"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                Text {
                    visible: startup.updateAvailable
                    text: startup.checking ? "DOWNLOADING…" : "DOWNLOAD ↗"
                    color: downloadHover.containsMouse ? "white" : "#ffb4bf"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    MouseArea {
                        id: downloadHover
                        anchors.fill: parent
                        anchors.margins: -7
                        enabled: !startup.checking
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: startup.downloadUpdate()
                    }
                }
            }
        }
        Item { Layout.preferredHeight: 6 }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "JERIDI ENGINE  /  WORKSPACE LAUNCHER"; font.pixelSize: 9; color: "#74778d"; font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            Text {
                text: "ENTER EDITOR →"
                color: enterHover.containsMouse ? "#ffffff" : "#cfc6f0"
                font.pixelSize: 11
                font.weight: Font.Bold
                MouseArea {
                    id: enterHover
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: welcome.enterWorkspaceRequested()
                }
            }
        }
    }
}

