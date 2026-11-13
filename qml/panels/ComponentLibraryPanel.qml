import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool canAddComponent: false
    signal addButtonRequested()

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

            Button {
                Layout.fillWidth: true
                text: "Add Button"
                enabled: root.canAddComponent
                onClicked: root.addButtonRequested()
            }

            color: "#94A3B8"
            wrapMode: Text.WordWrap
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
