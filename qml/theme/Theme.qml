pragma Singleton

import QtQuick
import QtCore

QtObject {
    id: root

    property alias appearance: preferences.appearance
    readonly property bool dark: appearance !== "light"
    readonly property var colors: dark ? darkColors : lightColors

    property Settings settings: Settings {
        id: preferences
        category: "Appearance"
        property string appearance: "dark"
    }

    property DarkTheme darkTheme: DarkTheme { id: darkColors }
    property LightTheme lightTheme: LightTheme { id: lightColors }
}