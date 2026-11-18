import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    property var imports: []
    property var symbols: []
    property string mode: "imports"
    signal openImportRequested(var fileUrl)
    signal goToLineRequested(int line)
    signal closeRequested()
    signal modeRequested(string newMode)
    color: Theme.colors.panel
    Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: Theme.colors.border }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            color: Theme.colors.control
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 5
                spacing: 4
                ToolButton {
                    text: "IMPORTS"
                    font.pixelSize: 10
                    font.bold: root.mode === "imports"
                    onClicked: root.modeRequested("imports")
                }
                ToolButton {
                    text: "OUTLINE"
                    font.pixelSize: 10
                    font.bold: root.mode === "symbols"
                    onClicked: root.modeRequested("symbols")
                }
                Item { Layout.fillWidth: true }
                ToolButton { text: "×"; implicitWidth: 25; onClicked: root.closeRequested() }
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.topMargin: 10
            Layout.bottomMargin: 6
            text: root.mode === "imports" ? "FILE REFERENCES  ·  " + root.imports.length
                                            : "SYMBOLS  ·  " + root.symbols.length
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 0.6
            color: Theme.colors.muted
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.mode === "imports" ? root.imports : root.symbols
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: ItemDelegate {
                id: row
                required property var modelData
                width: list.width
                height: 54
                hoverEnabled: true
                onClicked: {
                    if (root.mode === "imports") {
                        if (modelData.status === "local") root.openImportRequested(modelData.url)
                    } else root.goToLineRequested(modelData.line)
                }
                background: Rectangle { color: row.hovered ? Theme.colors.hover : "transparent" }
                contentItem: ColumnLayout {
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Rectangle {
                            Layout.preferredWidth: 7; Layout.preferredHeight: 7; radius: 4
                            color: root.mode !== "imports" ? "#76A7E8"
                                   : modelData.status === "local" ? "#24B989"
                                   : modelData.status === "missing" ? "#D89A47" : "#8390A2"
                        }
                        Label {
                            Layout.fillWidth: true
                            text: root.mode === "imports" ? modelData.specifier : modelData.name
                            color: Theme.colors.text
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: 14
                        text: root.mode === "imports"
                              ? (modelData.status === "local" ? modelData.path
                                : modelData.status === "missing" ? "Local target not found" : "External dependency")
                              : modelData.kind + "  ·  line " + modelData.line
                        color: Theme.colors.muted
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                    }
                }
                ToolTip.visible: hovered && root.mode === "imports"
                ToolTip.text: root.mode === "imports" && modelData.status === "local"
                              ? "Open " + modelData.path : "Only local project files can be opened"
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: 14
            visible: list.count === 0
            text: root.mode === "imports" ? "No imports detected in this file."
                                            : "No symbols detected in this file."
            color: Theme.colors.muted
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 29
            color: Theme.colors.control
            Label {
                anchors.centerIn: parent
                text: root.mode === "imports" ? "Local references are clickable" : "Select a symbol to jump"
                font.pixelSize: 10
                color: Theme.colors.muted
            }
        }
    }
}
