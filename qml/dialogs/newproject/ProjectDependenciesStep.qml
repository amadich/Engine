import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ProjectProfiles.js" as Profiles
import "WizardStyle.js" as S

Item {
    id: root
    required property string framework
    property var dependencies: []
    property string selectedDependency: ""
    property string searchText: ""
    property bool selectedOnly: false
    property string category: "All categories"
    signal dependencyToggled(string id, bool checked)
    signal packageFocused(string id)

    readonly property var allPackages: Profiles.dependencyOptions(framework)
    readonly property var categories: {
        const result = ["All categories"]
        for (let i = 0; i < allPackages.length; ++i)
            if (result.indexOf(allPackages[i].group) === -1) result.push(allPackages[i].group)
        return result
    }
    readonly property var filteredPackages: {
        const result = []
        const needle = searchText.trim().toLowerCase()
        for (let i = 0; i < allPackages.length; ++i) {
            const pkg = allPackages[i]
            if (selectedOnly && dependencies.indexOf(pkg.key) === -1) continue
            if (category !== "All categories" && pkg.group !== category) continue
            if (needle && (pkg.name + " " + pkg.group + " " + pkg.artifact + " " + pkg.detail).toLowerCase().indexOf(needle) === -1) continue
            result.push(pkg)
        }
        return result
    }
    onFrameworkChanged: { searchText = ""; selectedOnly = false; category = "All categories" }
    function coreLabel() {
        if (framework === "spring-boot") return "Spring Web · Spring Boot Test"
        if (framework === "express-ts") return "Express · TypeScript · tsx"
        if (framework === "next-js") return "Next.js · Tailwind CSS · Radix UI · Motion · Mynaui · shadcn"
        if (framework === "react-vite") return "React · React DOM · Vite · TypeScript"
        if (framework === "vue-vite") return "Vue · Vite · TypeScript"
        return "HTML5 · CSS3 · JavaScript"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 39
            spacing: 10
            Label { text: "Package Manager"; font.pixelSize: 19; font.weight: Font.DemiBold; color: S.title }
            Item { Layout.fillWidth: true }
            Label { text: root.dependencies.length + " selected"; font.pixelSize: 11; color: S.success }
        }
        Label {
            Layout.fillWidth: true
            text: "Choose packages for the generated project. Select a row to see details on the right."
            color: S.muted; font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.bottomMargin: 12
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            WizardInput {
                Layout.fillWidth: true
                placeholderText: "Search packages or Maven artifacts..."
                text: root.searchText
                onTextEdited: root.searchText = text
            }
            WizardCombo {
                Layout.preferredWidth: 144
                model: root.categories
                onActivated: function(index) { root.category = root.categories[index] }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            spacing: 15
            Label {
                text: "All packages"
                font.pixelSize: 11
                font.weight: !root.selectedOnly ? Font.DemiBold : Font.Normal
                color: !root.selectedOnly ? S.title : S.muted
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedOnly = false }
            }
            Label {
                text: "Selected (" + root.dependencies.length + ")"
                font.pixelSize: 11
                font.weight: root.selectedOnly ? Font.DemiBold : Font.Normal
                color: root.selectedOnly ? S.title : S.muted
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedOnly = true }
            }
            Item { Layout.fillWidth: true }
            Label { text: root.filteredPackages.length + " available"; font.pixelSize: 10; color: S.faint }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                width: Math.max(0, root.width - 12)
                spacing: 0
                Rectangle {
                    visible: !root.selectedOnly && !root.searchText.trim() && root.category === "All categories"
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 29 : 0
                    color: S.surface
                    Label { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: "BUILT-IN  ·  ALWAYS INCLUDED"; font.pixelSize: 10; font.weight: Font.DemiBold; color: S.muted }
                }
                Item {
                    visible: !root.selectedOnly && !root.searchText.trim() && root.category === "All categories"
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 47 : 0
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 9
                        spacing: 10
                        Label { text: "✓"; color: S.success; font.pixelSize: 13 }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label { text: "Core framework packages"; color: S.title; font.pixelSize: 12 }
                            Label { text: root.coreLabel(); color: S.muted; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                        Label { text: "Bundled"; color: S.success; font.pixelSize: 10 }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 29
                    color: S.surface
                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "OPTIONAL PACKAGES  ·  " + root.filteredPackages.length
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: S.muted
                    }
                }
                Repeater {
                    model: root.filteredPackages
                    Item {
                        id: pkgRow
                        required property var modelData
                        readonly property bool isSelected: root.dependencies.indexOf(modelData.key) !== -1
                        readonly property bool isFocused: root.selectedDependency === modelData.key
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        Rectangle { anchors.fill: parent; color: pkgRow.isFocused ? S.selected : pkgHover.containsMouse ? S.hover : "transparent" }
                        Rectangle { width: 2; height: parent.height; color: S.accent; visible: pkgRow.isFocused }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 9
                            spacing: 9
                            CheckBox {
                                id: pkgCheck
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 26
                                checked: pkgRow.isSelected
                                indicator: Rectangle {
                                    x: 1; y: 6; width: 15; height: 15; radius: 2
                                    color: pkgCheck.checked ? S.accent : S.input
                                    border.width: 1
                                    border.color: pkgCheck.checked ? S.accent : S.muted
                                    Text { anchors.centerIn: parent; text: "✓"; visible: pkgCheck.checked; color: "white"; font.pixelSize: 11 }
                                }
                                onClicked: root.dependencyToggled(pkgRow.modelData.key, checked)
                            }
                            Image {
                                Layout.preferredWidth: 17
                                Layout.preferredHeight: 17
                                source: pkgRow.modelData.group === "Security" ? "qrc:/engine/assets/icons/security.svg" : "qrc:/engine/assets/icons/package.svg"
                                sourceSize.width: 32
                                sourceSize.height: 32
                                fillMode: Image.PreserveAspectFit
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 7
                                    Label { text: pkgRow.modelData.name; font.pixelSize: 12; color: S.title; font.weight: pkgRow.isFocused ? Font.DemiBold : Font.Normal; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Label { text: pkgRow.modelData.group; font.pixelSize: 10; color: S.faint }
                                }
                                Label { text: pkgRow.modelData.detail; font.pixelSize: 10; color: S.muted; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                        }
                        MouseArea {
                            id: pkgHover
                            anchors.fill: parent
                            anchors.leftMargin: 31
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.packageFocused(pkgRow.modelData.key)
                            onDoubleClicked: root.dependencyToggled(pkgRow.modelData.key, !pkgRow.isSelected)
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: S.line }
                    }
                }
                Label {
                    visible: root.filteredPackages.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 30
                    text: root.allPackages.length === 0 ? "No optional packages are needed for this template." : "No packages match these filters."
                    font.pixelSize: 12
                    color: S.muted
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: S.line }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            spacing: 6
            Label { text: "✓"; color: S.success; font.pixelSize: 12 }
            Label { text: "Selections update the generated manifest. Downloads happen only after creation, if requested."; color: S.muted; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
        }
    }
}
