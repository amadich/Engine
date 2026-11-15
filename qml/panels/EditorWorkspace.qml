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

    color: Theme.colors.canvas

    ListModel {
        id: documents
    }

    function selectTab(index) {
        loadingBuffer = true
        activeTab = index
        editor.text = index < 0 ? "" : documents.get(index).draft
        statusMessage = ""
        loadingBuffer = false

        if (index >= 0)
            editor.forceActiveFocus()
    }

    function openFile(fileUrl) {
        const key = fileUrl.toString()

        for (let i = 0; i < documents.count; ++i) {
            if (documents.get(i).fileUrl === key) {
                selectTab(i)
                return
            }
        }

        const details = controller.inspectFile(fileUrl)

        if (details.error || details.kind !== "text" || details.truncated) {
            statusMessage = details.error
                || "Choose a supported text file up to 64 KiB."
            return
        }

        documents.append({
            fileUrl: key,
            name: details.name,
            relativePath: details.path,
            original: details.text,
            draft: details.text,
            dirty: false
        })

        selectTab(documents.count - 1)
    }

    function saveCurrent() {
        if (activeTab < 0)
            return

        const document = documents.get(activeTab)

        if (!document.dirty)
            return

        const error = controller.saveTextFile(
            document.fileUrl, document.original, document.draft)

        if (error) {
            statusMessage = error
            return
        }

        documents.setProperty(activeTab, "original", document.draft)
        documents.setProperty(activeTab, "dirty", false)
        dirtyCount -= 1
        statusMessage = ""
    }

    function closeTab(index) {
        if (documents.get(index).dirty) {
            statusMessage = "Save the file before closing its tab."
            return
        }

        const previous = activeTab
        documents.remove(index)

        if (previous === index)
            selectTab(Math.min(index, documents.count - 1))
        else if (previous > index)
            activeTab = previous - 1
    }

    function reset() {
        selectTab(-1)
        documents.clear()
        dirtyCount = 0
    }

    Shortcut {
        sequences: [StandardKey.Save]
        enabled: root.activeTab >= 0
        onActivated: root.saveCurrent()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Button {
                text: "Preview"
                highlighted: root.activeTab === -1
                onClicked: root.selectTab(-1)
            }

            ListView {
                id: tabs

                Layout.fillWidth: true
                Layout.preferredHeight: 36
                orientation: ListView.Horizontal
                flickableDirection: Flickable.HorizontalFlick
                clip: true
                spacing: 2
                model: documents

                onCountChanged: positionViewAtEnd()

                delegate: Rectangle {
                    id: tab

                    required property int index
                    required property string name
                    required property string relativePath
                    required property bool dirty

                    width: tabContent.implicitWidth + 8
                    height: tabs.height
                    radius: 5
                    color: root.activeTab === index
                           ? Theme.colors.selection : Theme.colors.control

                    RowLayout {
                        id: tabContent

                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 0

                        ToolButton {
                            text: tab.name + (tab.dirty ? " ●" : "")
                            ToolTip.visible: hovered
                            ToolTip.text: tab.relativePath
                            onClicked: root.selectTab(tab.index)
                        }

                        ToolButton {
                            text: "×"
                            Accessible.name: "Close " + tab.name
                            onClicked: root.closeTab(tab.index)
                        }
                    }
                }
            }

            Button {
                text: "Save"
                visible: root.activeTab >= 0
                enabled: root.hasUnsavedChanges
                onClicked: root.saveCurrent()
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.margins: 8
            visible: root.statusMessage !== ""
            text: root.statusMessage
            color: Theme.colors.error
            wrapMode: Text.WordWrap
        }

        PreviewPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.activeTab < 0

            previewUrl: visible ? root.previewUrl : ""
            devServerActive: root.devServerActive
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.activeTab >= 0
            clip: true

            TextArea {
                id: editor

                padding: 12
                font.family: "Menlo"
                font.pixelSize: 14
                color: Theme.colors.text
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.NoWrap
                selectByMouse: true
                persistentSelection: true

                background: Rectangle {
                    color: Theme.colors.canvas
                }

                onTextChanged: {
                    if (root.loadingBuffer || root.activeTab < 0)
                        return

                    const document = documents.get(root.activeTab)
                    const wasDirty = document.dirty
                    const isDirty = text !== document.original

                    documents.setProperty(root.activeTab, "draft", text)

                    if (wasDirty !== isDirty) {
                        documents.setProperty(root.activeTab, "dirty", isDirty)
                        root.dirtyCount += isDirty ? 1 : -1
                    }
                }
            }
        }
    }
}