import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// UI only: component installation, relocation and removal remain in C++.
Dialog {
    id: root
    required property ProjectController controller
    required property ComponentManager componentManager
    property bool hasUnsavedChanges: false
    property string operation: "install" // install | move | remove
    property string componentId: ""
    property string destinationPath: ""
    property string actionError: ""
    property var preview: ({})
    property bool repairConfirmation: false
    property bool installed: false
    property string originalPath: ""
    property bool previewPending: false

    readonly property var definition: ComponentRegistry.component(componentId)
    readonly property string componentName: definition.name || "Component"
    readonly property bool isPlacement: operation !== "remove"
    readonly property string errorText: String(actionError || preview.error || "")
    readonly property int fileCount: (preview.files || []).length
    readonly property int referenceCount: (preview.references || []).length
    readonly property int collisionCount: (preview.collisions || []).length
    readonly property bool canCommit: Boolean(componentId.length > 0
        && !hasUnsavedChanges && !previewPending
        && controller.activeProjectPath !== ""
        && (!controller.busy || controller.devServerActive)
        && errorText.length === 0 && fileCount > 0)

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(950, parent ? parent.width - 32 : 950)
    height: Math.min(610, parent ? parent.height - 32 : 610)
    padding: 0
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    title: (operation === "install" ? "Install " : operation === "move" ? "Move " : "Remove ") + componentName
    header: Item { implicitHeight: 0 }
    background: Rectangle {
        radius: 7
        color: Theme.colors.panel
        border.color: Theme.colors.border
    }

    function syncStatus() {
        installed = componentManager.isInstalled(componentId)
        originalPath = componentManager.installedDirectory(componentId)
    }
    function openForComponent(id) {
        componentId = id
        syncStatus()
        actionError = ""
        repairConfirmation = false
        destinationPath = operation === "install"
                ? String(ComponentRegistry.component(id).legacyDirectory || "src/components") : ""
        previewDelay.stop()
        refreshPreview()
        open()
    }
    function refreshPreview() {
        if (!componentId) preview = ({})
        else if (operation === "remove") preview = componentManager.previewRemove(componentId)
        else if (!destinationPath.trim()) preview = ({ "files": [], "references": [] })
        else if (operation === "move") preview = componentManager.previewMove(componentId, destinationPath.trim())
        else preview = componentManager.previewInstall(componentId, destinationPath.trim())
        previewPending = false
    }
    Connections {
        target: root.componentManager
        function onComponentInstalled(id) { if (id === root.componentId) root.syncStatus() }
        function onComponentMoved(id) { if (id === root.componentId) root.syncStatus() }
        function onComponentRemoved(id) { if (id === root.componentId) root.syncStatus() }
    }
    Timer { id: previewDelay; interval: 220; repeat: false; onTriggered: root.refreshPreview() }
    onDestinationPathChanged: {
        if (componentId && isPlacement) {
            actionError = ""
            preview = ({})
            previewPending = true
            previewDelay.restart()
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // Header: compact hierarchy, one accent, no decorative cards.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            color: Theme.colors.surface
            radius: 7
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 11
                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 5
                    color: "Transparent" /*Theme.colors.control*/
                    Image {
                        anchors.centerIn: parent
                        width: 24; height: 24
                        source: "qrc:/engine/assets/icons/cube_blue.svg"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Label {
                        text: "COMPONENTS  /  " + root.operation.toUpperCase()
                        color: Theme.colors.muted
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                    RowLayout {
                        spacing: 8
                        Label {
                            text: root.operation === "move" ? "Relocate component"
                                  : root.operation === "install" ? "Install component" : "Remove component"
                            color: Theme.colors.text
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "·  " + root.componentName
                            elide: Text.ElideRight
                            color: Theme.colors.muted
                            font.pixelSize: 12
                        }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: stateText.implicitWidth + 18
                    Layout.preferredHeight: 23
                    radius: 4
                    color: "Transparent" /*Theme.colors.control*/
                    border.color: Theme.colors.border
                    Label {
                        id: stateText
                        anchors.centerIn: parent
                        text: root.errorText ? "ATTENTION" : root.previewPending ? "SCANNING"
                              : root.canCommit ? "READY" : "PREVIEW"
                        color: root.errorText ? Theme.colors.error
                               : root.canCommit ? Theme.colors.accent : Theme.colors.muted
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
                ToolButton {
                    id: closeButton
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    onClicked: root.reject()
                    background: Rectangle {
                        radius: 4
                        color: closeButton.hovered ? Theme.colors.hover : "transparent"
                    }
                    contentItem: Image {
                        source: "qrc:/engine/assets/icons/close.svg"
                        fillMode: Image.PreserveAspectFit
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: "Close"
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            spacing: 10

            ComponentDestinationPicker {
                Layout.preferredWidth: root.width * 0.43
                Layout.fillHeight: true
                visible: root.isPlacement
                controller: root.controller
                destinationPath: root.destinationPath
                onDestinationEdited: function(path) { root.destinationPath = path }
            }

            Rectangle {
                Layout.preferredWidth: root.width * 0.43
                Layout.fillHeight: true
                visible: !root.isPlacement
                radius: 5
                color: Theme.colors.surface
                border.color: Theme.colors.border
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10
                    RowLayout {
                        Image { source: "qrc:/engine/assets/icons/trash.svg"; Layout.preferredWidth: 17; Layout.preferredHeight: 17 }
                        Label { text: "RECOVERY OPERATION"; font.pixelSize: 11; font.bold: true; color: Theme.colors.text }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }
                    Label {
                        Layout.fillWidth: true
                        text: "Registered files will be moved to the recovery area. Other project files are preserved."
                        wrapMode: Text.WordWrap
                        color: Theme.colors.muted
                        font.pixelSize: 12
                    }
                    Label { text: "CURRENT LOCATION"; color: Theme.colors.muted; font.pixelSize: 10; font.bold: true }
                    Label { Layout.fillWidth: true; text: root.originalPath || "Not installed"; wrapMode: Text.WrapAnywhere; color: Theme.colors.text; font.pixelSize: 12 }
                    Label { text: "RECOVERY LOCATION"; color: Theme.colors.muted; font.pixelSize: 10; font.bold: true }
                    Label { text: ".jeridiengine/trash/"; color: Theme.colors.text; font.pixelSize: 12 }
                    Item { Layout.fillHeight: true }
                    Label { text: "Final backup path is reported in OUTPUT."; color: Theme.colors.muted; font.pixelSize: 10 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 5
                color: Theme.colors.surface
                border.color: Theme.colors.border
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 9
                    RowLayout {
                        spacing: 7
                        Image { source: "qrc:/engine/assets/icons/preview.svg"; Layout.preferredWidth: 17; Layout.preferredHeight: 17 }
                        Label { text: "CHANGE PREVIEW"; color: Theme.colors.text; font.pixelSize: 11; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Label { text: root.previewPending ? "SCANNING" : root.fileCount + " FILES"; color: Theme.colors.muted; font.pixelSize: 10 }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: root.operation === "install" ? "TO" : "FROM"; color: Theme.colors.muted; font.pixelSize: 10 }
                        Label {
                            Layout.fillWidth: true
                            text: root.operation === "install" ? (root.destinationPath.trim() || "—") : (root.originalPath || "—")
                            elide: Text.ElideMiddle
                            color: Theme.colors.text
                            font.pixelSize: 11
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.operation === "move"
                        Label { text: "TO"; color: Theme.colors.muted; font.pixelSize: 10 }
                        Label {
                            Layout.fillWidth: true
                            text: root.destinationPath.trim() || "Select destination…"
                            elide: Text.ElideMiddle
                            color: Theme.colors.text
                            font.pixelSize: 11
                        }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }

                    ScrollView {
                        id: changesScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        clip: true
                        ColumnLayout {
                            width: changesScroll.availableWidth
                            spacing: 9
                            Label {
                                text: root.operation === "install" ? "FILES TO CREATE"
                                      : root.operation === "move" ? "FILES TO RELOCATE" : "FILES TO ARCHIVE"
                                color: Theme.colors.muted
                                font.pixelSize: 10
                                font.bold: true
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 24
                                spacing: 9
                                visible: root.fileCount === 0 && root.referenceCount === 0
                                         && root.collisionCount === 0 && !root.errorText
                                Image {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    source: "qrc:/engine/assets/icons/cube_block.svg"
                                    opacity: 0.65
                                }
                                Label {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.previewPending ? "Inspecting destination…"
                                          : root.isPlacement && !root.destinationPath.trim() ? "Select a destination" : "No changes to preview"
                                    color: Theme.colors.muted
                                    font.pixelSize: 12
                                }
                            }
                            Repeater {
                                model: root.preview.files || []
                                delegate: RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 7
                                    Image { source: "qrc:/engine/assets/icons/file.svg"; Layout.preferredWidth: 14; Layout.preferredHeight: 14 }
                                    Label { Layout.fillWidth: true; text: String(modelData); wrapMode: Text.WrapAnywhere; font.pixelSize: 11; color: Theme.colors.text }
                                }
                            }
                            Label {
                                visible: root.referenceCount > 0
                                text: root.operation === "remove" ? "REFERENCES BLOCKING REMOVAL" : "IMPORTS TO REVIEW"
                                color: root.operation === "remove" ? Theme.colors.error : Theme.colors.accent
                                font.pixelSize: 10; font.bold: true
                            }
                            Repeater {
                                model: root.preview.references || []
                                delegate: Label { required property var modelData; Layout.fillWidth: true; text: "• " + String(modelData); wrapMode: Text.WrapAnywhere; font.pixelSize: 11; color: Theme.colors.muted }
                            }
                            Label { visible: root.collisionCount > 0; text: "DESTINATION CONFLICTS"; color: Theme.colors.error; font.pixelSize: 10; font.bold: true }
                            Repeater {
                                model: root.preview.collisions || []
                                delegate: Label { required property var modelData; Layout.fillWidth: true; text: "• " + String(modelData); wrapMode: Text.WrapAnywhere; font.pixelSize: 11; color: Theme.colors.error }
                            }
                            Label {
                                Layout.fillWidth: true
                                visible: root.operation !== "install" && !!root.preview.cleanup
                                text: String(root.preview.cleanup || "")
                                wrapMode: Text.WordWrap
                                color: Theme.colors.muted
                                font.pixelSize: 11
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: root.errorText.length > 0
                        text: root.errorText
                        wrapMode: Text.WordWrap
                        color: Theme.colors.error
                        font.pixelSize: 11
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 62
            color: Theme.colors.surface
            radius: 7
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 9
                Image {
                    source: root.hasUnsavedChanges || root.errorText
                            ? "qrc:/engine/assets/icons/warning_2.svg" : "qrc:/engine/assets/icons/preview.svg"
                    Layout.preferredWidth: 17
                    Layout.preferredHeight: 17
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Label {
                        Layout.fillWidth: true
                        text: root.hasUnsavedChanges ? "Save open editor tabs before continuing"
                              : root.repairConfirmation ? "Confirm registry repair (no files touched)"
                              : root.errorText ? "Resolve the issue shown above"
                              : root.previewPending ? "Checking affected files…"
                              : root.canCommit ? "Ready · " + root.fileCount + " file(s) affected"
                              : "Preview only · nothing changes until confirmed"
                        elide: Text.ElideRight
                        color: root.hasUnsavedChanges || root.errorText ? Theme.colors.error : Theme.colors.text
                        font.pixelSize: 11
                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.operation === "move" || root.operation === "remove"
                              ? "Aliases and computed imports may need manual review."
                              : "Review paths and conflicts before installing."
                        elide: Text.ElideRight
                        color: Theme.colors.muted
                        font.pixelSize: 10
                    }
                }
                Button {
                    id: existingButton
                    visible: root.operation === "install" && root.installed
                    text: "Move existing"
                    font.pixelSize: 11
                    implicitHeight: 32
                    onClicked: { root.reject(); root.componentManager.requestMove(root.componentId) }
                    background: Rectangle {
                        radius: 4
                        color: existingButton.hovered ? Theme.colors.hover : Theme.colors.control
                        border.color: Theme.colors.border
                    }
                }
                Button {
                    id: repairButton
                    visible: root.operation === "install" && root.preview.repairable === true
                    enabled: !root.hasUnsavedChanges
                    text: root.repairConfirmation ? "Confirm repair" : "Repair registry"
                    font.pixelSize: 11
                    implicitHeight: 32
                    background: Rectangle {
                        radius: 4
                        color: repairButton.hovered ? Theme.colors.hover : Theme.colors.control
                        border.color: Theme.colors.border
                    }
                    onClicked: {
                        if (!root.repairConfirmation) root.repairConfirmation = true
                        else {
                            const error = root.componentManager.repairMissingInstallation(root.componentId)
                            root.repairConfirmation = false
                            root.actionError = error
                            if (!error) root.refreshPreview()
                        }
                    }
                }
                Button {
                    id: cancelButton
                    text: "Cancel"
                    font.pixelSize: 11
                    implicitHeight: 32
                    onClicked: root.reject()
                    background: Rectangle {
                        radius: 4
                        color: cancelButton.hovered ? Theme.colors.hover : Theme.colors.control
                        border.color: Theme.colors.border
                    }
                }
                Button {
                    id: commitButton
                    text: root.operation === "install" ? "Install component"
                          : root.operation === "move" ? "Move files" : "Move to recovery"
                    icon.source: root.operation === "remove"
                                 ? "qrc:/engine/assets/icons/trash.svg" : "qrc:/engine/assets/icons/cube_blue.svg"
                    icon.width: 16
                    icon.height: 16
                    font.pixelSize: 11
                    implicitHeight: 32
                    enabled: root.canCommit
                    onClicked: {
                        let error = ""
                        if (root.operation === "install")
                            error = root.componentManager.installComponentInDirectory(root.componentId, root.destinationPath.trim())
                        else if (root.operation === "move")
                            error = root.componentManager.moveComponentInDirectory(root.componentId, root.destinationPath.trim())
                        else
                            error = root.componentManager.removeComponent(root.componentId)
                        if (error) {
                            root.actionError = error
                            root.refreshPreview()
                        } else root.accept()
                    }
                    background: Rectangle {
                        radius: 4
                        color: commitButton.enabled ? Theme.colors.selection : Theme.colors.control
                        border.color: commitButton.enabled ? Theme.colors.accent : Theme.colors.border
                    }
                }
            }
        }
    }
}
