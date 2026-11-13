import QtQuick
import QtQuick.Controls
import QtWebView

Rectangle {
    id: root

    property url previewUrl: ""
    property bool devServerActive: false

    color: "#0B1120"

    Label {
        anchors.centerIn: parent
        visible: !previewLoader.active
        text: root.devServerActive ? "Waiting for Vite…" : "Project preview"
        color: "#64748B"
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