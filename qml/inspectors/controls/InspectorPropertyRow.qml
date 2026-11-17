import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Compact property row. Search visibility is opt-in via filterQuery.
RowLayout {
    id: root
    default property alias editors: editorRow.data

    property string caption: ""
    property string helpText: ""
    property string filterQuery: ""
    property bool showAll: false
    property int labelWidth: width < 255 ? 77 : 93

    readonly property string query: filterQuery.trim().toLowerCase()
    visible: query.length === 0 || showAll || caption.toLowerCase().indexOf(query) >= 0
             || helpText.toLowerCase().indexOf(query) >= 0

    Layout.fillWidth: true
    spacing: 6
    implicitHeight: Math.max(25, editorRow.implicitHeight)

    Label {
        Layout.preferredWidth: root.labelWidth
        Layout.minimumWidth: 59
        text: root.caption
        color: Theme.colors.muted
        font.pixelSize: 10
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        ToolTip.visible: labelHover.hovered && root.helpText.length > 0
        ToolTip.text: root.helpText
        ToolTip.delay: 550
        HoverHandler { id: labelHover }
    }

    RowLayout {
        id: editorRow
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 4
    }
}
