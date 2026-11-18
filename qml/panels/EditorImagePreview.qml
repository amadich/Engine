import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    property url fileUrl: ""
    property string fileName: ""
    property string relativePath: ""
    property real imageBytes: 0
    property bool fitToView: true
    property real zoom: 1
    color: Theme.colors.canvas

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: Theme.colors.control
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 9
                Image { source: "qrc:/engine/assets/icons/image.svg"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                Label { text: "IMAGE VIEWER"; color: Theme.colors.text; font.bold: true; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Label { text: Math.round(root.imageBytes / 1024) + " KB"; color: Theme.colors.muted; font.pixelSize: 10 }
                ToolButton {
                    text: "−"
                    onClicked: { root.fitToView = false; root.zoom = Math.max(0.1, root.zoom / 1.25) }
                    ToolTip.text: "Zoom out"
                    ToolTip.visible: hovered
                }
                ToolButton {
                    text: "100%"
                    onClicked: { root.fitToView = false; root.zoom = 1 }
                    ToolTip.text: "Actual size"
                    ToolTip.visible: hovered
                }
                ToolButton {
                    text: "+"
                    onClicked: { root.fitToView = false; root.zoom = Math.min(8, root.zoom * 1.25) }
                    ToolTip.text: "Zoom in"
                    ToolTip.visible: hovered
                }
                ToolButton {
                    text: "Fit"
                    onClicked: root.fitToView = true
                    ToolTip.text: "Fit to editor"
                    ToolTip.visible: hovered
                }
            }
        }
        Rectangle {
            id: viewport
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.colors.canvas
            clip: true
            Flickable {
                id: imageScroll
                anchors.fill: parent
                clip: true
                interactive: !root.fitToView
                contentWidth: Math.max(width, imageView.width)
                contentHeight: Math.max(height, imageView.height)
                ScrollBar.horizontal: ScrollBar { policy: root.fitToView ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded }
                ScrollBar.vertical: ScrollBar { policy: root.fitToView ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded }
                Image {
                    id: imageView
                    x: Math.max(0, (imageScroll.contentWidth - width) / 2)
                    y: Math.max(0, (imageScroll.contentHeight - height) / 2)
                    source: root.fileUrl
                    asynchronous: true
                    cache: false
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                    width: root.fitToView ? Math.max(1, imageScroll.width - 44)
                                          : Math.max(1, implicitWidth * root.zoom)
                    height: root.fitToView ? Math.max(1, imageScroll.height - 44)
                                           : Math.max(1, implicitHeight * root.zoom)
                }
            }
            Label {
                anchors.centerIn: parent
                visible: imageView.status === Image.Error
                text: "Preview unavailable for this image format."
                color: Theme.colors.muted
                font.pixelSize: 12
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: Theme.colors.control
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                Label { text: root.fileName; color: Theme.colors.text; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
                Label {
                    text: imageView.status === Image.Ready
                          ? imageView.sourceSize.width + " × " + imageView.sourceSize.height + " px"
                          : "Loading preview…"
                    color: Theme.colors.muted
                    font.pixelSize: 10
                }
            }
        }
    }
}
