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
        if (root.componentId === "") {
            componentLoader.source = ""
        } else if (inspectorUrl.toString() !== "") {
            // Provide required QML properties before the Inspector is constructed.
            componentLoader.setSource(inspectorUrl, {
                "controller": root.controller,
                "componentManager": root.componentManager
            })
        } else {
            componentLoader.setSource(Qt.resolvedUrl("GenericComponentInspector.qml"), {
                "controller": root.controller,
                "componentManager": root.componentManager,
                "componentId": root.componentId
            })
        }
    }

    onComponentIdChanged: refreshInspector()
    onInspectorUrlChanged: refreshInspector()
    Component.onCompleted: refreshInspector()

    InspectorPanel {
        anchors.fill: parent
        visible: root.componentId === ""
        fileDetails: root.fileDetails
    }

    Loader {
        id: componentLoader
        anchors.fill: parent
        visible: root.componentId !== ""
    }
}
