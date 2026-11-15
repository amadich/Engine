import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.colors.surface
    visible: engineToolbar.showOutput

    function appendLog(message) {
        const needsNewLine = outputArea.length > 0
                             && !outputArea.text.endsWith("\n")
        const prefix = needsNewLine ? "\n" : ""
        root.appendOutput(prefix + message + "\n")
    }

    function appendOutput(text) {
        outputArea.insert(outputArea.length, text)
        outputArea.cursorPosition = outputArea.length
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: "OUTPUT"
            color: "#38BDF8"
            font.bold: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: outputArea
                readOnly: true
                selectByMouse: true
                textFormat: TextEdit.PlainText
                text: "Jeridi Engine ready.\n"
                color: Theme.colors.text
                font.family: "Menlo"
                wrapMode: TextEdit.Wrap

                background: Rectangle {
                    color: "transparent"
                }
            }
        }
    }
}
