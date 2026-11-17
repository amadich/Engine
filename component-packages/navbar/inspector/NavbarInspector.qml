import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Navbar settings stay package-local. Shared Inspector controls are in JeridiEngine.
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
        brandInput.text !== String(savedSettings.brand ?? "My Website")
        || widthInput.value !== Number(savedSettings.widthPercent ?? 100)
        || heightInput.value !== Number(savedSettings.minHeight ?? 64)
        || backgroundField.colorValue !== String(savedSettings.background ?? "#242831").toUpperCase()
        || foregroundField.colorValue !== String(savedSettings.foreground ?? "#F1F4F9").toUpperCase()
        || placementInput.currentIndex !== (savedSettings.placement === "sticky" ? 1 : 0)
        || alignmentInput.currentIndex !== (["start", "center", "end"].indexOf(savedSettings.alignment ?? "end"))
    )

    readonly property var changedProperties: !configLoaded ? [] : [
        { name: "Brand", changed: brandInput.text !== String(savedSettings.brand ?? "My Website") },
        { name: "Width", changed: widthInput.value !== Number(savedSettings.widthPercent ?? 100) },
        { name: "Minimum height", changed: heightInput.value !== Number(savedSettings.minHeight ?? 64) },
        { name: "Background", changed: backgroundField.colorValue !== String(savedSettings.background ?? "#242831").toUpperCase() },
        { name: "Text color", changed: foregroundField.colorValue !== String(savedSettings.foreground ?? "#F1F4F9").toUpperCase() },
        { name: "Placement", changed: placementInput.currentIndex !== (savedSettings.placement === "sticky" ? 1 : 0) },
        { name: "Links alignment", changed: alignmentInput.currentIndex !== ["start", "center", "end"].indexOf(savedSettings.alignment ?? "end") }
    ].filter(function(item) { return item.changed }).map(function(item) { return item.name })
    function reloadConfig() {
        configLoaded = false
        statusError = false
        statusMessage = ""
        originalConfigText = ""
        installed = componentManager.isInstalled("navbar")
        configUrl = componentManager.configurationUrl("navbar")
        const details = installed
                      ? controller.inspectFile(configUrl)
                      : { kind: "text", text: componentManager.draftConfiguration("navbar") }
        if (details.error || details.kind !== "text" || details.truncated) {
            statusError = true
            statusMessage = String(details.error || "Unable to read Navbar settings.")
            return
        }
        try {
            const settings = JSON.parse(details.text)
            if (!settings || typeof settings !== "object" || Array.isArray(settings))
                throw new Error("Expected a JSON object")
            brandInput.text = String(settings.brand ?? "My Website")
            widthInput.value = Number(settings.widthPercent ?? 100)
            heightInput.value = Number(settings.minHeight ?? 64)
            backgroundField.colorValue = String(settings.background ?? "#242831").toUpperCase()
            foregroundField.colorValue = String(settings.foreground ?? "#F1F4F9").toUpperCase()
            backgroundField.resetEditor()
            foregroundField.resetEditor()
            placementInput.currentIndex = settings.placement === "sticky" ? 1 : 0
            alignmentInput.currentIndex = settings.alignment === "start" ? 0
                                        : settings.alignment === "center" ? 1 : 2
            originalConfigText = details.text
            savedSettings = {
                brand: brandInput.text, widthPercent: widthInput.value,
                minHeight: heightInput.value, background: backgroundField.colorValue,
                foreground: foregroundField.colorValue,
                placement: placementInput.currentIndex === 1 ? "sticky" : "flow",
                alignment: ["start", "center", "end"][alignmentInput.currentIndex]
            }
            configLoaded = true
            if (!installed)
                statusMessage = "Draft mode: Apply updates the preview, not project files."
        } catch (error) {
            statusError = true
            statusMessage = "Invalid navbar.config.json: " + error.message
        }
    }

    function applyConfig() {
        if (!configLoaded || (installed && !canWrite)) return
        if (!brandInput.text.trim() || backgroundField.invalidInput || foregroundField.invalidInput
                || !hexColor.test(backgroundField.colorValue)
                || !hexColor.test(foregroundField.colorValue)) {
            statusError = true
            statusMessage = "Brand and valid #RRGGBB colors are required."
            return
        }
        try {
            const settings = JSON.parse(originalConfigText)
            settings.brand = brandInput.text.trim()
            settings.widthPercent = widthInput.value
            settings.minHeight = heightInput.value
            settings.background = backgroundField.colorValue
            settings.foreground = foregroundField.colorValue
            settings.placement = placementInput.currentIndex === 1 ? "sticky" : "flow"
            settings.alignment = ["start", "center", "end"][alignmentInput.currentIndex]
            const nextText = JSON.stringify(settings, null, 2) + "\n"
            const error = installed
                ? controller.saveTextFile(configUrl, originalConfigText, nextText)
                : componentManager.setDraftConfiguration("navbar", nextText)
            if (error) {
                statusError = true
                statusMessage = error
                return
            }
            originalConfigText = nextText
            brandInput.text = settings.brand
            savedSettings = {
                brand: settings.brand, widthPercent: settings.widthPercent,
                minHeight: settings.minHeight, background: settings.background,
                foreground: settings.foreground, placement: settings.placement,
                alignment: settings.alignment
            }
            statusError = false
            statusMessage = installed ? "Navbar settings saved." : "Draft updated; no project files changed."
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
        function onComponentInstalled(id) { if (id === "navbar") root.reloadConfig() }
        function onComponentMoved(id) { if (id === "navbar") root.reloadConfig() }
        function onComponentRemoved(id) { if (id === "navbar") root.reloadConfig() }
    }

    InspectorScaffold {
        id: inspectorShell
        anchors.fill: parent
        controller: root.controller
        componentManager: root.componentManager
        componentId: "navbar"
        componentName: "Navbar"
        description: "React · Navigation"
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
            Layout.preferredHeight: 105
            visible: inspectorShell.previewVisible && (!inspectorShell.hasSearch
                     || "preview navbar visual schematic".indexOf(inspectorShell.filterText) >= 0)
            color: Theme.colors.canvas
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 7
                Label {
                    text: "SCHEMATIC PREVIEW"
                    color: Theme.colors.muted
                    font.pixelSize: 9
                    font.bold: true
                }
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * widthInput.value / 100
                    Layout.preferredHeight: Math.min(63, Math.max(32, heightInput.value * 0.65))
                    radius: 3
                    color: root.hexColor.test(backgroundField.colorValue)
                           ? backgroundField.colorValue : Theme.colors.control
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 7
                        Label {
                            Layout.preferredWidth: parent.width * 0.38
                            text: brandInput.text || "Brand"
                            color: root.hexColor.test(foregroundField.colorValue)
                                   ? foregroundField.colorValue : Theme.colors.text
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Home   About   Contact"
                            color: root.hexColor.test(foregroundField.colorValue)
                                   ? foregroundField.colorValue : Theme.colors.text
                            font.pixelSize: 9
                            elide: Text.ElideRight
                            horizontalAlignment: alignmentInput.currentIndex === 0
                                ? Text.AlignLeft : alignmentInput.currentIndex === 1
                                ? Text.AlignHCenter : Text.AlignRight
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
            filterKeywords: "brand title text"
            iconSource: "qrc:/engine/assets/icons/file.svg"
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: contentSection.sectionTitleMatches
                caption: "Brand"
                helpText: "Text shown on the left side of the navigation bar."
                InspectorTextField {
                    id: brandInput
                    Layout.fillWidth: true
                    text: "My Website"
                    enabled: root.configLoaded
                }
            }
        }

        InspectorSection {
            id: layoutSection
            Layout.fillWidth: true
            title: "Layout"
            filterQuery: inspectorShell.filterText
            filterKeywords: "layout width height placement sticky align links"
            iconSource: "qrc:/engine/assets/icons/cube.svg"
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: layoutSection.sectionTitleMatches
                caption: "Width"
                helpText: "Navbar width relative to its parent (25–100%)."
                InspectorNumberField {
                    id: widthInput
                    Layout.fillWidth: true
                    from: 25; to: 100; value: 100
                    enabled: root.configLoaded
                }
                Label { text: "%"; font.pixelSize: 10; color: Theme.colors.muted }
            }
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: layoutSection.sectionTitleMatches
                caption: "Min. Height"
                helpText: "CSS minimum height in pixels."
                InspectorNumberField {
                    id: heightInput
                    Layout.fillWidth: true
                    from: 40; to: 160; value: 64
                    enabled: root.configLoaded
                }
                Label { text: "px"; font.pixelSize: 10; color: Theme.colors.muted }
            }
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: layoutSection.sectionTitleMatches
                caption: "Placement"
                helpText: "Normal document flow or sticky at the top while scrolling."
                InspectorComboBox {
                    id: placementInput
                    Layout.fillWidth: true
                    model: ["Normal Flow", "Sticky Top"]
                    enabled: root.configLoaded
                }
            }
            InspectorPropertyRow {
                filterQuery: inspectorShell.filterText
                showAll: layoutSection.sectionTitleMatches
                caption: "Links Align"
                helpText: "Alignment of the hard-coded Home/About/Contact links."
                InspectorComboBox {
                    id: alignmentInput
                    Layout.fillWidth: true
                    model: ["Left", "Center", "Right"]
                    currentIndex: 2
                    enabled: root.configLoaded
                }
            }
        }

        InspectorSection {
            id: colorsSection
            Layout.fillWidth: true
            title: "Colors"
            filterQuery: inspectorShell.filterText
            filterKeywords: "color background text hex palette"
            iconSource: "qrc:/engine/assets/icons/image.svg"
            description: "Click a swatch for a live HSV color palette and HEX output."
            InspectorColorField {
                filterQuery: inspectorShell.filterText
                showAll: colorsSection.sectionTitleMatches
                id: backgroundField
                caption: "Background"
                colorValue: "#242831"
                enabled: root.configLoaded
            }
            InspectorColorField {
                filterQuery: inspectorShell.filterText
                showAll: colorsSection.sectionTitleMatches
                id: foregroundField
                caption: "Text Color"
                colorValue: "#F1F4F9"
                enabled: root.configLoaded
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
            title: "Layout Presets"
            iconSource: "qrc:/engine/assets/icons/star.svg"
            filterQuery: inspectorShell.filterText
            filterKeywords: "presets width full narrow compact height"
            expanded: false
            description: "Presets only change supported width and height settings."
            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                InspectorActionButton {
                    Layout.fillWidth: true
                    text: "Compact"
                    actionEnabled: root.configLoaded
                    hint: "Width 75%, min height 56px"
                    onClicked: { widthInput.value = 75; heightInput.value = 56 }
                }
                InspectorActionButton {
                    Layout.fillWidth: true
                    text: "Full Width"
                    actionEnabled: root.configLoaded
                    hint: "Width 100%, min height 64px"
                    onClicked: { widthInput.value = 100; heightInput.value = 64 }
                }
            }
            Label {
                Layout.fillWidth: true
                text: "Presets are not saved until you apply changes."
                font.pixelSize: 9
                color: Theme.colors.muted
                wrapMode: Text.WordWrap
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            title: "Pending Changes"
            iconSource: "qrc:/engine/assets/icons/preview.svg"
            filterQuery: inspectorShell.filterText
            filterKeywords: "pending changes edits modified unsaved"
            filterAllowed: root.dirty
            tag: root.changedProperties.length + " EDITS"
            expanded: false
            InspectorChangeList {
                changes: root.changedProperties
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            title: "Implementation Notes"
            filterQuery: inspectorShell.filterText
            filterKeywords: "notes implementation limitations hardcoded links"
            iconSource: "qrc:/engine/assets/icons/file.svg"
            expanded: false
            description: "A description of supported and unsupported settings."
            Label {
                Layout.fillWidth: true
                text: root.installed ? root.configUrl.toString() : "Draft configuration (not written to disk)"
                font.pixelSize: 9
                color: Theme.colors.muted
                wrapMode: Text.WrapAnywhere
            }
            Label {
                Layout.fillWidth: true
                text: "The Home / About / Contact labels and destinations are currently defined in EngineNavbar.tsx. The Inspector can align them, but cannot edit their text or URLs yet."
                color: Theme.colors.muted
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                text: "Changes here affect navbar.config.json only."
                color: Theme.colors.muted
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }
}
