import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root
    color: Theme.colors.panel
    implicitHeight: 43

    property string searchText: ""
    property bool frozen: false
    property bool followLatest: true
    property bool wrapLines: true
    property bool showTimes: true
    property bool hasOutput: false
    property bool hasVisibleOutput: false

    signal searchChanged(string value)
    signal pauseRequested()
    signal followRequested()
    signal copyAllRequested()
    signal copyVisibleRequested()
    signal clearRequested()
    signal wrapRequested()
    signal timestampsRequested()
    signal resetRequested()

    readonly property bool narrow: width < 470

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 9
        anchors.rightMargin: 8
        spacing: 5

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 65
            Layout.preferredHeight: 29
            radius: 5
            color: Theme.colors.surface
            border.width: 1
            border.color: searchInput.activeFocus ? Theme.colors.accent : Theme.colors.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 4
                spacing: 5

                Image {
                    Layout.preferredWidth: 13
                    Layout.preferredHeight: 13
                    source: "qrc:/engine/assets/icons/search.svg"
                    sourceSize: Qt.size(26, 26)
                }
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: root.searchText
                    placeholderText: "Search output, paths, errors…"
                    placeholderTextColor: Theme.colors.muted
                    font.pixelSize: 10
                    color: Theme.colors.text
                    padding: 0
                    selectByMouse: true
                    background: Item {}
                    onTextEdited: root.searchChanged(text)
                    Keys.onEscapePressed: root.searchChanged("")
                }
                OutputIconButton {
                    visible: root.searchText.length > 0
                    Layout.preferredWidth: visible ? 19 : 0
                    Layout.preferredHeight: 19
                    iconSize: 10
                    iconSource: "qrc:/engine/assets/icons/close.svg"
                    hint: "Clear search"
                    onClicked: root.searchChanged("")
                }
            }
        }

        OutputIconButton {
            visible: !root.narrow
            iconSource: "qrc:/engine/assets/icons/copy.svg"
            hint: "Copy retained output"
            enabled: root.hasOutput
            onClicked: root.copyAllRequested()
        }

        Button {
            id: pauseButton
            implicitWidth: 29
            implicitHeight: 27
            padding: 0
            hoverEnabled: true
            ToolTip.visible: hovered
            ToolTip.text: root.frozen ? "Resume live view" : "Freeze view (keep capturing)"
            ToolTip.delay: 420
            contentItem: Label {
                text: root.frozen ? "▶" : "Ⅱ"
                font.pixelSize: 13
                font.bold: true
                color: root.frozen ? "#E6B86B" : Theme.colors.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: 5
                color: root.frozen ? Theme.colors.selection
                     : pauseButton.hovered ? Theme.colors.hover : "transparent"
                border.width: root.frozen ? 1 : 0
                border.color: Theme.colors.accent
            }
            onClicked: root.pauseRequested()
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }

        Button {
            id: followButton
            implicitWidth: 29
            implicitHeight: 27
            padding: 0
            hoverEnabled: true
            ToolTip.visible: hovered
            ToolTip.text: root.followLatest ? "Auto-scroll enabled" : "Follow newest events"
            ToolTip.delay: 420
            contentItem: Label {
                text: "↓"
                font.pixelSize: 17
                color: root.followLatest ? Theme.colors.accent : Theme.colors.muted
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: 5
                color: root.followLatest ? Theme.colors.selection
                     : followButton.hovered ? Theme.colors.hover : "transparent"
                border.width: root.followLatest ? 1 : 0
                border.color: Theme.colors.accent
            }
            onClicked: root.followRequested()
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }

        OutputIconButton {
            visible: !root.narrow
            iconSource: "qrc:/engine/assets/icons/trash.svg"
            hint: "Clear output only — no project files are removed"
            enabled: root.hasOutput
            onClicked: root.clearRequested()
        }

        Button {
            id: optionsButton
            implicitWidth: 28
            implicitHeight: 27
            padding: 0
            hoverEnabled: true
            ToolTip.visible: hovered
            ToolTip.text: "Output options"
            ToolTip.delay: 420
            contentItem: Label {
                text: "⋯"
                font.pixelSize: 19
                color: Theme.colors.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: 5
                color: optionsButton.hovered ? Theme.colors.hover : "transparent"
            }
            onClicked: options.open()
            HoverHandler { cursorShape: Qt.PointingHandCursor }

            Menu {
                id: options
                y: parent.height
                width: 225
                MenuItem { text: "Copy filtered messages"; enabled: root.hasVisibleOutput && !root.frozen; onTriggered: root.copyVisibleRequested() }
                MenuItem { text: "Copy all retained messages"; enabled: root.hasOutput; onTriggered: root.copyAllRequested() }
                MenuSeparator {}
                MenuItem { text: (root.wrapLines ? "✓  " : "    ") + "Wrap long lines"; onTriggered: root.wrapRequested() }
                MenuItem { text: (root.showTimes ? "✓  " : "    ") + "Show timestamps"; onTriggered: root.timestampsRequested() }
                MenuItem { text: (root.followLatest ? "✓  " : "    ") + "Follow latest events"; onTriggered: root.followRequested() }
                MenuSeparator {}
                MenuItem { text: "Reset search and filter"; onTriggered: root.resetRequested() }
                MenuItem { text: "Clear console"; enabled: root.hasOutput; onTriggered: root.clearRequested() }
            }
        }
    }
}
