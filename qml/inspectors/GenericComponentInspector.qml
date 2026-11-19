import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Displays manifest-defined settings and package contents.
Item {
    id: root
    required property ProjectController controller
    required property ComponentManager componentManager
    required property string componentId

    readonly property var definition: ComponentRegistry.component(componentId)
    property bool installed: false

    readonly property string settingsId: String(definition.settingsPackage || componentId)
    readonly property var settingsDefinition: settingsId === componentId
        ? definition : ComponentRegistry.component(settingsId)
    readonly property var fields: (settingsDefinition.fields || []).filter(function(field) {
        return !definition.settingKeys || definition.settingKeys.includes(field.key)
    })
    readonly property bool propertiesFormat: settingsDefinition.configFormat === "properties"
    readonly property string directory: installed
        ? componentManager.installedDirectory(componentId) : ""
    readonly property bool hasPreview: installed && definition.preview === true
        && ((controller.projectFramework === "react-vite"
             && /^[a-zA-Z0-9_-]+(\/[a-zA-Z0-9_-]+)*$/.test(directory))
            || /^(src\/)?app\/[a-zA-Z0-9_/-]+$/.test(directory))
    property string original: ""
    property var values: ({})
    property bool loaded: false
    property bool dirty: false
    property bool failed: false
    property string message: ""

    function refreshStatus() {
        installed = componentManager.isInstalled(componentId)
        loaded = false
        dirty = false
        failed = false
        message = ""
        if (!fields.length)
            return
        const details = componentManager.isInstalled(settingsId)
            ? controller.inspectFile(componentManager.configurationUrl(settingsId))
            : { kind: "text", text: componentManager.draftConfiguration(settingsId) }
        if (details.error || details.kind !== "text" || details.truncated) {
            failed = true
            message = String(details.error || "Settings could not be loaded.")
            return
        }
        original = details.text
        try {
            const parsed = propertiesFormat ? {} : JSON.parse(original)
            if (propertiesFormat) {
                original.split(/\r?\n/).forEach(function(line) {
                    const separator = line.indexOf("=")
                    if (separator > 0 && !/^\s*[#!]/.test(line))
                        parsed[line.slice(0, separator).trim()] = line.slice(separator + 1)
                })
            }
            if (!parsed || typeof parsed !== "object" || Array.isArray(parsed))
                throw new Error("Expected a settings object.")
            values = parsed
            loaded = true
        } catch (error) {
            failed = true
            message = String(error.message)
        }
    }

    function updateValue(key, value) {
        const next = Object.assign({}, values)
        next[key] = value
        values = next
        dirty = true
    }

    function applySettings() {
        const updated = Object.assign({}, values)
        for (let i = 0; i < fields.length; i++) {
            const field = fields[i]
            const input = String(updated[field.key] ?? field.defaultValue ?? "")
            if ((field.options && !field.options.includes(input))
                || (field.pattern && !(new RegExp(field.pattern)).test(input))) {
                failed = true
                message = field.label + " has an invalid value."
                return
            }
            if (field.type === "number") {
                const number = Number(input)
                if (!/^[0-9]+$/.test(input) || number < field.minimum || number > field.maximum) {
                    failed = true
                    message = field.label + " must be between " + field.minimum + " and " + field.maximum + "."
                    return
                }
                updated[field.key] = number
            } else {
                updated[field.key] = input
            }
        }
        let output = JSON.stringify(updated, null, 2) + "\n"
        if (propertiesFormat) {
            const keys = fields.map(function(field) { return field.key })
            const lines = original.split(/\r?\n/).filter(function(line) {
                return !keys.includes(line.split("=")[0].trim())
            })
            while (lines.length && lines[lines.length - 1] === "")
                lines.pop()
            keys.forEach(function(key) { lines.push(key + "=" + updated[key]) })
            output = lines.join("\n") + "\n"
        }
        const settingsInstalled = componentManager.isInstalled(settingsId)
        const error = settingsInstalled
            ? controller.saveTextFile(componentManager.configurationUrl(settingsId), original, output)
            : componentManager.setDraftConfiguration(settingsId, output)
        if (error) {
            failed = true
            message = error
            return
        }
        refreshStatus()
        message = settingsInstalled ? "Settings saved." : "Draft saved for " + settingsDefinition.name + "."
    }
    Component.onCompleted: refreshStatus()
    Connections {
        target: root.componentManager
        function onComponentInstalled(id) { if (id === root.componentId || id === root.settingsId) root.refreshStatus() }
        function onComponentMoved(id) { if (id === root.componentId || id === root.settingsId) root.refreshStatus() }
        function onComponentRemoved(id) { if (id === root.componentId || id === root.settingsId) root.refreshStatus() }
    }
    Connections {
        target: root.controller
        function onActiveProjectChanged() { root.refreshStatus() }
    }

    InspectorScaffold {
        id: inspectorShell
        anchors.fill: parent
        controller: root.controller
        componentManager: root.componentManager
        componentId: root.componentId
        componentName: String(root.definition.name || "Component")
        description: String(root.definition.description || "Framework-specific component package")
        installed: root.installed
        showApply: root.fields.length > 0
        showReload: root.fields.length > 0
        dirty: root.dirty
        changeCount: root.dirty ? 1 : 0
        canApply: root.loaded && root.dirty && root.controller.activeProjectPath !== ""
        statusMessage: root.message
        statusIsError: root.failed
        previewVisible: false
        onApplyRequested: root.applySettings()
        onReloadRequested: root.refreshStatus()

        InspectorSection {
            Layout.fillWidth: true
            filterAllowed: root.fields.length > 0
            title: "Settings"
            description: String(root.definition.settingsHint || "")
            filterQuery: inspectorShell.filterText
            filterKeywords: root.fields.map(function(field) { return field.label }).join(" ")
            Repeater {
                model: root.fields
                InspectorPropertyRow {
                    id: fieldRow
                    required property var modelData
                    Layout.fillWidth: true
                    caption: modelData.label
                    filterQuery: inspectorShell.filterText
                    showAll: inspectorShell.filterText === "settings"
                    readonly property string settingValue: String(
                        root.values[modelData.key] ?? modelData.defaultValue ?? "")
                    Loader {
                        Layout.fillWidth: true
                        enabled: root.loaded
                        sourceComponent: fieldRow.modelData.options ? choiceEditor
                            : fieldRow.modelData.type === "number" ? numberEditor : textEditor
                    }
                    Component {
                        id: textEditor
                        InspectorTextField {
                            maximumLength: 256
                            text: fieldRow.settingValue
                            onTextEdited: root.updateValue(fieldRow.modelData.key, text)
                        }
                    }
                    Component {
                        id: choiceEditor
                        InspectorComboBox {
                            model: fieldRow.modelData.options
                            currentIndex: fieldRow.modelData.options.indexOf(fieldRow.settingValue)
                            onActivated: root.updateValue(fieldRow.modelData.key, currentText)
                        }
                    }
                    Component {
                        id: numberEditor
                        InspectorNumberField {
                            from: fieldRow.modelData.minimum
                            to: fieldRow.modelData.maximum
                            value: Number(fieldRow.settingValue)
                            onValueModified: root.updateValue(fieldRow.modelData.key, value)
                        }
                    }
                }
            }
            InspectorActionButton {
                Layout.fillWidth: true
                visible: root.hasPreview
                text: "Open package preview"
                actionEnabled: String(root.controller.previewUrl) !== ""
                disabledReason: "Run the project to preview the component"
                onClicked: root.controller.showComponentPreview(root.directory)
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            title: "Package Contents"
            filterQuery: inspectorShell.filterText
            filterKeywords: "files contents source package java tsx vue json"
            iconSource: "qrc:/engine/assets/icons/file.svg"
            tag: String((root.definition.files || []).length) + " FILES"
            Repeater {
                model: root.definition.files || []
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 7
                    Image {
                        source: "qrc:/engine/assets/icons/file.svg"
                        sourceSize: Qt.size(20, 20)
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                    }
                    Label {
                        Layout.fillWidth: true
                        text: String(modelData.target || "")
                        font.pixelSize: 11
                        color: Theme.colors.text
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            filterAllowed: root.fields.length === 0
            title: "Inspector Support"
            filterQuery: inspectorShell.filterText
            filterKeywords: "support configuration inspector settings"
            iconSource: "qrc:/engine/assets/icons/cube.svg"
            expanded: false
            Label {
                Layout.fillWidth: true
                text: "This package does not declare an editable settings Inspector. Install or relocate it using the Project Package section below."
                font.pixelSize: 10
                color: Theme.colors.muted
                wrapMode: Text.WordWrap
            }
        }
    }
}
