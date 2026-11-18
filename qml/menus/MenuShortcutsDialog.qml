import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Dialog {
    id: root
    title: "Keyboard Shortcuts"
    modal: true
    popupType: Popup.Window
    anchors.centerIn: parent
    width: Math.min(580, parent.width - 36)
    height: Math.min(590, parent.height - 40)
    padding: 0
    standardButtons: Dialog.Close
    readonly property bool mac: Qt.platform.os === "osx"
    function key(macKey, other) { return mac ? macKey : other }

    background: Rectangle {
        color: Theme.colors.panel
        border.width: 1
        border.color: Theme.colors.border
        radius: 7
    }

    contentItem: ColumnLayout {
        spacing: 0
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: Theme.colors.control
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                Image { source: "qrc:/engine/assets/icons/select-all.svg"; Layout.preferredWidth: 20; Layout.preferredHeight: 20 }
                Label { text: "KEYBOARD REFERENCE"; color: Theme.colors.text; font.bold: true; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
                Label { text: root.mac ? "macOS" : "Windows / Linux"; color: Theme.colors.muted; font.pixelSize: 10 }
            }
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                width: Math.max(340, root.width - 32)
                spacing: 2
                Repeater {
                    model: [
                        {section:"PROJECT", label:"", key:""},
                        {section:"", label:"New Project", key:root.key("⇧⌘N","Ctrl+Shift+N")},
                        {section:"", label:"Open Project", key:root.key("⌘O","Ctrl+O")},
                        {section:"", label:"Quick Open File", key:root.key("⌘P","Ctrl+P")},
                        {section:"", label:"Save File", key:root.key("⌘S","Ctrl+S")},
                        {section:"", label:"Save All", key:root.key("⇧⌘S","Ctrl+Shift+S")},
                        {section:"", label:"Close Editor", key:root.key("⌘W","Ctrl+W")},
                        {section:"", label:"Close Project", key:root.key("⇧⌘W","Ctrl+Shift+W")},
                        {section:"EDITOR", label:"", key:""},
                        {section:"", label:"Find in File", key:root.key("⌘F","Ctrl+F")},
                        {section:"", label:"Find Next", key:root.key("⌘G","Ctrl+G")},
                        {section:"", label:"Go to Line", key:root.key("⌘L","Ctrl+L")},
                        {section:"", label:"Copy File Path", key:root.key("⌥⌘C","Ctrl+Alt+C")},
                        {section:"", label:"Next / Previous Tab", key:root.key("⌃⇥ / ⌃⇧⇥","Ctrl+Tab / Ctrl+Shift+Tab")},
                        {section:"", label:"Font Zoom", key:root.key("⌘+ / ⌘− / ⌘0","Ctrl++ / Ctrl+- / Ctrl+0")},
                        {section:"WORKSPACE", label:"", key:""},
                        {section:"", label:"Toggle Project Explorer", key:root.key("⌘1","Ctrl+1")},
                        {section:"", label:"Toggle Output Console", key:root.key("⌘2","Ctrl+2")},
                        {section:"", label:"Show Both Panels", key:root.key("⇧⌘0","Ctrl+Shift+0")},
                        {section:"", label:"Run / Stop", key:root.key("⌃F5 / Shift+F5","Ctrl+F5 / Shift+F5")},
                        {section:"", label:"Preferences", key:root.key("⌘,","Ctrl+,")},
                        {section:"", label:"Shortcuts Reference", key:root.key("⇧⌘K","Ctrl+Shift+K")}
                    ]
                    delegate: Item {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: modelData.section ? 37 : 29
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            Rectangle {
                                visible: !modelData.section
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: Theme.colors.border
                                opacity: 0.35
                            }
                        }
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.section || modelData.label
                            color: modelData.section ? Theme.colors.accent : Theme.colors.text
                            font.pixelSize: modelData.section ? 10 : 12
                            font.bold: !!modelData.section
                            font.letterSpacing: modelData.section ? 0.7 : 0
                        }
                        Label {
                            visible: !modelData.section
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.key
                            color: Theme.colors.muted
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
