import QtQuick
import JeridiEngine

Item {
    id: root

    required property ProjectController controller
    required property ComponentManager componentManager

    property string componentId: ""
    property var fileDetails: ({})

    readonly property url inspectorUrl: ComponentRegistry.inspectorUrl(componentId)

    function refreshInspector() {
        if (inspectorUrl.toString() === "") {
            componentLoader.source = ""
        } else {
            // Provide required QML properties before the Inspector is constructed.
            componentLoader.setSource(inspectorUrl, {
                "controller": root.controller,
                "componentManager": root.componentManager
            })
        }
    }

    onInspectorUrlChanged: refreshInspector()
    Component.onCompleted: refreshInspector()

    InspectorPanel {
        anchors.fill: parent
        visible: root.inspectorUrl.toString() === ""
        fileDetails: root.fileDetails
    }

    Loader {
        id: componentLoader
        anchors.fill: parent
        visible: root.inspectorUrl.toString() !== ""
    }
}
