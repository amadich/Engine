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
    readonly property real contrast: contrastRatio(backgroundField.colorValue, foregroundField.colorValue)

    function luminance(hex) {
        if (!hexColor.test(hex)) return 0
        const values = [1, 3, 5].map(function(index) {
            const c = parseInt(hex.substr(index, 2), 16) / 255
            return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
        })
        return 0.2126 * values[0] + 0.7152 * values[1] + 0.0722 * values[2]
    }
    function contrastRatio(background, foreground) {
        if (!hexColor.test(background) || !hexColor.test(foreground)) return 0
        const a = luminance(background)
        const b = luminance(foreground)
        return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
    }

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
        anchors.fill: parent
        controller: root.controller
        componentManager: root.componentManager
        componentId: "card"
        componentName: "Card"
        description: "React · Display / Container"
        installed: root.installed
        dirty: root.dirty
        statusMessage: root.statusMessage
        statusIsError: root.statusError
        canApply: root.configLoaded && root.dirty && (!root.installed || root.canWrite)
                  && !backgroundField.invalidInput && !foregroundField.invalidInput
        canReload: root.configLoaded || root.statusError
        onApplyRequested: root.applyConfig()
        onReloadRequested: root.reloadConfig()

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 151
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
            Layout.fillWidth: true
            title: "Content"
            iconSource: "qrc:/engine/assets/icons/file.svg"
            description: "Values are saved to card.config.json."
            InspectorPropertyRow {
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
            Layout.fillWidth: true
            title: "Appearance"
            iconSource: "qrc:/engine/assets/icons/image.svg"
            description: "Click a swatch to choose a color. Hex codes update automatically."
            InspectorColorField {
                id: backgroundField
                caption: "Background"
                colorValue: "#FFFFFF"
                enabled: root.configLoaded
            }
            InspectorColorField {
                id: foregroundField
                caption: "Text Color"
                colorValue: "#1F2937"
                enabled: root.configLoaded
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            title: "Layout & Effects"
            iconSource: "qrc:/engine/assets/icons/cube.svg"
            InspectorPropertyRow {
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
            expanded: false
            description: "Computed information only; it does not modify the React component."
            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: "Text contrast ratio"
                    font.pixelSize: 10
                    color: Theme.colors.muted
                }
                Label {
                    text: root.contrast.toFixed(2) + ":1"
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.colors.text
                }
                Label {
                    text: root.contrast >= 4.5 ? "AA" : "LOW"
                    font.pixelSize: 10
                    color: root.contrast >= 4.5 ? "#42B883" : Theme.colors.error
                }
            }
            Label {
                Layout.fillWidth: true
                text: "Normal-sized text generally needs at least 4.5:1 contrast for WCAG AA."
                font.pixelSize: 10
                color: Theme.colors.muted
                wrapMode: Text.WordWrap
            }
        }
    }
}
