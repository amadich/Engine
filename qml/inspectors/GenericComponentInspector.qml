import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Used for packages without a custom settings inspector (for example Button).
Item {
    id: root
    required property ProjectController controller
    required property ComponentManager componentManager
    required property string componentId

    readonly property var definition: ComponentRegistry.component(componentId)
    property bool installed: false

    function refreshStatus() {
        installed = componentManager.isInstalled(componentId)
    }
    Component.onCompleted: refreshStatus()
    Connections {
        target: root.componentManager
        function onComponentInstalled(id) { if (id === root.componentId) root.refreshStatus() }
        function onComponentMoved(id) { if (id === root.componentId) root.refreshStatus() }
        function onComponentRemoved(id) { if (id === root.componentId) root.refreshStatus() }
    }
    Connections {
        target: root.controller
        function onActiveProjectChanged() { root.refreshStatus() }
    }

    InspectorScaffold {
        anchors.fill: parent
        controller: root.controller
        componentManager: root.componentManager
        componentId: root.componentId
        componentName: String(root.definition.name || "Component")
        description: "React · Component package"
        installed: root.installed
        showApply: false
        showReload: false

        InspectorSection {
            Layout.fillWidth: true
            title: "Package Contents"
            iconSource: "qrc:/engine/assets/icons/file.svg"
            tag: String((root.definition.files || []).length) + " FILES"
            Repeater {
                model: root.definition.files || []
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 7
                    Image {
                        source: "qrc:/engine/assets/icons/file.svg"
                        sourceSize: Qt.size(20, 20)
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                    }
                    Label {
                        Layout.fillWidth: true
                        text: String(modelData.target || "")
                        font.pixelSize: 11
                        color: Theme.colors.text
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }

        InspectorSection {
            Layout.fillWidth: true
            title: "Inspector Support"
            iconSource: "qrc:/engine/assets/icons/cube.svg"
            expanded: false
            Label {
                Layout.fillWidth: true
                text: "This package does not declare an editable settings Inspector. Install or relocate it using the Project Package section below."
                font.pixelSize: 10
                color: Theme.colors.muted
                wrapMode: Text.WordWrap
            }
        }
    }
}
