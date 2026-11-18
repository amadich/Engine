import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// A persistent shell around each tool window. Moving it does not recreate its content.
Rectangle {
    id: root
    default property alias dockContent: body.data
    property string panelId: ""
    property string panelTitle: "Panel"
    property string panelSubtitle: ""
    property string iconName: "cube.svg"
    property string zone: "left"
    property bool fillDock: false
    property bool canMoveUp: false
    property bool canMoveDown: false
    property bool focused: false

    signal moveRequested(string panelId, string zone)
    signal reorderRequested(string panelId, int offset)
    signal hideRequested(string panelId)
    signal focusRequested(string panelId)

    implicitWidth: 250
    implicitHeight: 230
    color: Theme.colors.panel
    border.width: 1
    border.color: Theme.colors.border
    clip: true
    property real preferredDockHeight: panelId === "output" ? 250 : 260
    Layout.fillWidth: true
    Layout.fillHeight: fillDock
    Layout.minimumHeight: 120
    Layout.preferredHeight: preferredDockHeight

    component DockTool: ToolButton {
        id: tool
        property string tip: ""
        implicitWidth: 24
        implicitHeight: 23
        padding: 0
        hoverEnabled: true
        contentItem: Text {
            text: tool.text
            font.pixelSize: 13
            color: tool.enabled ? Theme.colors.text : Theme.colors.disabled
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 3
            color: tool.down ? Theme.colors.selection : tool.hovered ? Theme.colors.hover : "transparent"
        }
        ToolTip.visible: tool.hovered && tool.tip !== ""
        ToolTip.text: tool.tip
        ToolTip.delay: 550
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: Theme.colors.control
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 5
                spacing: 5
                Image {
                    source: "qrc:/engine/assets/icons/" + root.iconName
                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 15
                    sourceSize: Qt.size(30, 30)
                    fillMode: Image.PreserveAspectFit
                }
                Label {
                    text: root.panelTitle
                    color: Theme.colors.text
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    text: root.zone.toUpperCase()
                    color: Theme.colors.muted
                    font.pixelSize: 9
                    visible: root.width > 250
                }
                DockTool {
                    text: "↑"
                    tip: "Move panel up"
                    enabled: root.canMoveUp
                    onClicked: root.reorderRequested(root.panelId, -1)
                }
                DockTool {
                    text: "↓"
                    tip: "Move panel down"
                    enabled: root.canMoveDown
                    onClicked: root.reorderRequested(root.panelId, 1)
                }
                DockTool {
                    id: moreButton
                    text: "⋯"
                    tip: "Dock options and location"
                    onClicked: dockMenu.popup()
                }
                DockTool {
                    text: "×"
                    tip: "Hide panel (reopen from Workspace bar)"
                    onClicked: root.hideRequested(root.panelId)
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.colors.border
            }
        }
        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
        }
    }

    Menu {
        id: dockMenu
        parent: moreButton
        y: moreButton.height
        MenuItem { text: "Move to Left"; enabled: root.zone !== "left"; onTriggered: root.moveRequested(root.panelId, "left") }
        MenuItem { text: "Move to Center"; enabled: root.zone !== "center"; onTriggered: root.moveRequested(root.panelId, "center") }
        MenuItem { text: "Move to Right"; enabled: root.zone !== "right"; onTriggered: root.moveRequested(root.panelId, "right") }
        MenuSeparator { }
        MenuItem { text: "Move Up"; enabled: root.canMoveUp; onTriggered: root.reorderRequested(root.panelId, -1) }
        MenuItem { text: "Move Down"; enabled: root.canMoveDown; onTriggered: root.reorderRequested(root.panelId, 1) }
        MenuSeparator { }
        MenuItem { text: root.focused ? "Restore Workspace" : "Focus This Panel"; onTriggered: root.focusRequested(root.panelId) }
        MenuItem { text: "Hide Panel"; onTriggered: root.hideRequested(root.panelId) }
    }
    // Resize the panel above its neighbour in a vertical dock stack.
    // The final/filling panel takes the remaining available height.
    Rectangle {
        id: verticalResizeGrip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 5
        z: 10
        color: resizeArea.containsMouse ? Theme.colors.accent : "transparent"
        visible: !root.fillDock && root.visible && root.canMoveDown
        MouseArea {
            id: resizeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SplitVCursor
            property real startingHeight: 0
            property real startingY: 0
            onPressed: function(mouse) {
                startingHeight = root.height
                startingY = mapToItem(null, mouse.x, mouse.y).y
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return
                var nowY = mapToItem(null, mouse.x, mouse.y).y
                root.preferredDockHeight = Math.max(120, Math.min(850, startingHeight + nowY - startingY))
            }
        }
    }

}
