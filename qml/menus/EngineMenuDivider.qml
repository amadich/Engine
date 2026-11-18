import QtQuick
import QtQuick.Controls
import JeridiEngine

MenuSeparator {
    implicitHeight: 10
    padding: 0
    contentItem: Rectangle {
        height: 1
        color: Theme.colors.border
        opacity: 0.72
        anchors.verticalCenter: parent.verticalCenter
    }
    background: Item { }
}
