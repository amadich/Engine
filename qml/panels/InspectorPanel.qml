import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var fileDetails: ({})

    color: "#111827"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Label {
            text: "INSPECTOR"
            color: "#E2E8F0"
            font.bold: true
        }

        Label {
            Layout.fillWidth: true
            visible: !root.fileDetails.name && !root.fileDetails.error
            text: "Select a file in Project Files."
            color: "#94A3B8"
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            visible: !!root.fileDetails.name
            text: root.fileDetails.name || ""
            color: "#E2E8F0"
            font.bold: true
            wrapMode: Text.Wrap
        }

        Label {
            Layout.fillWidth: true
            visible: !!root.fileDetails.path
            text: root.fileDetails.path || ""
            color: "#94A3B8"
            wrapMode: Text.Wrap
        }

        Label {
            visible: root.fileDetails.size !== undefined
            text: visible ? root.fileDetails.size + " bytes" : ""
            color: "#94A3B8"
        }

        Label {
            Layout.fillWidth: true
            visible: !!root.fileDetails.error
            text: root.fileDetails.error || ""
            color: "#FCA5A5"
            wrapMode: Text.WordWrap
        }

        Image {
            id: imagePreview

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.fileDetails.kind === "image"
            source: visible ? root.fileDetails.imageUrl : ""
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 640
            sourceSize.height: 640
            asynchronous: true
        }

        Label {
            visible: imagePreview.visible && imagePreview.status === Image.Error
            text: "Could not display this image."
            color: "#FCA5A5"
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.fileDetails.kind === "text"
            clip: true

            TextArea {
                readOnly: true
                selectByMouse: true
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.Wrap
                font.family: "monospace"
                color: "#CBD5E1"
                text: root.fileDetails.text || ""
            }
        }

        Label {
            visible: root.fileDetails.truncated === true
            text: "Showing the first 64 KiB."
            color: "#94A3B8"
        }

        Item {
            Layout.fillHeight: true
            visible: root.fileDetails.kind !== "image"
                     && root.fileDetails.kind !== "text"
        }
    }
}