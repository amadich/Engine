import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import JeridiEngine

Popup {
    id: updatesPopup
    required property StartupService startup
    signal dismissed()
    x: Math.round(((parent ? parent.width : 570) - width) / 2)
    y: Math.round(((parent ? parent.height : 550) - height) / 2)
    width: Math.min((parent ? parent.width : 620) - 50, 570)
    height: 335
    padding: 27
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onOpened: manifestField.text = startup.manifestUrl()
    onClosed: dismissed()
    Overlay.modal: Rectangle { color: "#bd090b13" }
    background: Rectangle { radius: 17; color: "#232631"; border.color: "#4b4d65" }
    contentItem: ColumnLayout {
        spacing: 13
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Update settings"; color: "white"; font.pixelSize: 22; font.weight: Font.Bold }
            Item { Layout.fillWidth: true }
            Button { text: "✕"; flat: true; onClicked: updatesPopup.close() }
        }
        Text { text: "MANIFEST URL  ·  HTTPS"; color: "#b0b5cb"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.1 }
        TextField {
            id: manifestField
            Layout.fillWidth: true
            selectByMouse: true
            placeholderText: "https://example.com/releases/latest.json"
            color: "#ffffff"
            background: Rectangle { radius: 8; color: "#151821"; border.color: "#545773" }
        }
        Text {
            Layout.fillWidth: true
            text: startup.status
            color: "#b6bacc"
            font.pixelSize: 12
            elide: Text.ElideRight
        }
        ProgressBar { Layout.fillWidth: true; from: 0; to: 100; value: startup.progress; visible: startup.checking }
        RowLayout {
            Layout.fillWidth: true
            Button { text: "Save source"; onClicked: startup.setManifestUrl(manifestField.text) }
            Button {
                text: startup.checking ? "Checking…" : "Check now"
                enabled: !startup.checking
                onClicked: {
                    startup.setManifestUrl(manifestField.text)
                    startup.checkUpdates()
                }
            }
            Item { Layout.fillWidth: true }
        }
        Text {
            Layout.fillWidth: true
            text: startup.downloadPath === ""
                  ? "Updates are SHA-256 verified and installed manually."
                  : "Verified package saved to: " + startup.downloadPath
            color: startup.downloadPath === "" ? "#8e95aa" : "#9cddbd"
            font.pixelSize: 11
            wrapMode: Text.WrapAnywhere
        }
        Item { Layout.fillHeight: true }
    }
}

