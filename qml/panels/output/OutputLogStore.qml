import QtQuick
import "OutputFormat.js" as Format

// The only owner of console entries, filtering, partial process lines and
// bounded history. OutputPanel owns the visuals, not the log data.
Item {
    id: root
    visible: false
    width: 0
    height: 0

    property int retentionLimit: 3000
    property string filterLevel: "all"
    property string searchQuery: ""
    property bool frozen: false

    property int receivedCount: 0
    property int errorCount: 0
    property int warningCount: 0
    property int infoCount: 0
    property int processCount: 0
    property int droppedCount: 0
    property int unseenCount: 0

    readonly property int visibleCount: displayRows.count
    property alias displayModel: displayRows

    // Private runtime buffers. Never write these to the user's project.
    property var history: []
    property int nextSequence: 1
    property string pendingProcessText: ""
    property int partialSequence: -1

    ListModel { id: displayRows }

    Timer {
        id: partialTimer
        interval: 300
        repeat: false
        onTriggered: root.publishPendingProcessLine()
    }

    onFilterLevelChanged: rebuild()
    onSearchQueryChanged: rebuild()
    onFrozenChanged: {
        if (!frozen) {
            unseenCount = 0
            rebuild()
        }
    }

    function bumpLevel(level, amount) {
        if (level === "error") errorCount += amount
        else if (level === "warning") warningCount += amount
        else infoCount += amount
    }

    function recount() {
        errorCount = 0
        warningCount = 0
        infoCount = 0
        processCount = 0
        for (let i = 0; i < history.length; ++i) {
            bumpLevel(history[i].level, 1)
            if (history[i].source === "process") processCount++
        }
        receivedCount = history.length
    }

    function rebuild() {
        if (frozen) return
        displayRows.clear()
        for (let i = 0; i < history.length; ++i) {
            if (Format.matches(history[i], filterLevel, searchQuery))
                displayRows.append(history[i])
        }
    }

    function addLine(value, source) {
        const line = Format.normalizeLine(value)
        const entry = {
            sequence: nextSequence++,
            time: Qt.formatTime(new Date(), "hh:mm:ss"),
            level: Format.classify(line, source),
            source: source,
            message: line
        }

        history.push(entry)
        receivedCount++
        bumpLevel(entry.level, 1)
        if (source === "process") processCount++
        if (frozen) unseenCount++

        if (history.length > retentionLimit) {
            // Drop a small batch to avoid rebuilding on every line at the limit.
            const toRemove = Math.min(100, history.length)
            history.splice(0, toRemove)
            droppedCount += toRemove
            recount()
            if (!frozen) rebuild()
        } else if (!frozen && Format.matches(entry, filterLevel, searchQuery)) {
            displayRows.append(entry)
        }
        return entry.sequence
    }

    function revisePartialLine(value) {
        if (partialSequence < 0 || history.length === 0) return
        const entry = history[history.length - 1]
        if (entry.sequence !== partialSequence) return

        const newMessage = Format.normalizeLine(value)
        const newLevel = Format.classify(newMessage, "process")
        if (entry.level !== newLevel) {
            bumpLevel(entry.level, -1)
            bumpLevel(newLevel, 1)
        }
        entry.level = newLevel
        entry.message = newMessage
        if (!frozen) rebuild()
    }

    function publishPendingProcessLine() {
        if (!pendingProcessText) return
        if (partialSequence >= 0) revisePartialLine(pendingProcessText)
        else partialSequence = addLine(pendingProcessText, "process")
    }

    // Receives exact stdout/stderr chunks. A chunk may split a line mid-word.
    function appendOutput(chunk) {
        const incoming = String(chunk === undefined || chunk === null ? "" : chunk)
        if (!incoming) return

        const sections = (pendingProcessText + incoming).split(/\r\n|\r|\n/)
        pendingProcessText = sections.pop()

        if (sections.length > 0) {
            for (let i = 0; i < sections.length; ++i) {
                if (i === 0 && partialSequence >= 0)
                    revisePartialLine(sections[i])
                else
                    addLine(sections[i], "process")
            }
            partialSequence = -1
        }

        if (pendingProcessText) partialTimer.restart()
        else partialTimer.stop()
    }

    function flushProcessLine() {
        partialTimer.stop()
        if (pendingProcessText) publishPendingProcessLine()
        pendingProcessText = ""
        partialSequence = -1
    }

    function appendLog(message) {
        flushProcessLine()
        const lines = String(message === undefined || message === null ? "" : message)
                      .split(/\r\n|\r|\n/)
        if (lines.length > 1 && lines[lines.length - 1] === "") lines.pop()
        for (let i = 0; i < lines.length; ++i)
            addLine(lines[i], "engine")
    }

    function clear() {
        partialTimer.stop()
        history = []
        pendingProcessText = ""
        partialSequence = -1
        displayRows.clear()
        nextSequence = 1
        droppedCount = 0
        unseenCount = 0
        receivedCount = 0
        errorCount = 0
        warningCount = 0
        infoCount = 0
        processCount = 0
    }

    function copyText(visibleOnly, includeTime) {
        const source = visibleOnly ? displayRows : history
        const lines = []
        if (visibleOnly) {
            for (let i = 0; i < source.count; ++i)
                lines.push(Format.formatForCopy(source.get(i), includeTime))
        } else {
            for (let j = 0; j < source.length; ++j)
                lines.push(Format.formatForCopy(source[j], includeTime))
        }
        return lines.join("\n")
    }

    Component.onCompleted: appendLog("Jeridi Engine ready.")
}
