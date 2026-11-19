import QtQuick
import QtQuick.Controls
import QtWebView

Rectangle {
    id: root

    property url previewUrl: ""
    property bool devServerActive: false
    property bool dockActive: true

    color: Theme.colors.surface

    Label {
        anchors.centerIn: parent
        visible: !previewLoader.active
        text: root.devServerActive ? "Waiting for the development server…" : "Project preview"
        color: Theme.colors.text
        font.pixelSize: 24
    }

    Loader {
        id: previewLoader
        anchors.fill: parent
        active: root.dockActive && root.previewUrl.toString() !== ""

        sourceComponent: Component {
            WebView {
                url: root.previewUrl
            }
        }
    }
}