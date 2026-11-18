import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// OUTPUT CONSOLE v2 — composition root only, not an all-in-one control.
// This public API remains compatible with existing Main.qml connections.
Rectangle {
    id: root
    color: Theme.colors.panel

    property string searchText: ""
    property string activeFilter: "all"
    property bool followLatest: true
    property bool wrapLines: true
    property bool showTimes: true
    property int selectedSequence: -1
    property string notice: ""

    readonly property bool compact: height < 230

    function appendLog(message) { logStore.appendLog(message) }
    function appendOutput(text) { logStore.appendOutput(text) }

    function copyText(value, label) {
        if (!value) return
        clipboardBuffer.text = value
        clipboardBuffer.selectAll()
        clipboardBuffer.copy()
        clipboardBuffer.deselect()
        clipboardBuffer.text = ""
        notice = label
        noticeTimer.restart()
    }

    function copyLog(visibleOnly) {
        copyText(logStore.copyText(visibleOnly, showTimes),
                 visibleOnly ? "Filtered output copied" : "Output copied")
    }

    function clearOutput() {
        logStore.clear()
        selectedSequence = -1
        notice = "Console cleared"
        noticeTimer.restart()
    }

    OutputLogStore {
        id: logStore
        filterLevel: root.activeFilter
    }

    // QML's built-in clipboard support; no C++ changes are necessary.
    TextEdit {
        id: clipboardBuffer
        visible: false
        width: 1
        height: 1
        textFormat: TextEdit.PlainText
    }

    Timer {
        id: queryTimer
        interval: 160
        repeat: false
        onTriggered: logStore.searchQuery = root.searchText
    }
    Timer {
        id: noticeTimer
        interval: 2400
        repeat: false
        onTriggered: root.notice = ""
    }
    Timer {
        id: scrollTimer
        interval: 70
        repeat: false
        onTriggered: {
            if (root.followLatest && !logStore.frozen)
                outputList.positionViewAtEnd()
        }
    }

    onSearchTextChanged: queryTimer.restart()
    onFollowLatestChanged: {
        if (followLatest) scrollTimer.restart()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        OutputHeader {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            frozen: logStore.frozen
            unseen: logStore.unseenCount
        }

        OutputToolbar {
            Layout.fillWidth: true
            Layout.preferredHeight: 43
            searchText: root.searchText
            frozen: logStore.frozen
            followLatest: root.followLatest
            wrapLines: root.wrapLines
            showTimes: root.showTimes
            hasOutput: logStore.receivedCount > 0
            hasVisibleOutput: logStore.visibleCount > 0

            onSearchChanged: function(value) { root.searchText = value }
            onPauseRequested: logStore.frozen = !logStore.frozen
            onFollowRequested: root.followLatest = !root.followLatest
            onCopyAllRequested: root.copyLog(false)
            onCopyVisibleRequested: root.copyLog(true)
            onClearRequested: root.clearOutput()
            onWrapRequested: root.wrapLines = !root.wrapLines
            onTimestampsRequested: root.showTimes = !root.showTimes
            onResetRequested: { root.searchText = ""; root.activeFilter = "all" }
        }

        OutputFilters {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 33 : 0
            visible: !root.compact
            selectedFilter: root.activeFilter
            allCount: logStore.receivedCount
            errorCount: logStore.errorCount
            warningCount: logStore.warningCount
            infoCount: logStore.infoCount
            processCount: logStore.processCount
            onFilterRequested: function(value) { root.activeFilter = value }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 25 : 0
            visible: !root.compact
            color: Theme.colors.surface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 11
                anchors.rightMargin: 11
                spacing: 7
                Image {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    source: "qrc:/engine/assets/icons/file.svg"
                    sourceSize: Qt.size(24, 24)
                }
                Label {
                    text: "EVENT STREAM"
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 0.5
                    color: Theme.colors.accent
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: logStore.visibleCount + " shown / " + logStore.receivedCount + " retained"
                    color: Theme.colors.muted
                    font.pixelSize: 9
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: outputList
                anchors.fill: parent
                model: logStore.displayModel
                clip: true
                reuseItems: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: OutputLogRow {
                    width: outputList.width - 9
                    sequence: model.sequence
                    timestamp: model.time
                    level: model.level
                    origin: model.source
                    message: model.message
                    selected: root.selectedSequence === model.sequence
                    showTimestamp: root.showTimes
                    wrapText: root.wrapLines
                    onSelectedRequested: function(value) { root.selectedSequence = value }
                    onCopyRequested: function(value) { root.copyText(value, "Message copied") }
                }

                // Browsing past history disengages auto-follow until re-enabled.
                onMovementStarted: root.followLatest = false
                onCountChanged: {
                    if (root.followLatest && !logStore.frozen) scrollTimer.restart()
                }
            }

            ColumnLayout {
                visible: logStore.visibleCount === 0
                anchors.centerIn: parent
                width: Math.max(100, Math.min(parent.width - 26, 300))
                spacing: 7
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    source: "qrc:/engine/assets/icons/cube_blue.svg"
                    sourceSize: Qt.size(56, 56)
                    opacity: 0.65
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.searchText || root.activeFilter !== "all"
                          ? "No matching messages" : "Waiting for events"
                    color: Theme.colors.text
                    font.bold: true
                    font.pixelSize: 12
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: root.searchText || root.activeFilter !== "all"
                          ? "Try another filter or clear your search."
                          : "Run your project to see process and engine events here."
                    color: Theme.colors.muted
                    font.pixelSize: 10
                }
            }

            Rectangle {
                visible: logStore.frozen
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 9
                radius: 5
                width: frozenLabel.implicitWidth + 18
                height: 23
                color: Theme.colors.control
                border.width: 1
                border.color: "#8E7045"
                Label {
                    id: frozenLabel
                    anchors.centerIn: parent
                    text: logStore.unseenCount ? logStore.unseenCount + " new events" : "View frozen"
                    color: "#E6B86B"
                    font.pixelSize: 9
                }
            }
        }

        OutputStatusBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            frozen: logStore.frozen
            following: root.followLatest
            notice: root.notice
            droppedCount: logStore.droppedCount
            errors: logStore.errorCount
            warnings: logStore.warningCount
        }
    }
}
