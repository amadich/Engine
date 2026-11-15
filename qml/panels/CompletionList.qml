import QtQuick
import QtQuick.Controls
import JeridiEngine

Rectangle {
    id: root

    property var suggestions: []
    property int selectedIndex: -1
    signal chosen(int index)

    visible: suggestions.length > 0
    radius: 6
    color: Theme.colors.surface
    border.color: Theme.colors.border
    clip: true

    ListView {
        id: list

        anchors.fill: parent
        anchors.margins: 3
        clip: true
        model: root.suggestions
        currentIndex: root.selectedIndex
        onCurrentIndexChanged: {
            if (currentIndex >= 0)
                positionViewAtIndex(currentIndex, ListView.Contain)
        }

        delegate: ItemDelegate {
            id: item
            required property int index
            required property string modelData

            width: list.width
            height: 26
            text: modelData
            focusPolicy: Qt.NoFocus

            contentItem: Label {
                text: item.text
                font.family: "Menlo"
                color: Theme.colors.text
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                radius: 4
                color: item.index === root.selectedIndex ? Theme.colors.selection
                       : item.hovered ? Theme.colors.hover : "transparent"
            }

            onClicked: root.chosen(item.index)
        }
    }
}
