cmake_minimum_required(VERSION 3.16)

project(JeridiEngine VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 QuickDialogs2 WebView)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appJeridiEngine
    src/main.cpp
)

qt_add_resources(appJeridiEngine component_templates
    PREFIX "/templates"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/templates"
    FILES
        templates/react/engine-button/EngineButton.tsx
    PREFIX "/engine"
    FILES
        assets/icons/cube.svg
        assets/icons/cube_blue.svg
        assets/icons/folder.svg
        assets/icons/file.svg
        assets/icons/image.svg
        assets/icons/forest.svg
        assets/icons/save.svg
        assets/icons/close.svg
        assets/icons/copy.svg
        assets/icons/cut.svg
        assets/icons/paste.svg
        assets/icons/redo.svg
        assets/icons/undo.svg
        assets/icons/trash.svg
        assets/icons/select-all.svg
        assets/logos/engine_logo.svg
        assets/logos/engine_logo_blue.svg
        assets/logos/engine_logo_green.svg
        assets/logos/engine_logo_orange.svg
)

set(engine_qml_files
    qml/Main.qml
    qml/components/EngineToolbar.qml
    qml/components/WorkspaceView.qml
    qml/panels/ComponentLibraryPanel.qml
    qml/panels/PreviewPanel.qml
    qml/panels/InspectorPanel.qml
    qml/panels/OutputPanel.qml
    qml/panels/ProjectFilesPanel.qml
    qml/dialogs/CreateProjectDialog.qml
    qml/theme/DarkTheme.qml
    qml/theme/LightTheme.qml
    qml/theme/Theme.qml
    qml/dialogs/PreferencesDialog.qml
    qml/panels/EditorWorkspace.qml
    qml/dialogs/QuickOpenDialog.qml
    qml/panels/EditorContextMenu.qml
)

# Keep one QML module while organizing source files into folders.
foreach(qml_file IN LISTS engine_qml_files)
    get_filename_component(qml_name "${qml_file}" NAME)
    set_source_files_properties("${qml_file}" PROPERTIES
        QT_RESOURCE_ALIAS "${qml_name}"
    )
endforeach()

set_source_files_properties(qml/theme/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appJeridiEngine
    URI JeridiEngine
    VERSION 1.0
    QML_FILES ${engine_qml_files}
    SOURCES
        src/application/projectcontroller.h
        src/application/projectcontroller.cpp
        src/infrastructure/processrunner.h
        src/infrastructure/processrunner.cpp
        src/infrastructure/projectfilesmodel.h
        SOURCES src/editor/codesyntaxhighlighter.h src/editor/codesyntaxhighlighter.cpp
)

target_include_directories(appJeridiEngine PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src/application"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/infrastructure"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/editor"
)

target_link_libraries(appJeridiEngine PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickDialogs2
    Qt6::WebView
)

set_target_properties(appJeridiEngine PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
install(TARGETS appJeridiEngine
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
