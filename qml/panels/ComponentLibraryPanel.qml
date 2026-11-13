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
            text: "COMPONENT LIBRARY"
            color: "#E2E8F0"
            font.bold: true
        }

        TextField {
            Layout.fillWidth: true
            placeholderText: "Search components..."
            enabled: false
        }

        Label {
            Layout.fillWidth: true
            text: "Your components will appear here."
            color: "#94A3B8"
            wrapMode: Text.WordWrap
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
