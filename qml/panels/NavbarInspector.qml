import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root

    required property ProjectController controller

    property url configUrl: ""
    property string originalConfigText: ""
    property bool configLoaded: false
    property bool installed: false
    property string statusMessage: ""

    readonly property var hexColor: /^#[0-9a-fA-F]{6}$/
    readonly property bool readyToEdit: configLoaded && installed
    readonly property bool canWrite: controller.activeProjectPath !== ""
                                     && (!controller.busy
                                         || controller.devServerActive)

    color: Theme.colors.panel

    Component.onCompleted: reloadConfig()

    function reloadConfig() {
        configLoaded = false
        installed = false
        originalConfigText = ""
        statusMessage = ""
        configUrl = controller.navbarConfigUrl()

        if (configUrl.toString() === "")
            return

        const details = controller.inspectFile(configUrl)

        if (details.error || details.kind !== "text" || details.truncated) {
            statusMessage = "Use Add to Project to install the Navbar files."
            return
        }

        try {
            const settings = JSON.parse(details.text)

            if (!settings || typeof settings !== "object" || Array.isArray(settings))
                throw new Error("Expected a JSON object.")

            brandInput.text = settings.brand ?? "My Website"
            widthInput.value = settings.widthPercent ?? 100
            heightInput.value = settings.minHeight ?? 64
            backgroundInput.text = settings.background ?? "#242831"
            foregroundInput.text = settings.foreground ?? "#F1F4F9"
            placementInput.currentIndex = settings.placement === "sticky" ? 1 : 0
            alignmentInput.currentIndex = settings.alignment === "start" ? 0
                                        : settings.alignment === "center" ? 1 : 2

            originalConfigText = details.text
            configLoaded = true
        } catch (error) {
            statusMessage = "Invalid navbar.config.json: " + error.message
        }

        // Confirm that the TSX file exists as well as the configuration.
        const componentUrl = configUrl.toString().replace(
            /navbar\.config\.json$/, "EngineNavbar.tsx")
        const component = controller.inspectFile(componentUrl)
        installed = !component.error && component.kind === "text"

        if (configLoaded && !installed)
            statusMessage = "Use Add to Project to install EngineNavbar.tsx."
    }

    function applyConfig() {
        const brand = brandInput.text.trim()
        const background = backgroundInput.text.trim()
        const foreground = foregroundInput.text.trim()

        if (brand === "" || !hexColor.test(background)
                || !hexColor.test(foreground)) {
            statusMessage = "Enter a brand and two colors in #RRGGBB format."
            return
        }

        const settings = JSON.parse(originalConfigText)
        settings.brand = brand
        settings.widthPercent = widthInput.value
        settings.minHeight = heightInput.value
        settings.background = background
        settings.foreground = foreground
        settings.placement = placementInput.currentIndex === 1 ? "sticky" : "flow"
        settings.alignment = ["start", "center", "end"][alignmentInput.currentIndex]

        const nextText = JSON.stringify(settings, null, 2) + "\n"
        const error = controller.saveTextFile(configUrl, originalConfigText, nextText)

        if (error) {
            statusMessage = error
            return
        }

        originalConfigText = nextText
        statusMessage = "Navbar settings saved."
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 12
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 10

            Label {
                text: "INSPECTOR · NAVBAR"
                font.bold: true
                color: Theme.colors.accent
            }

            Label {
                Layout.fillWidth: true
                text: "src/components/navbar/EngineNavbar.tsx"
                color: Theme.colors.muted
                wrapMode: Text.WrapAnywhere
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 80

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * widthInput.value / 100
                    height: Math.min(parent.height, heightInput.value / 2)
                    radius: 5
                    clip: true
                    color: root.hexColor.test(backgroundInput.text.trim())
                           ? backgroundInput.text.trim() : Theme.colors.control

                    Label {
                        anchors.fill: parent
                        anchors.margins: 6
                        text: brandInput.text
                        color: root.hexColor.test(foregroundInput.text.trim())
                               ? foregroundInput.text.trim() : Theme.colors.text
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: alignmentInput.currentIndex === 0
                            ? Text.AlignLeft : alignmentInput.currentIndex === 1
                            ? Text.AlignHCenter : Text.AlignRight
                        font.bold: true
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 6
                enabled: root.readyToEdit

                Label { text: "Brand" }
                TextField {
                    id: brandInput
                    Layout.fillWidth: true
                    text: "My Website"
                }

                Label { text: "Width (%)" }
                SpinBox {
                    id: widthInput
                    Layout.fillWidth: true
                    from: 25
                    to: 100
                    value: 100
                    editable: true
                }

                Label { text: "Min. height" }
                SpinBox {
                    id: heightInput
                    Layout.fillWidth: true
                    from: 40
                    to: 160
                    value: 64
                    editable: true
                }

                Label { text: "Background" }
                TextField {
                    id: backgroundInput
                    Layout.fillWidth: true
                    text: "#242831"
                }

                Label { text: "Text color" }
                TextField {
                    id: foregroundInput
                    Layout.fillWidth: true
                    text: "#F1F4F9"
                }

                Label { text: "Placement" }
                ComboBox {
                    id: placementInput
                    Layout.fillWidth: true
                    model: ["Normal flow", "Sticky top"]
                }

                Label { text: "Links" }
                ComboBox {
                    id: alignmentInput
                    Layout.fillWidth: true
                    model: ["Left", "Center", "Right"]
                    currentIndex: 2
                }
            }

            Button {
                Layout.fillWidth: true
                visible: !root.installed
                enabled: root.canWrite
                text: "Add to Project"

                onClicked: {
                    const error = root.controller.installNavbar()

                    if (error)
                        root.statusMessage = error
                    else
                        root.reloadConfig()
                }
            }

            Button {
                Layout.fillWidth: true
                visible: root.installed
                enabled: root.canWrite && root.readyToEdit
                text: "Apply"
                onClicked: root.applyConfig()
            }

            Button {
                Layout.fillWidth: true
                visible: root.configUrl.toString() !== ""
                text: "Reload settings"
                onClicked: root.reloadConfig()
            }

            Label {
                Layout.fillWidth: true
                text: root.controller.activeProjectPath === ""
                      ? "Open a React project to install this component."
                      : root.statusMessage
                visible: text !== ""
                color: Theme.colors.muted
                wrapMode: Text.WordWrap
            }
        }
    }
}