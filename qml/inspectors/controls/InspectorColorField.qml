import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// RGB color picker for #RRGGBB configuration values (no alpha channel).
// The picker uses HSV internally; the public value remains a validated HEX string.
RowLayout {
    id: root
    property string caption: "Color"
    property string helpText: "Click the swatch to open the color palette."
    property string filterQuery: ""
    property bool showAll: false
    property string colorValue: "#FFFFFF"
    property int labelWidth: width < 255 ? 74 : 92
    property real hue: 210
    property real saturation: 0
    property real brightness: 1
    property bool invalidInput: false
    readonly property bool validColor: /^#[0-9a-fA-F]{6}$/.test(colorValue)

    Layout.fillWidth: true
    spacing: 6
    implicitHeight: 25
    visible: filterQuery.trim().length === 0 || showAll
             || caption.toLowerCase().indexOf(filterQuery.toLowerCase()) >= 0
             || helpText.toLowerCase().indexOf(filterQuery.toLowerCase()) >= 0

    function channelHex(v) {
        return Math.round(Math.max(0, Math.min(1, v)) * 255)
            .toString(16).padStart(2, "0").toUpperCase()
    }
    function hsvHex(h, s, v) {
        const c = Qt.hsva(h / 360, s, v, 1)
        return "#" + channelHex(c.r) + channelHex(c.g) + channelHex(c.b)
    }
    function readHSV() {
        if (!validColor)
            return
        const r = parseInt(colorValue.slice(1, 3), 16) / 255
        const g = parseInt(colorValue.slice(3, 5), 16) / 255
        const b = parseInt(colorValue.slice(5, 7), 16) / 255
        const maximum = Math.max(r, g, b)
        const minimum = Math.min(r, g, b)
        const delta = maximum - minimum
        let h = root.hue
        if (delta > 0) {
            if (maximum === r) h = 60 * (((g - b) / delta) % 6)
            else if (maximum === g) h = 60 * ((b - r) / delta + 2)
            else h = 60 * ((r - g) / delta + 4)
            if (h < 0) h += 360
        }
        hue = h
        saturation = maximum === 0 ? 0 : delta / maximum
        brightness = maximum
        if (svCanvas) svCanvas.requestPaint()
    }
    function setHSV(h, s, v) {
        hue = Math.max(0, Math.min(360, h))
        saturation = Math.max(0, Math.min(1, s))
        brightness = Math.max(0, Math.min(1, v))
        colorValue = hsvHex(hue, saturation, brightness)
        invalidInput = false
        if (svCanvas) svCanvas.requestPaint()
    }
    function resetEditor() {
        invalidInput = false
        hexInput.text = colorValue
        readHSV()
    }
    function openPalette() {
        const overlay = Overlay.overlay
        if (!overlay)
            return
        const pos = swatch.mapToItem(overlay, 0, swatch.height + 4)
        palette.x = Math.max(8, Math.min(pos.x - 25, overlay.width - palette.width - 8))
        palette.y = Math.max(8, Math.min(pos.y, overlay.height - palette.height - 8))
        palette.open()
    }

    onColorValueChanged: {
        if (validColor) {
            invalidInput = false
            readHSV()
        }
        if (hexInput && !hexInput.activeFocus)
            hexInput.text = colorValue
    }
    Component.onCompleted: {
        readHSV()
        hexInput.text = colorValue
    }

    Label {
        Layout.preferredWidth: root.labelWidth
        Layout.minimumWidth: 58
        text: root.caption
        color: Theme.colors.muted
        font.pixelSize: 11
        elide: Text.ElideRight
        ToolTip.visible: captionHover.hovered
        ToolTip.text: root.helpText
        ToolTip.delay: 600
        HoverHandler { id: captionHover }
    }

    Rectangle {
        id: swatch
        Layout.preferredWidth: 28
        Layout.preferredHeight: 24
        radius: 3
        color: root.validColor ? root.colorValue : "transparent"
        border.width: 1
        border.color: swatchHover.hovered ? Theme.colors.accent : Theme.colors.border
        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 1
            color: root.validColor ? root.colorValue : Theme.colors.control
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
            onClicked: { if (root.enabled) root.openPalette() }
        }
        ToolTip.visible: swatchHover.hovered
        ToolTip.text: root.enabled ? "Open color picker" : "Configuration not loaded"
        HoverHandler { id: swatchHover }
    }

    InspectorTextField {
        id: hexInput
        Layout.fillWidth: true
        Layout.minimumWidth: 75
        font.family: "Menlo"
        font.pixelSize: 10
        placeholderText: "#RRGGBB"
        onEditingFinished: {
            const candidate = text.trim()
            if (/^#[0-9a-fA-F]{6}$/.test(candidate)) {
                root.colorValue = candidate.toUpperCase()
                root.invalidInput = false
                text = root.colorValue
            } else {
                root.invalidInput = true
            }
        }
        background: Rectangle {
            radius: 3
            color: Theme.colors.surface
            border.width: 1
            border.color: root.invalidInput ? Theme.colors.error
                         : hexInput.activeFocus ? Theme.colors.accent : Theme.colors.border
        }
        ToolTip.visible: root.invalidInput && hexInput.activeFocus
        ToolTip.text: "Use #RRGGBB, for example #2F80ED"
    }

    Popup {
        id: palette
        parent: Overlay.overlay
        width: 264
        height: 347
        padding: 11
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 5
            color: Theme.colors.surface
            border.width: 1
            border.color: Theme.colors.accent
        }

        contentItem: ColumnLayout {
            id: paletteContent
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                Label {
                    Layout.fillWidth: true
                    text: "COLOR PICKER"
                    font.bold: true
                    font.pixelSize: 10
                    color: Theme.colors.text
                }
                Label {
                    text: "RGB · HEX"
                    font.pixelSize: 9
                    color: Theme.colors.muted
                }
            }

            Item {
                id: svArea
                Layout.fillWidth: true
                Layout.preferredHeight: 132
                clip: true

                Canvas {
                    id: svCanvas
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.fillStyle = Qt.hsva(root.hue / 360, 1, 1, 1).toString()
                        ctx.fillRect(0, 0, width, height)
                        const white = ctx.createLinearGradient(0, 0, width, 0)
                        white.addColorStop(0, "rgba(255,255,255,1)")
                        white.addColorStop(1, "rgba(255,255,255,0)")
                        ctx.fillStyle = white
                        ctx.fillRect(0, 0, width, height)
                        const black = ctx.createLinearGradient(0, 0, 0, height)
                        black.addColorStop(0, "rgba(0,0,0,0)")
                        black.addColorStop(1, "rgba(0,0,0,1)")
                        ctx.fillStyle = black
                        ctx.fillRect(0, 0, width, height)
                    }
                }
                Rectangle {
                    width: 11
                    height: 11
                    radius: 6
                    x: root.saturation * (svArea.width - 1) - width / 2
                    y: (1 - root.brightness) * (svArea.height - 1) - height / 2
                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                }
                MouseArea {
                    anchors.fill: parent
                    function choose(px, py) {
                        root.setHSV(root.hue, px / Math.max(1, width),
                                    1 - py / Math.max(1, height))
                    }
                    onPressed: function(mouse) { choose(mouse.x, mouse.y) }
                    onPositionChanged: function(mouse) {
                        if (pressed) choose(mouse.x, mouse.y)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label { text: "H"; color: Theme.colors.muted; font.pixelSize: 10 }
                Slider {
                    id: hueSlider
                    Layout.fillWidth: true
                    implicitHeight: 26
                    from: 0
                    to: 360
                    value: root.hue
                    onMoved: root.setHSV(value, root.saturation, root.brightness)
                    background: Rectangle {
                        x: hueSlider.leftPadding
                        y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                        width: hueSlider.availableWidth
                        height: 9
                        radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#FF0000" }
                            GradientStop { position: 0.167; color: "#FFFF00" }
                            GradientStop { position: 0.333; color: "#00FF00" }
                            GradientStop { position: 0.5; color: "#00FFFF" }
                            GradientStop { position: 0.667; color: "#0000FF" }
                            GradientStop { position: 0.833; color: "#FF00FF" }
                            GradientStop { position: 1; color: "#FF0000" }
                        }
                    }
                    handle: Rectangle {
                        x: hueSlider.leftPadding + hueSlider.visualPosition *
                           (hueSlider.availableWidth - width)
                        y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                        width: 12
                        height: 17
                        radius: 3
                        color: Theme.colors.text
                        border.color: Theme.colors.border
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    Layout.preferredWidth: 31
                    Layout.preferredHeight: 25
                    radius: 3
                    color: root.validColor ? root.colorValue : "transparent"
                    border.color: Theme.colors.border
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label {
                        text: root.colorValue.toUpperCase()
                        font.family: "Menlo"
                        font.pixelSize: 11
                        color: Theme.colors.text
                    }
                    Label {
                        text: "R " + parseInt(root.colorValue.slice(1, 3), 16)
                              + "   G " + parseInt(root.colorValue.slice(3, 5), 16)
                              + "   B " + parseInt(root.colorValue.slice(5, 7), 16)
                        font.pixelSize: 9
                        color: Theme.colors.muted
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.colors.border }

            Label {
                text: "QUICK COLORS"
                font.pixelSize: 9
                font.bold: true
                color: Theme.colors.muted
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 8
                columnSpacing: 6
                rowSpacing: 6
                Repeater {
                    model: ["#FFFFFF", "#111827", "#64748B", "#EF4444",
                            "#F59E0B", "#22C55E", "#06B6D4", "#3B82F6",
                            "#8B5CF6", "#EC4899", "#F3F4F6", "#0F172A",
                            "#9A8AEA", "#2563EB", "#14B8A6", "#F97316"]
                    delegate: Rectangle {
                        required property string modelData
                        Layout.preferredWidth: 23
                        Layout.preferredHeight: 21
                        radius: 3
                        color: modelData
                        border.width: 1
                        border.color: Theme.colors.border
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.colorValue = modelData
                                root.invalidInput = false
                                // palette.close()
                                colorPickerPopup.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
