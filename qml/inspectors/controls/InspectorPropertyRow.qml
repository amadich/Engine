import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// A label and one or more compact editors; child editors use Layout.*.
RowLayout {
    id: root
    default property alias editors: editorRow.data

    property string caption: ""
    property string helpText: ""
    property int labelWidth: width < 255 ? 74 : 92

    Layout.fillWidth: true
    spacing: 6
    implicitHeight: Math.max(26, editorRow.implicitHeight)

    Label {
        Layout.preferredWidth: root.labelWidth
        Layout.minimumWidth: 58
        text: root.caption
        color: Theme.colors.muted
        font.pixelSize: 11
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        ToolTip.visible: labelHover.hovered && root.helpText.length > 0
        ToolTip.text: root.helpText
        ToolTip.delay: 600
        HoverHandler { id: labelHover }
    }

    RowLayout {
        id: editorRow
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 5
    }
}
