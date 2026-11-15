import QtQuick
import QtQuick.Controls
import JeridiEngine
import "EditorEditing.js" as Editing

Item {
    id: pane

    property alias text: input.text
    property alias selectionColor: input.selectionColor
    readonly property alias textDocument: input.textDocument
    property string fileName: ""
    property var suggestions: []
    property int selectedIndex: -1
    readonly property bool completing: selectedIndex >= 0

    clip: true

    function focusEditor() {
        input.forceActiveFocus()
    }

    function dismissCompletion() {
        suggestions = []
        selectedIndex = -1
    }

    function showCompletion() {
        if (!input.activeFocus || input.selectionStart !== input.selectionEnd) {
            dismissCompletion()
            return
        }

        const range = Editing.wordRange(input.text, input.cursorPosition)
        suggestions = Editing.suggestions(input.text, range, fileName)
        selectedIndex = suggestions.length > 0 ? 0 : -1
    }

    function refreshCompletion() {
        if (completing)
            showCompletion()
    }

    function replaceText(start, end, value, cursor) {
        if (end > start)
            input.remove(start, end)
        input.insert(start, value)
        input.cursorPosition = cursor
    }

    function acceptCompletion(index) {
        const word = suggestions[index]
        const range = Editing.wordRange(input.text, input.cursorPosition)
        dismissCompletion()

        if (!word || !range.prefix || word.indexOf(range.prefix) !== 0)
            return

        replaceText(range.start, range.end, word, range.start + word.length)
        focusEditor()
    }

    Shortcut {
        sequence: "Ctrl+J"
        enabled: pane.visible && input.activeFocus
        onActivated: pane.showCompletion()
    }

    ScrollView {
        id: scroll

        anchors.fill: parent
        clip: true

        TextArea {
            id: input

            padding: 16
            font.family: "Menlo"
            font.pixelSize: 14
            color: Theme.colors.text
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.NoWrap
            selectByMouse: true
            persistentSelection: true

            background: Rectangle { color: Theme.colors.canvas }

            onTextChanged: {
                if (pane.completing)
                    Qt.callLater(pane.refreshCompletion)
            }

            onCursorPositionChanged: {
                if (pane.completing)
                    Qt.callLater(pane.refreshCompletion)
            }

            onActiveFocusChanged: {
                if (!activeFocus)
                    pane.dismissCompletion()
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: editorMenu.popup()
            }

            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
                if (event.modifiers !== Qt.NoModifier || input.inputMethodComposing)
                    return

                const key = event.key

                if (pane.completing && (key === Qt.Key_Up || key === Qt.Key_Down)) {
                    const step = key === Qt.Key_Up ? -1 : 1
                    pane.selectedIndex = Math.max(0, Math.min(
                        pane.suggestions.length - 1, pane.selectedIndex + step))
                    event.accepted = true
                } else if (pane.completing && key === Qt.Key_Escape) {
                    pane.dismissCompletion()
                    event.accepted = true
                } else if (key === Qt.Key_Tab) {
                    if (pane.completing) {
                        pane.acceptCompletion(pane.selectedIndex)
                        event.accepted = true
                    } else if (input.selectionStart === input.selectionEnd) {
                        input.insert(input.cursorPosition, "  ")
                        event.accepted = true
                    }
                } else if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                    pane.dismissCompletion()
                    try {
                        const start = input.selectionStart
                        const end = input.selectionEnd
                        const edit = Editing.newline(input.text, start, end)
                        pane.replaceText(start, end, edit.text, edit.cursor)
                        event.accepted = true
                    } catch (error) {
                        // Let TextArea handle Enter if smart indentation fails.
                        console.warn("Smart indent:", error)
                    }
                }
            }
        }

        EditorContextMenu {
            id: editorMenu
            editor: input
        }
    }

    CompletionList {
        id: completion

        // Include scroll offsets as dependencies so the caret mapping stays live.
        readonly property point caret: {
            const viewport = scroll.contentItem
            const offsetX = viewport.contentX
            const offsetY = viewport.contentY
            const rect = input.cursorRectangle
            return input.mapToItem(pane, rect.x, rect.y)
        }
        readonly property real caretBottom: caret.y + input.cursorRectangle.height

        z: 2
        suggestions: pane.suggestions
        selectedIndex: pane.selectedIndex
        width: Math.min(256, pane.width - 12)
        height: Math.min(suggestions.length, 6) * 26 + 6
        x: Math.max(6, Math.min(caret.x, pane.width - width - 6))
        y: caretBottom + height + 4 <= pane.height
           ? caretBottom + 3
           : Math.max(0, caret.y - height - 3)
        visible: pane.completing && pane.height > 64
                 && caret.y >= 0 && caretBottom <= pane.height

        onChosen: function(index) { pane.acceptCompletion(index) }
    }
}
