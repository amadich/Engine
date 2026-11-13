import QtQuick
import QtQuick.Controls
import JeridiEngine

SplitView {
    id: root
    property url previewUrl: ""
    property bool devServerActive: false


    orientation: Qt.Horizontal

    ComponentLibraryPanel {
        SplitView.preferredWidth: 260
        SplitView.minimumWidth: 180
    }

    PreviewPanel {
        SplitView.fillWidth: true
        SplitView.minimumWidth: 360
        previewUrl: root.previewUrl
        devServerActive: root.devServerActive
    }

    InspectorPanel {
        SplitView.preferredWidth: 280
        SplitView.minimumWidth: 200
    }
}
