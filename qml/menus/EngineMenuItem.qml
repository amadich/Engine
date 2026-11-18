import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Shared menu row: icon/check, action, optional shortcut, disabled and hover states.
MenuItem {
    id: item
    property string iconName: ""
    property string shortcutLabel: ""
    property bool destructive: false

    implicitWidth: 272
    implicitHeight: 29
    padding: 0
    leftPadding: 9
    rightPadding: 9
    hoverEnabled: true

    indicator: Item { implicitWidth: 0; implicitHeight: 0 }

    contentItem: RowLayout {
        spacing: 9

        Item {
            Layout.preferredWidth: 17
            Layout.preferredHeight: 18

            Image {
                anchors.centerIn: parent
                width: 15
                height: 15
                source: item.iconName ? "qrc:/engine/assets/icons/" + item.iconName : ""
                sourceSize: Qt.size(30, 30)
                fillMode: Image.PreserveAspectFit
                visible: item.iconName !== "" && !(item.checkable && item.checked)
                opacity: item.enabled ? 0.9 : 0.35
            }
            Text {
                anchors.centerIn: parent
                text: "✓"
                visible: item.checkable && item.checked
                color: Theme.colors.accent
                font.pixelSize: 13
                font.bold: true
            }
        }

        Label {
            Layout.fillWidth: true
            text: item.text
            elide: Text.ElideRight
            font.pixelSize: 12
            color: !item.enabled ? Theme.colors.disabled
                 : item.destructive ? Theme.colors.error : Theme.colors.text
            verticalAlignment: Text.AlignVCenter
        }

        Label {
            visible: item.shortcutLabel.length > 0
            text: item.shortcutLabel
            font.pixelSize: 10
            font.family: Qt.platform.os === "osx" ? "Helvetica Neue" : "Sans Serif"
            color: item.enabled ? Theme.colors.muted : Theme.colors.disabled
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        radius: 4
        color: item.enabled && (item.highlighted || item.hovered || item.down)
               ? Theme.colors.selection : "transparent"
    }
}
