import QtQuick
import QtQuick.Controls
import JeridiEngine

SplitView {
    orientation: Qt.Horizontal

    ComponentLibraryPanel {
        SplitView.preferredWidth: 260
        SplitView.minimumWidth: 180
    }

    PreviewPanel {
        SplitView.fillWidth: true
        SplitView.minimumWidth: 360
    }

    InspectorPanel {
        SplitView.preferredWidth: 280
        SplitView.minimumWidth: 200
    }
}
