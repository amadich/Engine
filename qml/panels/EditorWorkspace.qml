import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine
import "EditorIntelligence.js" as Intelligence

Rectangle {
    id: root
    required property ProjectController controller
    property url previewUrl: ""
    property bool devServerActive: false
    property int activeTab: -1
    property int dirtyCount: 0
    property bool loadingBuffer: false
    property string statusMessage: ""
    property bool statusError: true
    property int editorFontSize: 14
    property bool findVisible: false
    property bool navigationVisible: false
    property string navigationMode: "imports"
    property var navigationImports: []
    property var navigationSymbols: []
    signal fileActivated(url file)

    readonly property url currentFileUrl: activeTab >= 0 && activeTab < documentModel.count
        ? documentModel.get(activeTab).fileUrl : ""
    readonly property bool hasUnsavedChanges: dirtyCount > 0
    readonly property bool currentDirty: activeTab >= 0 && activeTab < documentModel.count
        && documentModel.get(activeTab).dirty
    readonly property string currentPath: activeTab >= 0 && activeTab < documentModel.count
        ? documentModel.get(activeTab).relativePath : ""
    readonly property string currentName: activeTab >= 0 && activeTab < documentModel.count
        ? documentModel.get(activeTab).name : ""
    readonly property string currentKind: activeTab >= 0 && activeTab < documentModel.count
        ? documentModel.get(activeTab).kind : ""
    readonly property real currentSize: activeTab >= 0 && activeTab < documentModel.count
        ? documentModel.get(activeTab).size : 0
    readonly property color toolbarColor: Theme.colors.control
    readonly property color activeColor: Theme.colors.canvas
    readonly property color inactiveColor: Theme.colors.control
    readonly property color accentColor: "#629BEB"
    readonly property color mutedText: Theme.colors.muted
    readonly property color hoverColor: Theme.colors.selection
    color: Theme.colors.canvas

    ListModel { id: documentModel }
    CodeSyntaxHighlighter { id: syntaxHighlighter }
    Timer { id: intelligenceTimer; interval: 220; repeat: false; onTriggered: root.refreshIntelligence() }
    Connections {
        target: Theme
        function onDarkChanged() { root.updateSyntaxHighlighting() }
    }

    function fileType(name) {
        const n = name.toLowerCase()
        if (/\.(png|jpe?g|webp|gif|bmp|svg)$/.test(n)) return "Image"
        if (n.endsWith(".tsx")) return "TypeScript React"
        if (n.endsWith(".ts")) return "TypeScript"
        if (n.endsWith(".jsx")) return "JavaScript React"
        if (n.endsWith(".js")) return "JavaScript"
        if (n.endsWith(".java")) return "Java"
        if (n.endsWith(".kt")) return "Kotlin"
        if (n.endsWith(".vue")) return "Vue"
        if (n.endsWith(".json")) return "JSON"
        if (n.endsWith(".css") || n.endsWith(".scss")) return "CSS"
        if (n.endsWith(".html")) return "HTML"
        if (n.endsWith(".xml")) return "XML"
        if (n.endsWith(".qml")) return "QML"
        if (n.endsWith(".cpp") || n.endsWith(".h")) return "C++"
        if (n.endsWith(".md")) return "Markdown"
        if (n.endsWith(".yaml") || n.endsWith(".yml")) return "YAML"
        return "Plain Text"
    }

    function updateSyntaxHighlighting() {
        syntaxHighlighter.configure(editor.textDocument,
                                    root.currentKind === "text" ? root.currentName : "", Theme.dark)
    }

    function refreshIntelligence() {
        if (activeTab < 0 || currentKind !== "text") {
            navigationImports = []
            navigationSymbols = []
            return
        }
        const extracted = Intelligence.extractImports(editor.text, currentName)
        const resolved = []
        for (const imp of extracted) {
            const info = controller.resolveImport(currentFileUrl, imp.specifier)
            resolved.push({ specifier: imp.specifier, line: imp.line,
                            status: info.status || "external", kind: info.kind || "dependency",
                            path: info.path || "", url: info.url || "" })
        }
        navigationImports = resolved
        navigationSymbols = Intelligence.extractSymbols(editor.text, currentName)
    }

    function selectTab(index) {
        editor.dismissCompletion()
        if (index < -1 || index >= documentModel.count) return
        loadingBuffer = true
        activeTab = index
        editor.text = index >= 0 && documentModel.get(index).kind === "text"
            ? documentModel.get(index).draft : ""
        statusMessage = ""
        findVisible = false
        loadingBuffer = false
        updateSyntaxHighlighting()
        refreshIntelligence()
        if (index >= 0) {
            fileActivated(documentModel.get(index).fileUrl)
            if (currentKind === "text") editor.focusEditor()
        }
    }

    function openFile(fileUrl) {
        const key = fileUrl.toString()
        for (let i = 0; i < documentModel.count; ++i) {
            if (documentModel.get(i).fileUrl === key) { selectTab(i); return }
        }
        const details = controller.inspectFile(fileUrl)
        if (details.error || (details.kind !== "text" && details.kind !== "image") || details.truncated) {
            statusMessage = details.error || "This file type cannot be opened here (text limit: 512 KiB)."
            statusError = true
            return
        }
        documentModel.append({
            fileUrl: key, name: details.name, relativePath: details.path,
            original: details.kind === "text" ? details.text : "",
            draft: details.kind === "text" ? details.text : "",
            kind: details.kind, size: details.size || 0, dirty: false
        })
        selectTab(documentModel.count - 1)
        tabBar.revealLastTab()
    }

    function saveCurrent() {
        if (activeTab < 0 || currentKind !== "text") return
        const doc = documentModel.get(activeTab)
        if (!doc.dirty) return
        const error = controller.saveTextFile(doc.fileUrl, doc.original, doc.draft)
        if (error) { statusMessage = error; statusError = true; return }
        documentModel.setProperty(activeTab, "original", doc.draft)
        documentModel.setProperty(activeTab, "dirty", false)
        dirtyCount -= 1
        statusMessage = ""
    }
    function saveAll() {
        let failed = 0
        for (let i = 0; i < documentModel.count; ++i) {
            const doc = documentModel.get(i)
            if (!doc.dirty || doc.kind !== "text") continue
            const error = controller.saveTextFile(doc.fileUrl, doc.original, doc.draft)
            if (error) { failed += 1; statusMessage = error; statusError = true; continue }
            documentModel.setProperty(i, "original", doc.draft)
            documentModel.setProperty(i, "dirty", false)
            dirtyCount -= 1
        }
        if (!failed) statusMessage = ""
    }
    function closeTab(index) {
        if (index < 0 || index >= documentModel.count) return
        if (documentModel.get(index).dirty) {
            statusMessage = "Save the modified file before closing its tab."
            statusError = true
            return
        }
        const previous = activeTab
        documentModel.remove(index)
        if (previous === index) selectTab(Math.min(index, documentModel.count - 1))
        else if (previous > index) activeTab = previous - 1
    }
    function reset() {
        intelligenceTimer.stop()
        selectTab(-1)
        documentModel.clear()
        dirtyCount = 0
        statusMessage = ""
        navigationVisible = false
        navigationImports = []
        navigationSymbols = []
    }
    function closeCurrent() { closeTab(activeTab) }
    function closeAllEditors() {
        if (hasUnsavedChanges) { statusMessage = "Save modified files before closing all editors."; statusError = true; return }
        reset()
    }
    function nextTab() { if (documentModel.count) selectTab((activeTab + 1) % documentModel.count) }
    function previousTab() {
        if (documentModel.count) selectTab(activeTab < 0 ? documentModel.count - 1
                                          : (activeTab + documentModel.count - 1) % documentModel.count)
    }
    function showPreview() { selectTab(-1) }
    function undoEdit() { if (currentKind === "text") editor.undoEdit() }
    function redoEdit() { if (currentKind === "text") editor.redoEdit() }
    function cutSelection() { if (currentKind === "text") editor.cutSelection() }
    function copySelection() { if (currentKind === "text") editor.copySelection() }
    function pasteClipboard() { if (currentKind === "text") editor.pasteClipboard() }
    function selectAllText() { if (currentKind === "text") editor.selectAllText() }
    function toggleComment() { if (currentKind === "text") editor.toggleComment() }
    function requestCompletion() {
        if (currentKind !== "text") return
        editor.focusEditor()
        Qt.callLater(function() { editor.showCompletion() })
    }
    function changeFontSize(delta) { editorFontSize = Math.max(10, Math.min(26, editorFontSize + delta)) }

    function openFind() {
        if (currentKind !== "text") return
        findVisible = true
        Qt.callLater(function() { findBar.focusSearch() })
    }
    function openReplace() {
        if (currentKind !== "text") return
        findBar.replaceVisible = true
        openFind()
    }
    function findNext(backwards) {
        if (currentKind !== "text") return
        if (!findVisible) { openFind(); return }
        if (!editor.findText(findBar.query, backwards === true, findBar.matchCase)) {
            statusMessage = "No match for: " + findBar.query
            statusError = true
        } else statusMessage = ""
    }
    function openGoToLine() {
        if (currentKind !== "text") return
        goToLineInput.text = String(editor.caretLine)
        goToLineDialog.open()
        Qt.callLater(function() { goToLineInput.forceActiveFocus(); goToLineInput.selectAll() })
    }
    function goToImportAtCaret() {
        if (currentKind !== "text") return
        refreshIntelligence()
        const match = navigationImports.find(item => item.line === editor.caretLine)
        if (match && match.status === "local") openFile(match.url)
        else {
            statusMessage = match ? "This import is external or its local target is missing."
                                  : "Place the caret on an import line, or open Imports."
            statusError = false
        }
    }
    function showImports() { navigationMode = "imports"; navigationVisible = true; refreshIntelligence() }
    function showOutline() { navigationMode = "symbols"; navigationVisible = true; refreshIntelligence() }

    Shortcut {
        sequence: "F12"
        enabled: root.visible && root.currentKind === "text"
        onActivated: root.goToImportAtCaret()
    }
    Shortcut {
        sequence: "Ctrl+R"
        enabled: root.visible && root.currentKind === "text"
        onActivated: root.openReplace()
    }
    Shortcut {
        sequence: "Ctrl+B"
        enabled: root.visible && root.currentKind === "text"
        onActivated: root.goToImportAtCaret()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        EditorTabBar {
            id: tabBar
            documents: documentModel
            activeTab: root.activeTab
            currentDirty: root.currentDirty
            toolbarColor: root.toolbarColor
            activeColor: root.activeColor
            inactiveColor: root.inactiveColor
            accentColor: root.accentColor
            mutedText: root.mutedText
            hoverColor: root.hoverColor
            onTabRequested: function(index) { root.selectTab(index) }
            onCloseRequested: function(index) { root.closeTab(index) }
            onSaveRequested: root.saveCurrent()
        }
        EditorActionBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            visible: root.activeTab >= 0
            path: root.currentPath
            language: root.fileType(root.currentName)
            imageFile: root.currentKind === "image"
            importCount: root.navigationImports.length
            symbolCount: root.navigationSymbols.length
            navigationVisible: root.navigationVisible
            onImportsRequested: root.showImports()
            onSymbolsRequested: root.showOutline()
            onFindRequested: root.openFind()
            onReplaceRequested: root.openReplace()
            onGoToLineRequested: root.openGoToLine()
            onGoToImportRequested: root.goToImportAtCaret()
        }
        EditorFindBar {
            id: findBar
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            visible: root.findVisible && root.currentKind === "text"
            onSearchRequested: function(backwards) { root.findNext(backwards) }
            onReplaceRequested: {
                if (editor.replaceCurrent(query, replacement, matchCase)) root.statusMessage = ""
            }
            onReplaceAllRequested: {
                const count = editor.replaceAll(query, replacement, matchCase)
                root.statusMessage = count + " occurrence(s) replaced."
                root.statusError = false
            }
            onCloseRequested: { root.findVisible = false; editor.focusEditor() }
            matchCount: root.findVisible && root.currentKind === "text"
                        ? editor.countMatches(query, matchCase) : 0
        }
        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            visible: root.statusMessage !== ""
            text: root.statusMessage
            color: root.statusError ? Theme.colors.error : Theme.colors.muted
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
        PreviewPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.activeTab < 0
            previewUrl: visible ? root.previewUrl : ""
            devServerActive: root.devServerActive
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            visible: root.activeTab >= 0
            CodeEditorPane {
                id: editor
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.currentKind === "text"
                fileName: root.currentName
                editorFontSize: root.editorFontSize
                selectionColor: root.accentColor
                importPathProvider: function(prefix) {
                    return root.controller.suggestImportPaths(root.currentFileUrl, prefix)
                }
                onTextChanged: {
                    if (root.loadingBuffer || root.activeTab < 0 || root.currentKind !== "text") return
                    const doc = documentModel.get(root.activeTab)
                    const wasDirty = doc.dirty
                    const isDirty = editor.text !== doc.original
                    documentModel.setProperty(root.activeTab, "draft", editor.text)
                    if (wasDirty !== isDirty) {
                        documentModel.setProperty(root.activeTab, "dirty", isDirty)
                        root.dirtyCount += isDirty ? 1 : -1
                    }
                    intelligenceTimer.restart()
                }
            }
            EditorImagePreview {
                id: imagePreview
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.currentKind === "image"
                fileUrl: visible ? root.currentFileUrl : ""
                fileName: root.currentName
                relativePath: root.currentPath
                imageBytes: root.currentSize
            }
            EditorNavigationPanel {
                Layout.preferredWidth: 230
                Layout.fillHeight: true
                visible: root.navigationVisible && root.currentKind === "text"
                mode: root.navigationMode
                imports: root.navigationImports
                symbols: root.navigationSymbols
                onModeRequested: function(mode) { root.navigationMode = mode }
                onCloseRequested: root.navigationVisible = false
                onOpenImportRequested: function(fileUrl) { root.openFile(fileUrl) }
                onGoToLineRequested: function(line) { editor.goToLine(line) }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            visible: root.activeTab >= 0
            color: Theme.colors.control
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.colors.border }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10
                Label {
                    text: root.currentKind === "text"
                          ? "Ln " + editor.caretLine + ", Col " + editor.caretColumn
                          : "Image preview"
                    color: Theme.colors.text
                    font.pixelSize: 10
                }
                Label { text: root.currentKind === "text" ? editor.lineCount + " lines" : ""; color: Theme.colors.muted; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Label { text: root.currentDirty ? "● Modified" : "✓ Saved"; color: root.currentDirty ? root.accentColor : Theme.colors.muted; font.pixelSize: 10 }
                Label { text: root.fileType(root.currentName); color: Theme.colors.muted; font.pixelSize: 10 }
                Label { text: "UTF-8"; visible: root.currentKind === "text"; color: Theme.colors.muted; font.pixelSize: 10 }
                Label { text: "Spaces: 2"; visible: root.currentKind === "text"; color: Theme.colors.muted; font.pixelSize: 10 }
            }
        }
    }

    Dialog {
        id: goToLineDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 320
        modal: true
        popupType: Popup.Window
        title: "Go to Line"
        standardButtons: Dialog.Ok | Dialog.Cancel
        background: Rectangle { color: Theme.colors.panel; border.color: Theme.colors.border; radius: 5 }
        contentItem: ColumnLayout {
            spacing: 10
            Label { text: "Line number"; color: Theme.colors.text; font.pixelSize: 12 }
            TextField {
                id: goToLineInput
                Layout.fillWidth: true
                validator: IntValidator { bottom: 1; top: 999999 }
                onAccepted: goToLineDialog.accept()
            }
        }
        onAccepted: {
            if (!editor.goToLine(Number(goToLineInput.text))) {
                root.statusMessage = "Line number is outside this file."
                root.statusError = true
            } else root.statusMessage = ""
        }
    }
}
