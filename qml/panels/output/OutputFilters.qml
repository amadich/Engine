import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import JeridiEngine

// Horizontally scrollable category bar: narrow SplitView panels stay usable.
Rectangle {
    id: root
    color: Theme.colors.panel
    implicitHeight: 33

    property string selectedFilter: "all"
    property int allCount: 0
    property int errorCount: 0
    property int warningCount: 0
    property int infoCount: 0
    property int processCount: 0
    signal filterRequested(string value)

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 9
        anchors.rightMargin: 9
        clip: true
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: filterRow.implicitWidth
        contentHeight: height

        Row {
            id: filterRow
            spacing: 6
            y: 3

            OutputFilterChip {
                caption: "All"
                count: root.allCount
                selected: root.selectedFilter === "all"
                markerColor: Theme.colors.accent
                onClicked: root.filterRequested("all")
            }
            OutputFilterChip {
                caption: "Errors"
                count: root.errorCount
                selected: root.selectedFilter === "error"
                markerColor: "#F2858D"
                onClicked: root.filterRequested("error")
            }
            OutputFilterChip {
                caption: "Warnings"
                count: root.warningCount
                selected: root.selectedFilter === "warning"
                markerColor: "#E6B86B"
                onClicked: root.filterRequested("warning")
            }
            OutputFilterChip {
                caption: "Info"
                count: root.infoCount
                selected: root.selectedFilter === "info"
                markerColor: "#83B5FF"
                onClicked: root.filterRequested("info")
            }
            OutputFilterChip {
                caption: "Process"
                count: root.processCount
                selected: root.selectedFilter === "process"
                markerColor: "#36C596"
                onClicked: root.filterRequested("process")
            }
        }
    }
}
