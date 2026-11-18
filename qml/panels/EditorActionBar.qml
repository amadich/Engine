import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    property string path: ""
    property string language: ""
    property bool imageFile: false
    property int importCount: 0
    property int symbolCount: 0
    property bool navigationVisible: false
    signal importsRequested()
    signal symbolsRequested()
    signal findRequested()
    signal replaceRequested()
    signal goToLineRequested()
    signal goToImportRequested()

    color: Theme.colors.control
    implicitHeight: 34
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.colors.border }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 7
        Image { source: "qrc:/engine/assets/icons/folder.svg"; Layout.preferredWidth: 13; Layout.preferredHeight: 13 }
        Label {
            text: root.path
            Layout.fillWidth: true
            color: Theme.colors.muted
            font.pixelSize: 11
            elide: Text.ElideMiddle
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle { width: 1; height: 17; color: Theme.colors.border }
        ToolButton {
            text: "Imports " + root.importCount
            visible: !root.imageFile
            implicitHeight: 28
            font.pixelSize: 11
            onClicked: root.importsRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Inspect local imports and open referenced files (F12)"
        }
        ToolButton {
            text: "Outline " + root.symbolCount
            visible: !root.imageFile
            implicitHeight: 28
            font.pixelSize: 11
            onClicked: root.symbolsRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Navigate symbols in this file"
        }
        ToolButton {
            text: "Find"
            visible: !root.imageFile
            implicitHeight: 28
            font.pixelSize: 11
            onClicked: root.findRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Search in file (Ctrl+F)"
        }
        ToolButton {
            text: "Ln"
            visible: !root.imageFile
            implicitHeight: 28
            font.pixelSize: 11
            onClicked: root.goToLineRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Go to line (Ctrl+L)"
        }
    }
}
