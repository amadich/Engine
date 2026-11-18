import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Dialog {
    id: root
    required property StartupService startup
    title: "Engine Updates"
    modal: true
    popupType: Popup.Window
    anchors.centerIn: parent
    width: Math.min(470, parent.width - 32)
    padding: 18
    standardButtons: Dialog.Close
    background: Rectangle { color: Theme.colors.panel; border.color: Theme.colors.border; radius: 7 }
    contentItem: ColumnLayout {
        spacing: 13
        RowLayout {
            spacing: 12
            Image { source: "qrc:/engine/assets/icons/server_square_update.svg"; Layout.preferredWidth: 30; Layout.preferredHeight: 30 }
            ColumnLayout {
                spacing: 3
                Label { text: "Jeridi Engine v" + root.startup.currentVersion(); color: Theme.colors.text; font.bold: true; font.pixelSize: 15 }
                Label { text: "Verified update channel"; color: Theme.colors.muted; font.pixelSize: 11 }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }
        Label { Layout.fillWidth: true; text: root.startup.status; color: Theme.colors.text; wrapMode: Text.WordWrap; font.pixelSize: 12 }
        ProgressBar {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: root.startup.progress
            visible: root.startup.checking
        }
        Label {
            Layout.fillWidth: true
            text: root.startup.manifestUrl() ? "Source: " + root.startup.manifestUrl() : "No update source configured. Set the HTTPS manifest URL in the Welcome screen's update settings."
            color: Theme.colors.muted
            wrapMode: Text.WrapAnywhere
            font.pixelSize: 10
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Button { text: "Check Again"; enabled: !root.startup.checking; onClicked: root.startup.checkUpdates() }
            Button { text: "Download Verified Update"; visible: root.startup.updateAvailable; enabled: !root.startup.checking; onClicked: root.startup.downloadUpdate() }
            Item { Layout.fillWidth: true }
        }
        Label {
            visible: root.startup.downloadPath !== ""
            text: "Downloaded to: " + root.startup.downloadPath + "\nInstall the verified package manually."
            color: Theme.colors.muted
            wrapMode: Text.WrapAnywhere
            font.pixelSize: 11
        }
    }
}
