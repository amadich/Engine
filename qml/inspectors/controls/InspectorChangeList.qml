import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Shared read-only summary of which supported configuration fields have changed.
ColumnLayout {
    id: root
    property var changes: []
    Layout.fillWidth: true
    spacing: 5

    Repeater {
        model: root.changes
        RowLayout {
            required property string modelData
            Layout.fillWidth: true
            spacing: 6
            Image {
                source: "qrc:/engine/assets/icons/file.svg"
                sourceSize: Qt.size(24, 24)
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
            }
            Label {
                Layout.fillWidth: true
                text: modelData
                font.pixelSize: 10
                color: Theme.colors.text
                elide: Text.ElideRight
            }
        }
    }
    Label {
        Layout.fillWidth: true
        text: "Apply saves these edits; Reload discards them."
        font.pixelSize: 9
        color: Theme.colors.muted
        wrapMode: Text.WordWrap
    }
}
