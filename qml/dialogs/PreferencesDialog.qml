import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Dialog {
    id: root

    title: "Preferences"
    modal: true
    popupType: Popup.Window
    anchors.centerIn: parent
    width: 460
    padding: 20
    standardButtons: Dialog.Close

    background: Rectangle {
        radius: 12
        color: Theme.colors.panel
        border.color: Theme.colors.border
    }

    contentItem: ColumnLayout {
        spacing: 12

        Label {
            text: "Appearance"
            font.pixelSize: 18
            font.bold: true
            color: Theme.colors.text
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Label {
                Layout.fillWidth: true
                text: "Color theme"
                color: Theme.colors.text
            }

            RowLayout {
                spacing: 6

                Repeater {
                    model: [
                        { label: "Light", value: "light" },
                        { label: "Dark", value: "dark" }
                    ]

                    delegate: Button {
                        id: themeButton

                        required property var modelData
                        readonly property bool selectedTheme:
                            Theme.appearance === modelData.value

                        Layout.preferredWidth: 84
                        Layout.preferredHeight: 36
                        text: modelData.label
                        Accessible.name: text + (selectedTheme ? ", selected" : "")

                        onClicked: Theme.appearance = modelData.value

                        contentItem: Text {
                            text: themeButton.text
                            color: Theme.colors.text
                            font.bold: themeButton.selectedTheme
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 7
                            color: themeButton.selectedTheme ? Theme.colors.selection
                                 : themeButton.hovered ? Theme.colors.hover
                                 : Theme.colors.control

                            border.width: themeButton.selectedTheme
                                          || themeButton.visualFocus ? 1 : 0
                            border.color: Theme.colors.accent
                        }
                    }
                }
            }
        }
    }
}