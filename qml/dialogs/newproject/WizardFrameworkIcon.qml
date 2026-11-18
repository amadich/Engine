import QtQuick
import "ProjectProfiles.js" as Profiles

Item {
    id: root
    property string framework: "react-vite"
    implicitWidth: 22
    implicitHeight: 22
    Image {
        anchors.centerIn: parent
        width: Math.min(root.width, 22)
        height: Math.min(root.height, 22)
        source: Profiles.iconPath(root.framework)
        fillMode: Image.PreserveAspectFit
        smooth: true
        sourceSize.width: 48
        sourceSize.height: 48
    }
}
