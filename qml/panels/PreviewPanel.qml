import QtQuick
import QtQuick.Controls
import QtWebView

Rectangle {
    id: root

    property url previewUrl: ""
    property bool devServerActive: false

    color: Theme.colors.surface

    Label {
        anchors.centerIn: parent
        visible: !previewLoader.active
        text: root.devServerActive ? "Waiting for Vite…" : "Project preview"
        color: Theme.colors.text
        font.pixelSize: 24
    }

    Loader {
        id: previewLoader
        anchors.fill: parent
        active: root.previewUrl.toString() !== ""

        sourceComponent: Component {
            WebView {
                url: root.previewUrl
            }
        }
    }
}