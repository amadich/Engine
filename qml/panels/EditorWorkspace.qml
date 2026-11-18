import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root

    required property ProjectController controller

    property url previewUrl: ""
    property bool devServerActive: false

    property int activeTab: -1
    property int dirtyCount: 0
    property bool loadingBuffer: false
    property string statusMessage: ""

    readonly property bool hasUnsavedChanges: dirtyCount > 0

    readonly property bool currentDirty:
        activeTab >= 0
        && activeTab < documentModel.count
        && documentModel.get(activeTab).dirty

    readonly property string currentPath:
        activeTab >= 0
        && activeTab < documentModel.count
        ? documentModel.get(activeTab).relativePath
        : ""

    readonly property string currentName:
        activeTab >= 0
        && activeTab < documentModel.count
        ? documentModel.get(activeTab).name
        : ""

    // Editor colors
    readonly property color toolbarColor: Theme.colors.control
    readonly property color activeColor: Theme.colors.canvas
    readonly property color inactiveColor: Theme.colors.control
    readonly property color accentColor: "#629BEB"
    readonly property color mutedText: "#9299A5"
    readonly property color hoverColor: Theme.colors.selection

    color: Theme.colors.canvas

    ListModel {
        id: documentModel
    }


    CodeSyntaxHighlighter {
        id: syntaxHighlighter
    }

    function updateSyntaxHighlighting() {
        const fileName = root.activeTab < 0
                         ? ""
                         : documentModel.get(root.activeTab).name

        syntaxHighlighter.configure(editor.textDocument, fileName, Theme.dark)
    }

    Connections {
        target: Theme

        function onDarkChanged() {
            root.updateSyntaxHighlighting()
        }
    }

    // FILE HELPERS


    function fileType(fileName) {
        const name = fileName.toLowerCase()

        if (name.endsWith(".tsx"))
            return "TypeScript React"

        if (name.endsWith(".ts"))
            return "TypeScript"

        if (name.endsWith(".jsx"))
            return "JavaScript React"

        if (name.endsWith(".js"))
            return "JavaScript"

        if (name.endsWith(".java"))
            return "Java"

        if (name.endsWith(".vue"))
            return "Vue"

        if (name.endsWith(".xml"))
            return "XML"

        if (name.endsWith(".json"))
            return "JSON"

        if (name.endsWith(".html"))
            return "HTML"

        if (name.endsWith(".css"))
            return "CSS"

        if (name.endsWith(".qml"))
            return "QML"

        if (name.endsWith(".cpp"))
            return "C++"

        if (name.endsWith(".md"))
            return "Markdown"

        return "Plain Text"
    }

    // DOCUMENT MANAGEMENT


    function selectTab(index) {
        editor.dismissCompletion()

        if (index < -1 || index >= documentModel.count)
            return

        loadingBuffer = true

        activeTab = index

        editor.text = index < 0
            ? ""
            : documentModel.get(index).draft

        statusMessage = ""

        loadingBuffer = false
        root.updateSyntaxHighlighting()

        if (index >= 0)
            editor.focusEditor()
    }

    function openFile(fileUrl) {
        const key = fileUrl.toString()

        for (let i = 0; i < documentModel.count; ++i) {
            if (documentModel.get(i).fileUrl === key) {
                selectTab(i)
                return
            }
        }

        const details = controller.inspectFile(fileUrl)

        if (details.error ||
            details.kind !== "text" ||
            details.truncated) {

            statusMessage = details.error
                || "Choose a supported text file up to 64 KiB."

            return
        }

        documentModel.append({
            fileUrl: key,
            name: details.name,
            relativePath: details.path,
            original: details.text,
            draft: details.text,
            dirty: false
        })

        selectTab(documentModel.count - 1)
        tabBar.revealLastTab()
    }

    function saveCurrent() {
        if (activeTab < 0)
            return

        const document = documentModel.get(activeTab)

        if (!document.dirty)
            return

        const error = controller.saveTextFile(
            document.fileUrl,
            document.original,
            document.draft
        )

        if (error) {
            statusMessage = error
            return
        }

        documentModel.setProperty(
            activeTab,
            "original",
            document.draft
        )

        documentModel.setProperty(
            activeTab,
            "dirty",
            false
        )

        dirtyCount -= 1
        statusMessage = ""
    }

    function closeTab(index) {
        if (index < 0 || index >= documentModel.count)
            return

        if (documentModel.get(index).dirty) {
            statusMessage = "Save the file before closing its tab."
            return
        }

        const previous = activeTab

        documentModel.remove(index)

        if (previous === index) {
            selectTab(Math.min(index, documentModel.count - 1))
        } else if (previous > index) {
            activeTab = previous - 1
        }
    }

    function reset() {
        selectTab(-1)
        documentModel.clear()
        dirtyCount = 0
        statusMessage = ""
    }

    // KEYBOARD SHORTCUTS


    Shortcut {
        sequences: [StandardKey.Save]
        enabled: root.activeTab >= 0
        onActivated: root.saveCurrent()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // EDITOR TOOLBAR


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

        // FILE INFORMATION BAR


        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            visible: root.activeTab >= 0

            color: Theme.colors.canvas

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14

                spacing: 8

                Label {
                    Layout.fillWidth: true

                    text: root.currentPath

                    color: root.mutedText
                    font.pixelSize: 11

                    elide: Text.ElideMiddle
                }

                Label {
                    text: root.fileType(root.currentName)

                    color: root.mutedText
                    font.pixelSize: 11
                }

                Rectangle {
                    width: 1
                    height: 12
                    color: root.mutedText
                    opacity: 0.35
                }

                Label {
                    text: root.currentDirty
                          ? "Modified"
                          : "Saved"

                    color: root.currentDirty
                           ? root.accentColor
                           : root.mutedText

                    font.pixelSize: 11
                }
            }
        }

        // STATUS MESSAGE


        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 6
            Layout.bottomMargin: 6

            visible: root.statusMessage !== ""

            text: root.statusMessage

            color: Theme.colors.error

            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        // PREVIEW PANEL


        PreviewPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: root.activeTab < 0

            previewUrl: visible ? root.previewUrl : ""
            devServerActive: root.devServerActive
        }

        // CODE EDITOR



        CodeEditorPane {
            id: editor
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.activeTab >= 0
            fileName: root.currentName
            selectionColor: root.accentColor

            onTextChanged: {
                if (root.loadingBuffer || root.activeTab < 0)
                    return

                const document = documentModel.get(root.activeTab)
                const wasDirty = document.dirty
                const isDirty = editor.text !== document.original

                documentModel.setProperty(root.activeTab, "draft", editor.text)

                if (wasDirty !== isDirty) {
                    documentModel.setProperty(root.activeTab, "dirty", isDirty)
                    root.dirtyCount += isDirty ? 1 : -1
                }
            }
        }
    }
}
