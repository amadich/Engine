import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Read-only WCAG contrast check for opaque #RRGGBB colors.
// Shared by Card and Navbar; it does not write any configuration values.
ColumnLayout {
    id: root
    property string backgroundColor: "#FFFFFF"
    property string foregroundColor: "#000000"
    readonly property bool validColors: /^#[0-9a-fA-F]{6}$/.test(backgroundColor)
                                       && /^#[0-9a-fA-F]{6}$/.test(foregroundColor)
    readonly property real ratio: validColors ? calculateRatio(backgroundColor, foregroundColor) : 0
    Layout.fillWidth: true
    spacing: 5

    function luminance(hex) {
        const rgb = [1, 3, 5].map(function(index) {
            const channel = parseInt(hex.slice(index, index + 2), 16) / 255
            return channel <= 0.04045 ? channel / 12.92
                   : Math.pow((channel + 0.055) / 1.055, 2.4)
        })
        return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722
    }
    function calculateRatio(a, b) {
        const l1 = luminance(a)
        const l2 = luminance(b)
        return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 5
        Image {
            source: "qrc:/engine/assets/icons/warning_2.svg"
            sourceSize: Qt.size(24, 24)
            Layout.preferredWidth: 13
            Layout.preferredHeight: 13
        }
        Label {
            Layout.fillWidth: true
            text: "Text contrast"
            font.pixelSize: 10
            color: Theme.colors.muted
        }
        Label {
            text: root.validColors ? root.ratio.toFixed(2) + ":1" : "Invalid HEX"
            font.pixelSize: 10
            font.bold: true
            color: Theme.colors.text
        }
        Label {
            text: !root.validColors ? "N/A" : root.ratio >= 7 ? "AAA"
                  : root.ratio >= 4.5 ? "AA" : "LOW"
            font.pixelSize: 9
            font.bold: true
            color: root.validColors && root.ratio >= 4.5 ? "#22A878" : Theme.colors.error
        }
    }
    Label {
        Layout.fillWidth: true
        text: !root.validColors ? "Enter valid #RRGGBB values to calculate contrast."
              : root.ratio >= 7 ? "Meets WCAG AAA for normal-sized text."
              : root.ratio >= 4.5 ? "Meets WCAG AA for normal-sized text."
              : "Below WCAG AA's 4.5:1 target for normal-sized text."
        font.pixelSize: 9
        color: root.validColors && root.ratio >= 4.5 ? Theme.colors.muted : Theme.colors.error
        wrapMode: Text.WordWrap
    }
}
