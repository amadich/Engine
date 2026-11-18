import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

Rectangle {
    id: root

    required property var documents
    required property int activeTab
    required property bool currentDirty
    required property color toolbarColor
    required property color activeColor
    required property color inactiveColor
    required property color accentColor
    required property color mutedText
    required property color hoverColor

    signal tabRequested(int index)
    signal closeRequested(int index)
    signal saveRequested()

    function revealLastTab() {
        tabs.positionViewAtEnd()
    }

    function fileIcon(fileName) {
        const name = fileName.toLowerCase()

        if (/\.(png|jpe?g|svg|webp|gif|bmp)$/.test(name)) return "image.svg"
        if (/\.(tsx|jsx)$/.test(name)) return "lang/react.svg"
        if (/\.(ts|js)$/.test(name)) return "lang/javascript.svg"
        if (name.endsWith(".vue")) return "lang/vuejs.svg"
        if (name.endsWith(".html")) return "lang/html5.svg"
        if (name.endsWith(".java")) return "lang/spring.svg"
        if (name.endsWith(".json")) return "file.svg"
        return "file.svg"
    }

    Layout.fillWidth: true
    Layout.preferredHeight: 44

    color: root.toolbarColor

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        spacing: 6

        // --------------------------------------
        // PREVIEW TAB
        // --------------------------------------

        Rectangle {
            id: previewTab

            Layout.preferredWidth: 110
            Layout.fillHeight: true

            color: root.activeTab === -1
                ? root.activeColor
                : "transparent"

            radius: 5

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 2

                color: root.activeTab === -1
                    ? root.accentColor
                    : "transparent"
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Image {
                    source: "qrc:/engine/assets/icons/forest.svg"

                    Layout.preferredWidth: 17
                    Layout.preferredHeight: 17

                    sourceSize.width: 34
                    sourceSize.height: 34

                    fillMode: Image.PreserveAspectFit
                }

                Label {
                    text: "Preview"
                    color: Theme.colors.text
                    font.pixelSize: 13
                    font.weight: root.activeTab === -1
                        ? Font.DemiBold
                        : Font.Normal
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: root.tabRequested(-1)
            }
        }

        // --------------------------------------
        // OPEN FILE TABS
        // --------------------------------------

        ListView {
            id: tabs

            Layout.fillWidth: true
            Layout.fillHeight: true

            orientation: ListView.Horizontal
            flickableDirection: Flickable.HorizontalFlick

            boundsBehavior: Flickable.StopAtBounds

            clip: true
            spacing: 3

            model: root.documents

            onCountChanged: {
                if (count > 0)
                    positionViewAtEnd()
            }

            delegate: Rectangle {
                id: tab

                required property int index
                required property string name
                required property string relativePath
                required property bool dirty

                readonly property bool selected:
                    root.activeTab === index

                readonly property bool hovered:
                    tabHover.hovered

                width: 190
                height: tabs.height

                radius: 5

                color: selected
                    ? root.activeColor
                    : hovered
                        ? root.hoverColor
                        : root.inactiveColor

                // Active indicator
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: 2

                    color: tab.selected
                        ? root.accentColor
                        : "transparent"
                }

                HoverHandler {
                    id: tabHover
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6

                    spacing: 8

                    // File icon
                    Image {
                        Layout.preferredWidth: 17
                        Layout.preferredHeight: 17

                        source: "qrc:/engine/assets/icons/"
                                + root.fileIcon(tab.name)

                        sourceSize.width: 34
                        sourceSize.height: 34

                        fillMode: Image.PreserveAspectFit
                    }

                    // File name
                    Label {
                        Layout.fillWidth: true

                        text: tab.name

                        color: tab.selected
                            ? Theme.colors.text
                            : root.mutedText

                        font.pixelSize: 13

                        font.weight: tab.selected
                            ? Font.DemiBold
                            : Font.Normal

                        elide: Text.ElideMiddle

                        verticalAlignment: Text.AlignVCenter
                    }

                    // Close / Dirty indicator
                    ToolButton {
                        id: closeButton

                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24

                        hoverEnabled: true

                        background: Rectangle {
                            radius: 5

                            color: closeButton.hovered
                                ? "#9E3D48"
                                : "transparent"
                        }

                        contentItem: Item {
                            Image {
                                anchors.centerIn: parent

                                width: 12
                                height: 12

                                source: "qrc:/engine/assets/icons/close.svg"

                                visible: !tab.dirty
                                         || closeButton.hovered

                                fillMode: Image.PreserveAspectFit
                            }

                            Rectangle {
                                anchors.centerIn: parent

                                width: 7
                                height: 7
                                radius: 4

                                color: root.accentColor

                                visible: tab.dirty
                                         && !closeButton.hovered
                            }
                        }

                        opacity: tab.selected
                                 || tab.hovered
                                 || tab.dirty
                                 ? 1.0 : 0.0

                        ToolTip.visible: hovered
                        ToolTip.text: "Close " + tab.name

                        onClicked: root.closeRequested(tab.index)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1

                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.tabRequested(tab.index)
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.tabRequested(tab.index)
                }
                TapHandler {
                    acceptedButtons: Qt.MiddleButton
                    onTapped: root.closeRequested(tab.index)
                }

                ToolTip.visible: tab.hovered
                                 && !closeButton.hovered

                ToolTip.text: tab.relativePath
                ToolTip.delay: 700
            }
        }

        // --------------------------------------
        // SAVE BUTTON
        // --------------------------------------

        Rectangle {
            Layout.preferredWidth: 86
            Layout.preferredHeight: 32

            radius: 6

            color: saveMouse.containsMouse
                   && root.currentDirty
                   ? root.hoverColor
                   : "transparent"

            opacity: root.currentDirty ? 1.0 : 0.5

            RowLayout {
                anchors.centerIn: parent
                spacing: 7

                Image {
                    source: "qrc:/engine/assets/icons/save.svg"

                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16

                    sourceSize.width: 32
                    sourceSize.height: 32

                    fillMode: Image.PreserveAspectFit
                }

                Label {
                    text: "Save"

                    color: Theme.colors.text
                    font.pixelSize: 13
                }
            }

            MouseArea {
                id: saveMouse

                anchors.fill: parent
                hoverEnabled: true

                enabled: root.currentDirty

                cursorShape: enabled
                             ? Qt.PointingHandCursor
                             : Qt.ArrowCursor

                onClicked: root.saveRequested()
            }
        }
    }
}
