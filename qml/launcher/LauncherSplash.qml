import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import JeridiEngine

Item {
    id: splash
    required property StartupService startup
    property string engineVersion: ""
    signal skipRequested()

    Row {
        x: 50
        y: 48
        spacing: 12
        Rectangle {
            width: 44; height: 44; radius: 12
            color: "#171527"
            Text {
                anchors.centerIn: parent
                text: "J"
                font.family: "Arial"
                font.pixelSize: 30
                font.weight: Font.Black
                color: "#ffffff"
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { text: "JERIDI"; color: "white"; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 2 }
            Text { text: "ENGINE"; color: "#f8e8ff"; font.pixelSize: 10; font.letterSpacing: 3 }
        }
    }

    Column {
        x: 50
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        spacing: 10
        Text { text: "MAKE WHAT'S NEXT."; color: "white"; font.pixelSize: 18; font.weight: Font.DemiBold; font.letterSpacing: 1 }
        Text { text: "IDEAS  /  CODE  /  CREATION"; color: "#fff0fc"; font.pixelSize: 10; font.letterSpacing: 2 }
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: Math.max(520, splash.width * 0.535)
        anchors.right: parent.right
        anchors.rightMargin: 44
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -48
        spacing: 3

        Text { text: "DEVELOPMENT ENVIRONMENT"; color: "#afb0c5"; font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 2.2 }
        Item { width: 1; height: 10 }
        Rectangle { width: 52; height: 3; color: "#ff7c8c" }
        Item { width: 1; height: 14 }
        Text {
            text: "JERIDI"
            color: "#ffffff"
            font.family: "Arial"
            font.pixelSize: Math.min(82, splash.width * 0.071)
            font.weight: Font.Black
            font.letterSpacing: -2
        }
        Text {
            text: "ENGINE"
            color: "#ffffff"
            font.family: "Arial"
            font.pixelSize: Math.min(82, splash.width * 0.071)
            font.weight: Font.Black
            font.letterSpacing: -2
        }
        Item { width: 1; height: 16 }
        Row {
            spacing: 18
            Text { text: splash.engineVersion; color: "#ff8c9f"; font.family: "Arial"; font.pixelSize: 52; font.weight: Font.Bold }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text { text: "DESKTOP"; color: "#a5a6b9"; font.pixelSize: 10; font.letterSpacing: 1.5 }
                Text { text: "RELEASE"; color: "#a5a6b9"; font.pixelSize: 10; font.letterSpacing: 1.5 }
            }
        }
        Item { width: 1; height: 15 }
        Text {
            text: "Build beautiful things. One project at a time."
            width: parent.width
            wrapMode: Text.WordWrap
            color: "#b1b3c3"
            font.pixelSize: 14
        }
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: Math.max(520, splash.width * 0.535)
        anchors.right: parent.right
        anchors.rightMargin: 56
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        spacing: 12
        Row {
            width: parent.width
            Text {
                text: startup.checking ? "CHECKING FOR UPDATES" : "PREPARING YOUR WORKSPACE"
                width: parent.width - 55
                color: "#b4b7c9"
                font.pixelSize: 10
                font.letterSpacing: 1.6
            }
            Text { text: startup.progress + "%"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.Bold }
        }
        Rectangle {
            width: parent.width; height: 4; radius: 2; color: "#343442"
            Rectangle {
                height: parent.height
                radius: 2
                width: parent.width * Math.max(0, Math.min(1, startup.progress / 100))
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#ff8c81" }
                    GradientStop { position: 1; color: "#a075fa" }
                }
                Behavior on width { NumberAnimation { duration: 540; easing.type: Easing.OutCubic } }
            }
        }
        Row {
            width: parent.width
            Text {
                text: startup.status
                width: parent.width - 126
                color: "#9698ad"
                elide: Text.ElideRight
                font.pixelSize: 11
            }
            Text {
                text: "CONTINUE →"
                color: skipArea.containsMouse ? "white" : "#b5b8cf"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                MouseArea {
                    id: skipArea
                    anchors.fill: parent
                    anchors.margins: -7
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: splash.skipRequested()
                }
            }
        }
    }
}

