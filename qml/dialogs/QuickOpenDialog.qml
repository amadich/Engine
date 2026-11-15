import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Dialog {
    id: root

    required property ProjectController controller
    signal fileChosen(url file)

    property var indexedFiles: []
    readonly property int resultLimit: 80

    title: "Quick Open"
    modal: true
    popupType: Popup.Window
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: parent
    width: Math.min(580, parent.width - 32)
    padding: 12

    background: Rectangle {
        radius: 10
        color: Theme.colors.panel
        border.color: Theme.colors.border
    }

    onOpened: {
        indexedFiles = controller.quickOpenFiles()
        query.clear()
        updateResults()
        query.forceActiveFocus()
    }

    onClosed: indexedFiles = []

    function updateResults() {
        const term = query.text.trim().toLowerCase()
        const matches = []

        for (const file of indexedFiles) {
            const name = file.name.toLowerCase()
            const path = file.path.toLowerCase()

            if (!path.includes(term))
                continue

            const rank = name === term ? 0
                       : name.startsWith(term) ? 1
                       : name.includes(term) ? 2 : 3

            matches.push({ file: file, rank: rank })
        }

        matches.sort(function(a, b) {
            return a.rank - b.rank || a.file.path.localeCompare(b.file.path)
        })

        results.model = matches.slice(0, resultLimit)
        results.currentIndex = results.count > 0 ? 0 : -1
    }

    function moveSelection(offset) {
        if (results.count === 0)
            return

        results.currentIndex = Math.max(
            0, Math.min(results.count - 1, results.currentIndex + offset))
        results.positionViewAtIndex(results.currentIndex, ListView.Contain)
    }

    function choose(index) {
        if (index < 0 || index >= results.count)
            return

        const file = results.model[index].file.url
        close()
        Qt.callLater(function() { root.fileChosen(file) })
    }

    contentItem: ColumnLayout {
        spacing: 8

        TextField {
            id: query

            Layout.fillWidth: true
            placeholderText: "Search by file name or path…"
            Accessible.name: "Search project files"

            onTextChanged: {
                if (root.opened)
                    root.updateResults()
            }

            onAccepted: root.choose(results.currentIndex)

            Keys.onUpPressed: function(event) {
                root.moveSelection(-1)
                event.accepted = true
            }

            Keys.onDownPressed: function(event) {
                root.moveSelection(1)
                event.accepted = true
            }
        }

        ListView {
            id: results

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(count, 8) * 44
            visible: count > 0
            clip: true

            ScrollBar.vertical: ScrollBar {}

            delegate: ItemDelegate {
                id: result

                required property int index
                required property var modelData

                width: ListView.view.width
                height: 44
                highlighted: ListView.isCurrentItem
                onClicked: root.choose(index)

                background: Rectangle {
                    radius: 5
                    color: result.highlighted ? Theme.colors.selection
                         : result.hovered ? Theme.colors.hover
                         : "transparent"
                }

                contentItem: ColumnLayout {
                    spacing: 1

                    Label {
                        Layout.fillWidth: true
                        text: result.modelData.file.name
                        color: Theme.colors.text
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        text: result.modelData.file.path
                        color: Theme.colors.muted
                        font.pixelSize: 11
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: results.count === 0
            text: "No matching files"
            color: Theme.colors.muted
        }
    }
}