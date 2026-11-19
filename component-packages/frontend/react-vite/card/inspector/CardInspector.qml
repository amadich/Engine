import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Card-specific settings. The shell, fields, color picker and project actions are shared.
Item {
    id: root
    required property ProjectController controller
    required property ComponentManager componentManager

    property url configUrl: ""
    property string originalConfigText: ""
    property var savedSettings: ({})
    property bool configLoaded: false
    property bool installed: false
    property string statusMessage: ""
    property bool statusError: false

    readonly property var hexColor: /^#[0-9a-fA-F]{6}$/
    readonly property bool canWrite: controller.activeProjectPath !== ""
                                     && (!controller.busy || controller.devServerActive)
    readonly property bool dirty: configLoaded && (
        titleInput.text !== String(savedSettings.title ?? "My Card")
        || descriptionInput.text !== String(savedSettings.description ?? "")
        || backgroundField.colorValue !== String(savedSettings.background ?? "#FFFFFF").toUpperCase()
        || foregroundField.colorValue !== String(savedSettings.foreground ?? "#1F2937").toUpperCase()
        || radiusInput.value !== Number(savedSettings.borderRadius ?? 12)
        || paddingInput.value !== Number(savedSettings.padding ?? 20)
        || shadowInput.checked !== (savedSettings.shadow === true)
    )
    // Names are diagnostic only; no new JSON keys are introduced.
    readonly property var changedProperties: !configLoaded ? [] : [
        { name: "Title", changed: titleInput.text !== String(savedSettings.title ?? "My Card") },
        { name: "Description", changed: descriptionInput.text !== String(savedSettings.description ?? "") },
        { name: "Background", changed: backgroundField.colorValue !== String(savedSettings.background ?? "#FFFFFF").toUpperCase() },
        { name: "Text color", changed: foregroundField.colorValue !== String(savedSettings.foreground ?? "#1F2937").toUpperCase() },
        { name: "Corner radius", changed: radiusInput.value !== Number(savedSettings.borderRadius ?? 12) },
        { name: "Padding", changed: paddingInput.value !== Number(savedSettings.padding ?? 20) },
        { name: "Drop shadow", changed: shadowInput.checked !== (savedSettings.shadow === true) }
    ].filter(function(item) { return item.changed }).map(function(item) { return item.name })
    function reloadConfig() {
        configLoaded = false
        statusError = false
        statusMessage = ""
        originalConfigText = ""
        installed = componentManager.isInstalled("card")
        configUrl = componentManager.configurationUrl("card")

        const details = installed
                      ? controller.inspectFile(configUrl)
                      : { kind: "text", text: componentManager.draftConfiguration("card") }
        if (details.error || details.kind !== "text" || details.truncated) {
            statusError = true
            statusMessage = String(details.error || "Unable to read Card settings.")
            return
        }

        try {
            const settings = JSON.parse(details.text)
            if (!settings || typeof settings !== "object" || Array.isArray(settings))
                throw new Error("Expected a JSON object")
            titleInput.text = String(settings.title ?? "My Card")
            descriptionInput.text = String(settings.description ?? "")
            backgroundField.colorValue = String(settings.background ?? "#FFFFFF").toUpperCase()
            foregroundField.colorValue = String(settings.foreground ?? "#1F2937").toUpperCase()
            backgroundField.resetEditor()
            foregroundField.resetEditor()
            radiusInput.value = Number(settings.borderRadius ?? 12)
            paddingInput.value = Number(settings.padding ?? 20)
            shadowInput.checked = settings.shadow === true
            originalConfigText = details.text
            savedSettings = {
                title: titleInput.text, description: descriptionInput.text,
                background: backgroundField.colorValue, foreground: foregroundField.colorValue,
                borderRadius: radiusInput.value, padding: paddingInput.value,
                shadow: shadowInput.checked
            }
            configLoaded = true
            if (!installed)
                statusMessage = "Draft mode: Apply updates the preview, not project files."
        } catch (error) {
            statusError = true
            statusMessage = "Invalid card.config.json: " + error.message
        }
    }

    function applyConfig() {
        if (!configLoaded || (installed && !canWrite)) return
        if (!titleInput.text.trim() || backgroundField.invalidInput || foregroundField.invalidInput
                || !hexColor.test(backgroundField.colorValue)
                || !hexColor.test(foregroundField.colorValue)) {
            statusError = true
            statusMessage = "Title and valid #RRGGBB colors are required."
            return
        }

        try {
            // Preserve unknown configuration keys instead of replacing the document.
            const settings = JSON.parse(originalConfigText)
            settings.title = titleInput.text.trim()
            settings.description = descriptionInput.text
            settings.background = backgroundField.colorValue
            settings.foreground = foregroundField.colorValue
            settings.borderRadius = radiusInput.value
            settings.padding = paddingInput.value
            settings.shadow = shadowInput.checked

            const nextText = JSON.stringify(settings, null, 2) + "\n"
            const error = installed
                ? controller.saveTextFile(configUrl, originalConfigText, nextText)
                : componentManager.setDraftConfiguration("card", nextText)
            if (error) {
                statusError = true
                statusMessage = error
                return
            }
            originalConfigText = nextText
            titleInput.text = settings.title
            savedSettings = {
                title: settings.title, description: settings.description,
                background: settings.background, foreground: settings.foreground,
                borderRadius: settings.borderRadius, padding: settings.padding,
                shadow: settings.shadow
            }
            statusError = false
            statusMessage = installed ? "Card settings saved." : "Draft updated; no project files changed."
        } catch (error) {
            statusError = true
            statusMessage = "Could not apply settings: " + error.message
        }
    }

    Component.onCompleted: reloadConfig()
    Connections {
        target: root.controller
        function onActiveProjectChanged() { root.reloadConfig() }
    }
    Connections {
        target: root.componentManager
        function onComponentInstalled(id) { if (id === "card") root.reloadConfig() }
        function onComponentMoved(id) { if (id === "card") root.reloadConfig() }
        function onComponentRemoved(id) { if (id === "card") root.reloadConfig() }
    }

    InspectorScaffold {
        id: inspectorShell
        anchors.fill: parent
        controller: root.controller
        componentManager: root.componentManager
        componentId: "card"
        componentName: "Card"
        description: "React · Display / Container"
        installed: root.installed
        dirty: root.dirty
        changeCount: root.changedProperties.length
        statusMessage: root.statusMessage
        statusIsError: root.statusError
        canApply: root.configLoaded && root.dirty && (!root.installed || root.canWrite)
                  && !backgroundField.invalidInput && !foregroundField.invalidInput
        canReload: root.configLoaded || root.statusError
        onApplyRequested: root.applyConfig()
        onReloadRequested: root.reloadConfig()

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 142
            visible: inspectorShell.previewVisible && (!inspectorShell.hasSearch
                     || "preview card visual".indexOf(inspectorShell.filterText) >= 0)
            color: Theme.colors.canvas

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                Label {
                    text: "LIVE PREVIEW"
                    font.pixelSize: 9
                    font.bold: true
                    color: Theme.colors.muted
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: radiusInput.value
                    color: root.hexColor.test(backgroundField.colorValue)
                           ? backgroundField.colorValue : Theme.colors.control
                    border.width: shadowInput.checked ? 2 : 1
                    border.color: shadowInput.checked ? Theme.colors.muted : Theme.colors.border
                    clip: true
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Math.min(24, paddingInput.value)
                        spacing: 4
                        Label {
                            Layout.fillWidth: true
                            text: titleInput.text || "Card title"
                            font.pixelSize: 13
                            font.bold: true
                            color: root.hexColor.test(foregroundField.colorValue)
                                   ? foregroundField.colorValue : Theme.colors.text
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: descriptionInput.text || "Description"
                            font.pixelSize: 11
                            color: root.hexColor.test(foregroundField.colorValue)
                                   ? foregroundField.colorValue : Theme.colors.text
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        InspectorSection {
            id: contentSection
            Layout.fillWidth: true
            title: "Content"
            filterQuery: inspectorShell.filterText
            filterKeywords: "title description text heading content"
            iconSource: "qrc:/engine/assets/icons/file.svg"
            description: "Values are saved to card.config.json."
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: contentSection.sectionTitleMatches
                caption: "Title"
                helpText: "Heading shown inside the card."
                InspectorTextField {
                    id: titleInput
                    Layout.fillWidth: true
                    text: "My Card"
                    enabled: root.configLoaded
                }
            }
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: contentSection.sectionTitleMatches
                caption: "Description"
                helpText: "Supporting text displayed below the heading."
                InspectorTextField {
                    id: descriptionInput
                    Layout.fillWidth: true
                    text: ""
                    enabled: root.configLoaded
                }
            }
        }

        InspectorSection {
            id: appearanceSection
            Layout.fillWidth: true
            title: "Appearance"
            filterQuery: inspectorShell.filterText
            filterKeywords: "appearance background text color hex palette"
            iconSource: "qrc:/engine/assets/icons/image.svg"
            description: "Click a swatch to choose a color. Hex codes update automatically."
            InspectorColorField {
                filterQuery: inspectorShell.filterText
                showAll: appearanceSection.sectionTitleMatches
                id: backgroundField
                caption: "Background"
                colorValue: "#FFFFFF"
                enabled: root.configLoaded
            }
            InspectorColorField {
                filterQuery: inspectorShell.filterText
                showAll: appearanceSection.sectionTitleMatches
                id: foregroundField
                caption: "Text Color"
                colorValue: "#1F2937"
                enabled: root.configLoaded
            }
        }

        InspectorSection {
            id: layoutSection
            Layout.fillWidth: true
            title: "Layout & Effects"
            filterQuery: inspectorShell.filterText
            filterKeywords: "layout corner radius padding shadow effects"
            iconSource: "qrc:/engine/assets/icons/cube.svg"
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: layoutSection.sectionTitleMatches
                caption: "Corner Radius"
                helpText: "Rounded corners in CSS pixels (0–48)."
                InspectorNumberField {
                    id: radiusInput
                    Layout.fillWidth: true
                    from: 0; to: 48; value: 12
                    enabled: root.configLoaded
                }
                Label { text: "px"; font.pixelSize: 10; color: Theme.colors.muted }
            }
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: layoutSection.sectionTitleMatches
                caption: "Padding"
                helpText: "Space inside the card in CSS pixels (0–48)."
                InspectorNumberField {
                    id: paddingInput
                    Layout.fillWidth: true
                    from: 0; to: 48; value: 20
                    enabled: root.configLoaded
                }
                Label { text: "px"; font.pixelSize: 10; color: Theme.colors.muted }
            }
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: layoutSection.sectionTitleMatches
                caption: "Drop Shadow"
                helpText: "Toggle the shadow already supported by EngineCard.tsx."
                InspectorToggle {
                    id: shadowInput
                    Layout.fillWidth: true
                    checked: true
                    text: enabled ? (checked ? "Enabled" : "Disabled") : "Unavailable"
                    enabled: root.configLoaded
                }
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            title: "Accessibility"
            iconSource: "qrc:/engine/assets/icons/warning_2.svg"
            filterQuery: inspectorShell.filterText
            filterKeywords: "accessibility contrast ratio wcag aa aaa"
            expanded: false
            description: "Read-only WCAG contrast calculation; does not edit the React component."
            InspectorContrastMetric {
                backgroundColor: backgroundField.colorValue
                foregroundColor: foregroundField.colorValue
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            title: "Quick Presets"
            iconSource: "qrc:/engine/assets/icons/star.svg"
            description: "Set existing layout values; changes are not saved until Apply."
            filterQuery: inspectorShell.filterText
            filterKeywords: "presets compact balanced spacious radius padding shadow"
            expanded: false
            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                InspectorActionButton {
                    Layout.fillWidth: true
                    text: "Compact"
                    actionEnabled: root.configLoaded
                    hint: "Radius 6px, padding 10px, no shadow"
                    onClicked: { radiusInput.value = 6; paddingInput.value = 10; shadowInput.checked = false }
                }
                InspectorActionButton {
                    Layout.fillWidth: true
                    text: "Balanced"
                    actionEnabled: root.configLoaded
                    hint: "Radius 12px, padding 20px, shadow enabled"
                    onClicked: { radiusInput.value = 12; paddingInput.value = 20; shadowInput.checked = true }
                }
                InspectorActionButton {
                    Layout.fillWidth: true
                    text: "Spacious"
                    actionEnabled: root.configLoaded
                    hint: "Radius 20px, padding 28px, shadow enabled"
                    onClicked: { radiusInput.value = 20; paddingInput.value = 28; shadowInput.checked = true }
                }
            }
            Label {
                Layout.fillWidth: true
                text: "Presets edit only supported card layout settings."
                font.pixelSize: 9
                color: Theme.colors.muted
                wrapMode: Text.WordWrap
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            title: "Pending Changes"
            iconSource: "qrc:/engine/assets/icons/preview.svg"
            tag: root.changedProperties.length + " EDITS"
            filterQuery: inspectorShell.filterText
            filterKeywords: "pending changes edits modified unsaved"
            filterAllowed: root.dirty
            expanded: false
            InspectorChangeList {
                changes: root.changedProperties
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            title: "Configuration Info"
            iconSource: "qrc:/engine/assets/icons/file.svg"
            filterQuery: inspectorShell.filterText
            filterKeywords: "configuration info json path file schema"
            expanded: false
            Label {
                Layout.fillWidth: true
                text: root.installed ? root.configUrl.toString() : "Draft configuration (not written to disk)"
                font.pixelSize: 9
                color: Theme.colors.muted
                wrapMode: Text.WrapAnywhere
            }
            Label {
                Layout.fillWidth: true
                text: "Existing JSON keys outside the supported Card settings are preserved."
                font.pixelSize: 9
                color: Theme.colors.muted
                wrapMode: Text.WordWrap
            }
        }
    }
}
