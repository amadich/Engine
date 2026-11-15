
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Menu {
    id: menu

    required property TextArea editor

    signal saveRequested()

    width: 282
    padding: 6
    popupType: Popup.Item

    readonly property bool isMac: Qt.platform.os === "osx"

    readonly property color foreground: Theme.colors.text
    readonly property color surface: Theme.colors.control
    readonly property color accent: "#629BEB"
    readonly property color hoverSurface: Theme.colors.selection

    readonly property color secondary:
        Qt.rgba(foreground.r, foreground.g, foreground.b, 0.55)

    readonly property color separator:
        Qt.rgba(foreground.r, foreground.g, foreground.b, 0.13)

    function key(mac, other) {
        return isMac ? mac : other
    }

    background: Rectangle {
        color: menu.surface
        radius: 9
        border.width: 1
        border.color: menu.separator
    }

    // ==========================================
    // REUSABLE MENU ITEM (SAME FILE)
    // ==========================================

    Component {
        id: actionComponent

        MenuItem {
            id: action

            property string symbol: ""
            property string shortcutText: ""
            property string actionId: ""

            implicitWidth: 270
            implicitHeight: 33

            leftPadding: 10
            rightPadding: 10
            topPadding: 0
            bottomPadding: 0

            contentItem: RowLayout {
                spacing: 10

                Label {
                    Layout.preferredWidth: 20

                    text: action.symbol
                    color: menu.foreground

                    font.pixelSize: 15

                    horizontalAlignment: Text.AlignHCenter

                    opacity: action.enabled ? 0.85 : 0.3
                }

                Label {
                    Layout.fillWidth: true

                    text: action.text
                    color: menu.foreground

                    font.pixelSize: 12

                    opacity: action.enabled ? 1.0 : 0.4

                    elide: Text.ElideRight
                }

                Label {
                    text: action.shortcutText
                    color: menu.secondary
                    font.pixelSize: 11

                    opacity: action.enabled ? 1.0 : 0.4
                }
            }

            background: Rectangle {
                radius: 5

                color: action.highlighted && action.enabled
                       ? menu.hoverSurface
                       : "transparent"
            }

            onTriggered: menu.executeAction(action.actionId)
        }
    }

    // ==========================================
    // ACTION LOGIC
    // ==========================================

    function executeAction(actionId) {
        switch (actionId) {
        case "undo":
            editor.undo()
            break

        case "redo":
            editor.redo()
            break

        case "cut":
            editor.cut()
            break

        case "copy":
            editor.copy()
            break

        case "paste":
            editor.paste()
            break

        case "delete":
            editor.remove(
                editor.selectionStart,
                editor.selectionEnd
            )
            break

        case "selectAll":
            editor.selectAll()
            break

        case "save":
            saveRequested()
            break
        }
    }

    // ==========================================
    // ACTION DEFINITIONS
    // ==========================================

    ListModel {
        id: actionModel

        ListElement {
            title: "Undo"
            symbol: "↶"
            actionId: "undo"
            group: 0
        }

        ListElement {
            title: "Redo"
            symbol: "↷"
            actionId: "redo"
            group: 0
        }

        ListElement {
            title: "Cut"
            symbol: "✂"
            actionId: "cut"
            group: 1
        }

        ListElement {
            title: "Copy"
            symbol: "▢"
            actionId: "copy"
            group: 1
        }

        ListElement {
            title: "Paste"
            symbol: "▣"
            actionId: "paste"
            group: 1
        }

        ListElement {
            title: "Delete"
            symbol: "⌫"
            actionId: "delete"
            group: 1
        }

        ListElement {
            title: "Select All"
            symbol: "☷"
            actionId: "selectAll"
            group: 2
        }

        ListElement {
            title: "Save File"
            symbol: "↓"
            actionId: "save"
            group: 3
        }
    }

    // ==========================================
    // HEADER
    // ==========================================

    MenuItem {
        height: 38
        enabled: false

        contentItem: RowLayout {
            spacing: 8

            Label {
                text: "⌘"
                color: menu.accent
                font.pixelSize: 18
                font.bold: true
            }

            Label {
                text: "Jeridi Editor"
                color: menu.foreground
                font.pixelSize: 12
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                text: "EDITOR ACTIONS"
                color: menu.secondary
                font.pixelSize: 9
            }
        }

        background: Item {}
    }

    MenuSeparator {}

    // ==========================================
    // GENERATE MENU ITEMS
    // ==========================================

    Instantiator {
        model: actionModel

        delegate: Loader {
            id: itemLoader

            required property string title
            required property string symbol
            required property string actionId
            required property int group

            sourceComponent: actionComponent

            onLoaded: {
                item.text = title
                item.symbol = symbol
                item.actionId = actionId

                switch (actionId) {
                case "undo":
                    item.shortcutText =
                        menu.key("⌘Z", "Ctrl+Z")
                    break

                case "redo":
                    item.shortcutText =
                        menu.key("⇧⌘Z", "Ctrl+Shift+Z")
                    break

                case "cut":
                    item.shortcutText =
                        menu.key("⌘X", "Ctrl+X")
                    break

                case "copy":
                    item.shortcutText =
                        menu.key("⌘C", "Ctrl+C")
                    break

                case "paste":
                    item.shortcutText =
                        menu.key("⌘V", "Ctrl+V")
                    break

                case "delete":
                    item.shortcutText = "Del"
                    break

                case "selectAll":
                    item.shortcutText =
                        menu.key("⌘A", "Ctrl+A")
                    break

                case "save":
                    item.shortcutText =
                        menu.key("⌘S", "Ctrl+S")
                    break
                }
            }
        }

        onObjectAdded: function(index, object) {
            if (object.item)
                menu.insertItem(index + 2, object.item)
        }

        onObjectRemoved: function(index, object) {
            if (object.item)
                menu.removeItem(object.item)
        }
    }

    // ==========================================
    // UPDATE ENABLED STATES
    // ==========================================

    function refreshActions() {
        for (let i = 0; i < menu.count; ++i) {
            const item = menu.itemAt(i)

            if (!item || !item.actionId)
                continue

            switch (item.actionId) {
            case "undo":
                item.enabled = editor.canUndo
                break

            case "redo":
                item.enabled = editor.canRedo
                break

            case "cut":
            case "copy":
            case "delete":
                item.enabled = editor.selectedText.length > 0
                break

            default:
                item.enabled = true
                break
            }
        }
    }

    onAboutToShow: refreshActions()
}
