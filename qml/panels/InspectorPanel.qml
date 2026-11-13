import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: "#111827"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Label {
            text: "INSPECTOR"
            color: "#E2E8F0"
            font.bold: true
        }

        Label {
            Layout.fillWidth: true
            text: "Select a component to edit its properties."
            color: "#94A3B8"
            wrapMode: Text.WordWrap
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
