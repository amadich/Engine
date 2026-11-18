import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "WizardStyle.js" as S

Item {
    id: root
    property string label: ""
    property string note: ""
    property int labelWidth: 174
    default property alias field: fieldSlot.data
    implicitHeight: note.length ? 45 : 32
    Layout.fillWidth: true
    RowLayout {
        anchors.fill: parent
        spacing: 13
        Label {
            Layout.preferredWidth: root.labelWidth
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 7
            text: root.label
            font.pixelSize: 12
            color: S.text
            elide: Text.ElideRight
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Item {
                id: fieldSlot
                Layout.fillWidth: true
                Layout.preferredHeight: 29
            }
            Label {
                visible: root.note.length > 0
                text: root.note
                font.pixelSize: 10
                color: S.faint
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }
        }
    }
}
