cmake_minimum_required(VERSION 3.16)

project(JeridiEngine VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 QuickDialogs2 WebView)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appJeridiEngine
    src/main.cpp
)

# Package data is collected automatically. New packages only need their own files.
file(GLOB_RECURSE component_package_files CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/component-packages/*"
)
set(component_package_assets ${component_package_files})
list(FILTER component_package_assets EXCLUDE REGEX "\\.qml$")

qt_add_resources(appJeridiEngine component_packages
    PREFIX "/component-packages"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/component-packages"
    FILES ${component_package_assets}
)

# Custom inspectors belong to their package, but compile into the QML module.
file(GLOB_RECURSE component_inspectors CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/component-packages/*/inspector/*.qml"
)

qt_add_resources(appJeridiEngine engine_assets
    PREFIX "/engine"
    FILES
        assets/icons/cube.svg
        assets/icons/cube_blue.svg
        assets/icons/cube_block.svg
        assets/icons/warning_2.svg
        assets/icons/preview.svg
        assets/icons/search.svg
        assets/icons/star.svg
        assets/icons/user.svg
        assets/icons/folder.svg
        assets/icons/folder_1.svg
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
    qml/components/ComponentInstallationActions.qml
    qml/inspectors/InspectorHost.qml
    qml/inspectors/GenericComponentInspector.qml
    qml/inspectors/controls/InspectorColorField.qml
    qml/inspectors/controls/InspectorComboBox.qml
    qml/inspectors/controls/InspectorNumberField.qml
    qml/inspectors/controls/InspectorPropertyRow.qml
    qml/inspectors/controls/InspectorScaffold.qml
    qml/inspectors/controls/InspectorSection.qml
    qml/inspectors/controls/InspectorTextField.qml
    qml/inspectors/controls/InspectorToggle.qml
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
    qml/dialogs/ComponentInstallDialog.qml
    qml/dialogs/ComponentMoveDialog.qml
    qml/dialogs/ComponentRemoveDialog.qml
    qml/dialogs/ComponentActionDialog.qml
    qml/dialogs/ComponentDestinationPicker.qml
    qml/panels/EditorContextMenu.qml

    qml/panels/EditorTabBar.qml
    qml/panels/CodeEditorPane.qml
    qml/panels/CompletionList.qml

    # OTHER TYPE (JS, JSON etc ...)
    qml/panels/EditorEditing.js

)
list(APPEND engine_qml_files ${component_inspectors})

# Keep one QML module while organizing source files into folders.
foreach(qml_file IN LISTS engine_qml_files)
    if(IS_ABSOLUTE "${qml_file}")
        file(RELATIVE_PATH package_qml_path
            "${CMAKE_CURRENT_SOURCE_DIR}/component-packages" "${qml_file}")
        set_source_files_properties("${qml_file}" PROPERTIES
            QT_RESOURCE_ALIAS "packages/${package_qml_path}")
    else()
        get_filename_component(qml_name "${qml_file}" NAME)
        set_source_files_properties("${qml_file}" PROPERTIES
            QT_RESOURCE_ALIAS "${qml_name}")
    endif()
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
        src/components/componentregistry.h
        src/components/componentregistry.cpp
        src/components/componentmanager.h
        src/components/componentmanager.cpp
        src/components/componentinstaller.h
        src/components/componentinstaller.cpp
        src/components/componentinstallationstore.h
        src/components/componentinstallationstore.cpp
        src/components/componentlifecycle.h
        src/components/componentlifecycle.cpp
        src/components/projectfoldermodel.h
        src/components/projectfoldermodel.cpp
        src/infrastructure/processrunner.h
        src/infrastructure/processrunner.cpp
        src/infrastructure/projectfilesmodel.h
        src/editor/codesyntaxhighlighter.h
        src/editor/codesyntaxhighlighter.cpp
)

target_include_directories(appJeridiEngine PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src/application"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/components"
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

# Opt-in regression suite. Does not change normal builds or require Qt6::Test.
option(JERIDI_BUILD_COMPONENT_TESTS "Build component lifecycle regression tests" OFF)
if(JERIDI_BUILD_COMPONENT_TESTS)
    find_package(Qt6 REQUIRED COMPONENTS Test)
    enable_testing()
    add_executable(component_lifecycle_tests
        tests/component_lifecycle_tests.cpp
        src/components/componentinstaller.cpp
        src/components/componentinstallationstore.cpp
        src/components/componentlifecycle.cpp
    )
    target_include_directories(component_lifecycle_tests PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/src/components")
    target_link_libraries(component_lifecycle_tests PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME component_lifecycle_tests COMMAND component_lifecycle_tests)
endif()
