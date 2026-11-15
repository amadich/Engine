
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
        && activeTab < documents.count
        && documents.get(activeTab).dirty

    readonly property string currentPath:
        activeTab >= 0
        && activeTab < documents.count
        ? documents.get(activeTab).relativePath
        : ""

    readonly property string currentName:
        activeTab >= 0
        && activeTab < documents.count
        ? documents.get(activeTab).name
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
        id: documents
    }

    // --------------------------------------------------
    // FILE HELPERS
    // --------------------------------------------------

    function fileIcon(fileName) {
        const name = fileName.toLowerCase()

        if (name.endsWith(".png") ||
            name.endsWith(".jpg") ||
            name.endsWith(".jpeg") ||
            name.endsWith(".svg") ||
            name.endsWith(".webp"))
            return "image.svg"

        return "file.svg"
    }

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

    // --------------------------------------------------
    // DOCUMENT MANAGEMENT
    // --------------------------------------------------

    function selectTab(index) {
        if (index < -1 || index >= documents.count)
            return

        loadingBuffer = true

        activeTab = index

        editor.text = index < 0
            ? ""
            : documents.get(index).draft

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

        if (details.error ||
            details.kind !== "text" ||
            details.truncated) {

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
        tabs.positionViewAtEnd()
    }

    function saveCurrent() {
        if (activeTab < 0)
            return

        const document = documents.get(activeTab)

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

        documents.setProperty(
            activeTab,
            "original",
            document.draft
        )

        documents.setProperty(
            activeTab,
            "dirty",
            false
        )

        dirtyCount -= 1
        statusMessage = ""
    }

    function closeTab(index) {
        if (index < 0 || index >= documents.count)
            return

        if (documents.get(index).dirty) {
            statusMessage = "Save the file before closing its tab."
            return
        }

        const previous = activeTab

        documents.remove(index)

        if (previous === index) {
            selectTab(Math.min(index, documents.count - 1))
        } else if (previous > index) {
            activeTab = previous - 1
        }
    }

    function reset() {
        selectTab(-1)
        documents.clear()
        dirtyCount = 0
        statusMessage = ""
    }

    // --------------------------------------------------
    // KEYBOARD SHORTCUTS
    // --------------------------------------------------

    Shortcut {
        sequences: [StandardKey.Save]
        enabled: root.activeTab >= 0
        onActivated: root.saveCurrent()
    }

    // --------------------------------------------------
    // MAIN LAYOUT
    // --------------------------------------------------

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==============================================
        // EDITOR TOOLBAR
        // ==============================================

        Rectangle {
            id: editorToolbar

            Layout.fillWidth: true
            Layout.preferredHeight: 44

            color: root.toolbarColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                spacing: 6

                // --------------------------------------
                // PREVIEW TAB
                // --------------------------------------

                Rectangle {
                    id: previewTab

                    Layout.preferredWidth: 110
                    Layout.fillHeight: true

                    color: root.activeTab === -1
                        ? root.activeColor
                        : "transparent"

                    radius: 5

                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: 2

                        color: root.activeTab === -1
                            ? root.accentColor
                            : "transparent"
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Image {
                            source: "qrc:/engine/assets/icons/forest.svg"

                            Layout.preferredWidth: 17
                            Layout.preferredHeight: 17

                            sourceSize.width: 34
                            sourceSize.height: 34

                            fillMode: Image.PreserveAspectFit
                        }

                        Label {
                            text: "Preview"
                            color: Theme.colors.text
                            font.pixelSize: 13
                            font.weight: root.activeTab === -1
                                ? Font.DemiBold
                                : Font.Normal
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.selectTab(-1)
                    }
                }

                // --------------------------------------
                // OPEN FILE TABS
                // --------------------------------------

                ListView {
                    id: tabs

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    orientation: ListView.Horizontal
                    flickableDirection: Flickable.HorizontalFlick

                    boundsBehavior: Flickable.StopAtBounds

                    clip: true
                    spacing: 3

                    model: documents

                    onCountChanged: {
                        if (count > 0)
                            positionViewAtEnd()
                    }

                    delegate: Rectangle {
                        id: tab

                        required property int index
                        required property string name
                        required property string relativePath
                        required property bool dirty

                        readonly property bool selected:
                            root.activeTab === index

                        readonly property bool hovered:
                            tabHover.hovered

                        width: 190
                        height: tabs.height

                        radius: 5

                        color: selected
                            ? root.activeColor
                            : hovered
                                ? root.hoverColor
                                : root.inactiveColor

                        // Active indicator
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: 2

                            color: tab.selected
                                ? root.accentColor
                                : "transparent"
                        }

                        HoverHandler {
                            id: tabHover
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6

                            spacing: 8

                            // File icon
                            Image {
                                Layout.preferredWidth: 17
                                Layout.preferredHeight: 17

                                source: "qrc:/engine/assets/icons/"
                                        + root.fileIcon(tab.name)

                                sourceSize.width: 34
                                sourceSize.height: 34

                                fillMode: Image.PreserveAspectFit
                            }

                            // File name
                            Label {
                                Layout.fillWidth: true

                                text: tab.name

                                color: tab.selected
                                    ? Theme.colors.text
                                    : root.mutedText

                                font.pixelSize: 13

                                font.weight: tab.selected
                                    ? Font.DemiBold
                                    : Font.Normal

                                elide: Text.ElideMiddle

                                verticalAlignment: Text.AlignVCenter
                            }

                            // Close / Dirty indicator
                            ToolButton {
                                id: closeButton

                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24

                                hoverEnabled: true

                                background: Rectangle {
                                    radius: 5

                                    color: closeButton.hovered
                                        ? "#9E3D48"
                                        : "transparent"
                                }

                                contentItem: Item {
                                    Image {
                                        anchors.centerIn: parent

                                        width: 12
                                        height: 12

                                        source: "qrc:/engine/assets/icons/close.svg"

                                        visible: !tab.dirty
                                                 || closeButton.hovered

                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Rectangle {
                                        anchors.centerIn: parent

                                        width: 7
                                        height: 7
                                        radius: 4

                                        color: root.accentColor

                                        visible: tab.dirty
                                                 && !closeButton.hovered
                                    }
                                }

                                opacity: tab.selected
                                         || tab.hovered
                                         || tab.dirty
                                         ? 1.0 : 0.0

                                ToolTip.visible: hovered
                                ToolTip.text: "Close " + tab.name

                                onClicked: root.closeTab(tab.index)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: -1

                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.selectTab(tab.index)
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton

                            onTapped: root.selectTab(tab.index)
                        }

                        ToolTip.visible: tab.hovered
                                         && !closeButton.hovered

                        ToolTip.text: tab.relativePath
                        ToolTip.delay: 700
                    }
                }

                // --------------------------------------
                // SAVE BUTTON
                // --------------------------------------

                Rectangle {
                    Layout.preferredWidth: 86
                    Layout.preferredHeight: 32

                    radius: 6

                    color: saveMouse.containsMouse
                           && root.currentDirty
                           ? root.hoverColor
                           : "transparent"

                    opacity: root.currentDirty ? 1.0 : 0.5

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 7

                        Image {
                            source: "qrc:/engine/assets/icons/save.svg"

                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16

                            sourceSize.width: 32
                            sourceSize.height: 32

                            fillMode: Image.PreserveAspectFit
                        }

                        Label {
                            text: "Save"

                            color: Theme.colors.text
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        id: saveMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        enabled: root.currentDirty

                        cursorShape: enabled
                                     ? Qt.PointingHandCursor
                                     : Qt.ArrowCursor

                        onClicked: root.saveCurrent()
                    }
                }
            }
        }

        // ==============================================
        // FILE INFORMATION BAR
        // ==============================================

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

        // ==============================================
        // STATUS MESSAGE
        // ==============================================

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

        // ==============================================
        // PREVIEW PANEL
        // ==============================================

        PreviewPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: root.activeTab < 0

            previewUrl: visible ? root.previewUrl : ""
            devServerActive: root.devServerActive
        }

        // ==============================================
        // CODE EDITOR
        // ==============================================

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: root.activeTab >= 0

            clip: true

            TextArea {
                id: editor

                padding: 16

                font.family: "Menlo"
                font.pixelSize: 14

                color: Theme.colors.text

                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.NoWrap

                selectByMouse: true
                persistentSelection: true

                selectionColor: root.accentColor

                background: Rectangle {
                    color: Theme.colors.canvas
                }

                onTextChanged: {
                    if (root.loadingBuffer ||
                        root.activeTab < 0)
                        return

                    const document = documents.get(root.activeTab)

                    const wasDirty = document.dirty
                    const isDirty = text !== document.original

                    documents.setProperty(
                        root.activeTab,
                        "draft",
                        text
                    )

                    if (wasDirty !== isDirty) {
                        documents.setProperty(
                            root.activeTab,
                            "dirty",
                            isDirty
                        )

                        root.dirtyCount += isDirty ? 1 : -1
                    }
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton

                    onTapped: function(eventPoint) {
                        editorMenu.popup()
                    }
                }
            }

            EditorContextMenu {
                id: editorMenu
                editor: editor
            }
        }
    }
}
