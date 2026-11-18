import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine
import "EditorEditing.js" as Editing
import "EditorIntelligence.js" as Intelligence

Item {
    id: pane
    property alias text: input.text
    property alias selectionColor: input.selectionColor
    readonly property alias textDocument: input.textDocument
    property string fileName: ""
    property int editorFontSize: 14
    readonly property real editorLineHeight: Math.ceil(editorMetrics.height)
    FontMetrics { id: editorMetrics; font: input.font }
    property var importPathProvider: null
    readonly property alias canUndo: input.canUndo
    readonly property alias canRedo: input.canRedo
    readonly property int lineCount: input.lineCount
    readonly property var caretInfo: Intelligence.caretInfo(input.text, input.cursorPosition)
    readonly property int caretLine: caretInfo.line
    readonly property int caretColumn: caretInfo.column
    property var suggestions: []
    property int selectedIndex: -1
    readonly property bool completing: selectedIndex >= 0
    clip: true

    function focusEditor() { input.forceActiveFocus() }
    function undoEdit() { input.undo(); focusEditor() }
    function redoEdit() { input.redo(); focusEditor() }
    function cutSelection() { input.cut(); focusEditor() }
    function copySelection() { input.copy(); focusEditor() }
    function pasteClipboard() { input.paste(); focusEditor() }
    function selectAllText() { input.selectAll(); focusEditor() }

    function dismissCompletion() {
        autoCompleteTimer.stop()
        suggestions = []
        selectedIndex = -1
    }

    function showCompletion() {
        if (!input.activeFocus || input.selectionStart !== input.selectionEnd || input.inputMethodComposing) {
            dismissCompletion()
            return
        }
        const context = Intelligence.importContext(input.text, input.cursorPosition)
        if (context && typeof pane.importPathProvider === "function") {
            suggestions = pane.importPathProvider(context.prefix)
            selectedIndex = suggestions.length > 0 ? 0 : -1
            return
        }
        const range = Editing.wordRange(input.text, input.cursorPosition)
        suggestions = Editing.suggestions(input.text, range, fileName)
        selectedIndex = suggestions.length > 0 ? 0 : -1
    }

    function replaceText(start, end, value, cursor) {
        if (end > start) input.remove(start, end)
        input.insert(start, value)
        input.cursorPosition = cursor
    }

    function acceptCompletion(index) {
        const word = suggestions[index]
        const context = Intelligence.importContext(input.text, input.cursorPosition)
        const range = context || Editing.wordRange(input.text, input.cursorPosition)
        dismissCompletion()
        if (!word || !range.prefix || !word.toLowerCase().startsWith(range.prefix.toLowerCase())) return
        replaceText(range.start, range.end, word, range.start + word.length)
        focusEditor()
        if (word.endsWith("/") && context) autoCompleteTimer.restart()
    }

    function countMatches(query, matchCase) {
        return Intelligence.matches(input.text, query, matchCase).length
    }

    function findText(query, backwards, matchCase) {
        const found = Intelligence.matches(input.text, query, matchCase)
        if (!found.length) return false
        const anchor = backwards ? input.selectionStart - 1 : input.selectionEnd
        let index = backwards ? found[found.length - 1] : found[0]
        if (backwards) {
            for (let i = found.length - 1; i >= 0; --i)
                if (found[i] <= anchor) { index = found[i]; break }
        } else {
            for (let i = 0; i < found.length; ++i)
                if (found[i] >= anchor) { index = found[i]; break }
        }
        input.select(index, index + query.length)
        focusEditor()
        return true
    }

    function replaceCurrent(query, replacement, matchCase) {
        if (!query) return false
        const selected = input.selectedText
        if (selected.length === query.length &&
            (matchCase ? selected === query : selected.toLowerCase() === query.toLowerCase())) {
            const start = input.selectionStart
            replaceText(start, input.selectionEnd, replacement, start + replacement.length)
            findText(query, false, matchCase)
            return true
        }
        return findText(query, false, matchCase)
    }

    function replaceAll(query, replacement, matchCase) {
        const found = Intelligence.matches(input.text, query, matchCase)
        if (!found.length) return 0
        dismissCompletion()
        // Edit from the end to preserve all earlier offsets and TextArea's undo history.
        for (let i = found.length - 1; i >= 0; --i) {
            input.remove(found[i], found[i] + query.length)
            input.insert(found[i], replacement)
        }
        focusEditor()
        return found.length
    }

    function goToLine(number) {
        if (number < 1) return false
        const lines = input.text.split("\n")
        if (number > lines.length) return false
        let offset = 0
        for (let i = 0; i < number - 1; ++i) offset += lines[i].length + 1
        input.cursorPosition = offset
        focusEditor()
        return true
    }

    function toggleComment() {
        const ext = fileName.toLowerCase().split(".").pop()
        const hash = ["yaml", "yml", "properties", "py", "sh"].includes(ext)
        if (!["tsx", "ts", "jsx", "js", "vue", "java", "cpp", "cc", "h", "hpp", "qml", "kt", "yaml", "yml", "properties", "py", "sh"].includes(ext))
            return false
        const marker = hash ? "# " : "// "
        const begin = input.text.lastIndexOf("\n", Math.max(0, input.selectionStart - 1)) + 1
        let finish = input.text.indexOf("\n", input.selectionEnd)
        if (finish < 0) finish = input.text.length
        const source = input.text.slice(begin, finish)
        const lines = source.split("\n")
        const allCommented = lines.filter(s => s.trim() !== "").every(s => s.trimStart().startsWith(marker.trim()))
        const changed = lines.map(line => {
            if (!line.trim()) return line
            const indent = (line.match(/^\s*/) || [""])[0]
            const body = line.slice(indent.length)
            if (allCommented) return indent + body.replace(new RegExp("^" + (hash ? "#" : "\\/\\/") + " ?"), "")
            return indent + marker + body
        }).join("\n")
        input.remove(begin, finish)
        input.insert(begin, changed)
        input.select(begin, begin + changed.length)
        focusEditor()
        return true
    }

    Shortcut {
        sequence: "Ctrl+Space"
        enabled: pane.visible && input.activeFocus
        onActivated: pane.showCompletion()
    }
    Shortcut {
        sequence: "Ctrl+/"
        enabled: pane.visible && input.activeFocus
        onActivated: pane.toggleComment()
    }
    Timer {
        id: autoCompleteTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (!input.activeFocus) return
            const context = Intelligence.importContext(input.text, input.cursorPosition)
            const range = Editing.wordRange(input.text, input.cursorPosition)
            if (context || range.prefix.length >= 2) pane.showCompletion()
            else pane.dismissCompletion()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            id: gutter
            Layout.preferredWidth: 52
            Layout.fillHeight: true
            color: Theme.colors.control
            clip: true
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.colors.border }
            ListView {
                anchors.fill: parent
                model: input.lineCount
                interactive: false
                clip: true
                contentY: scroll.contentItem.contentY
                header: Item { width: gutter.width; height: input.topPadding }
                delegate: Rectangle {
                    required property int index
                    width: gutter.width - 1
                    height: pane.editorLineHeight
                    color: index + 1 === pane.caretLine ? Theme.colors.selection : "transparent"
                    Label {
                        anchors.right: parent.right
                        anchors.rightMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(index + 1)
                        font.family: "Menlo"
                        font.pixelSize: pane.editorFontSize - 2
                        color: index + 1 === pane.caretLine ? Theme.colors.text : Theme.colors.muted
                    }
                }
            }
        }
        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            TextArea {
                id: input
                leftPadding: 14
                rightPadding: 24
                topPadding: 16
                bottomPadding: 18
                font.family: "Menlo"
                font.pixelSize: pane.editorFontSize
                color: Theme.colors.text
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.NoWrap
                selectByMouse: true
                persistentSelection: true
                background: Rectangle {
                    color: Theme.colors.canvas
                    Rectangle {
                        x: 0
                        y: input.cursorRectangle.y
                        width: parent.width
                        height: pane.editorLineHeight
                        color: Theme.colors.selection
                        opacity: input.activeFocus ? 0.14 : 0.07
                    }
                }
                onTextChanged: {
                    if (input.activeFocus && !input.inputMethodComposing)
                        autoCompleteTimer.restart()
                }
                onCursorPositionChanged: {
                    if (pane.completing)
                        Qt.callLater(pane.showCompletion)
                }
                onActiveFocusChanged: {
                    if (!activeFocus) pane.dismissCompletion()
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: editorMenu.popup()
                }
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (input.inputMethodComposing) return
                    const key = event.key
                    if (pane.completing && event.modifiers === Qt.NoModifier &&
                        (key === Qt.Key_Up || key === Qt.Key_Down)) {
                        pane.selectedIndex = Math.max(0, Math.min(pane.suggestions.length - 1,
                            pane.selectedIndex + (key === Qt.Key_Up ? -1 : 1)))
                        event.accepted = true
                    } else if (pane.completing && key === Qt.Key_Escape) {
                        pane.dismissCompletion()
                        event.accepted = true
                    } else if (event.modifiers === Qt.NoModifier && key === Qt.Key_Tab) {
                        if (pane.completing) pane.acceptCompletion(pane.selectedIndex)
                        else input.insert(input.cursorPosition, "  ")
                        event.accepted = true
                    } else if (event.modifiers === Qt.ShiftModifier && (key === Qt.Key_Tab || key === Qt.Key_Backtab)) {
                        const lineStart = input.text.lastIndexOf("\n", Math.max(0, input.cursorPosition - 1)) + 1
                        const spaces = input.text.slice(lineStart, lineStart + 2)
                        const removeCount = spaces.startsWith("  ") ? 2
                                          : spaces.startsWith(" ") || spaces.startsWith("\t") ? 1 : 0
                        if (removeCount) input.remove(lineStart, lineStart + removeCount)
                        event.accepted = true
                    } else if (event.modifiers === Qt.NoModifier &&
                               (key === Qt.Key_Return || key === Qt.Key_Enter)) {
                        if (pane.completing) pane.acceptCompletion(pane.selectedIndex)
                        else {
                            const start = input.selectionStart
                            const end = input.selectionEnd
                            const edit = Editing.newline(input.text, start, end)
                            pane.replaceText(start, end, edit.text, edit.cursor)
                        }
                        event.accepted = true
                    }
                }
            }
            EditorContextMenu { id: editorMenu; editor: input }
        }
    }

    CompletionList {
        id: completion
        readonly property point caret: {
            // mapToItem accounts for both horizontal and vertical scrolling.
            const rect = input.cursorRectangle
            return input.mapToItem(pane, rect.x, rect.y)
        }
        readonly property real caretBottom: caret.y + input.cursorRectangle.height
        z: 10
        suggestions: pane.suggestions
        selectedIndex: pane.selectedIndex
        width: Math.max(120, Math.min(340, pane.width - gutter.width - 12))
        height: Math.min(suggestions.length, 8) * 27 + 6
        x: Math.max(gutter.width + 3, Math.min(caret.x, pane.width - width - 4))
        y: caretBottom + height + 4 <= pane.height ? caretBottom + 3
           : Math.max(0, caret.y - height - 3)
        visible: pane.completing && pane.height > 64
                 && caret.y >= 0 && caretBottom <= pane.height
        onChosen: function(index) { pane.acceptCompletion(index) }
    }
}
