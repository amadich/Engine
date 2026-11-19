cmake_minimum_required(VERSION 3.16)

project(JeridiEngine VERSION 0.7.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 QuickDialogs2 WebView Network)
qt_standard_project_setup(REQUIRES 6.8)

# Native application branding for macOS and Windows.
set(JERIDI_MACOS_ICON "${CMAKE_CURRENT_SOURCE_DIR}/assets/branding/JeridiEngine.icns")
set_source_files_properties("${JERIDI_MACOS_ICON}" PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

if(WIN32)
    set(JERIDI_WINDOWS_RESOURCES "${CMAKE_CURRENT_SOURCE_DIR}/assets/branding/JeridiEngine.rc")
else()
    set(JERIDI_WINDOWS_RESOURCES "")
endif()

qt_add_executable(appJeridiEngine
    src/main.cpp
    ${JERIDI_MACOS_ICON}
    ${JERIDI_WINDOWS_RESOURCES}
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

# Framework generators are offline, versioned assets; a new generator is a
# directory under project-templates/ and never touches projectcontroller.cpp.
file(GLOB_RECURSE project_template_files CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/project-templates/*"
    "${CMAKE_CURRENT_SOURCE_DIR}/project-templates/.*"
)
qt_add_resources(appJeridiEngine project_templates
    PREFIX "/project-templates"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/project-templates"
    FILES ${project_template_files}
)

# Custom inspectors belong to their package, but compile into the QML module.
set(component_inspectors ${component_package_files})
list(FILTER component_inspectors INCLUDE REGEX "/inspector/[^/]+\\.qml$")

# Include icons by directory, including framework icons supplied later.
# CONFIGURE_DEPENDS reconfigures when a new icon is added to assets/icons/.
file(GLOB_RECURSE engine_icon_files RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/*.svg"
)
file(GLOB_RECURSE engine_logo_files RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/assets/logos/*.svg"
)
qt_add_resources(appJeridiEngine engine_assets
    PREFIX "/engine"
    FILES ${engine_icon_files} ${engine_logo_files}
)

set(engine_qml_files
    qml/Main.qml
    qml/StartupLauncher.qml
    qml/launcher/LauncherArtwork.qml
    qml/launcher/LauncherSplash.qml
    qml/launcher/LauncherWelcome.qml
    qml/launcher/LauncherUpdatesPopup.qml
    qml/components/EngineToolbar.qml
    qml/menus/EngineMenu.qml
    qml/menus/EngineMenuItem.qml
    qml/menus/EngineMenuSection.qml
    qml/menus/EngineMenuDivider.qml
    qml/menus/EngineMenuBar.qml
    qml/menus/MenuShortcutsDialog.qml
    qml/menus/MenuProjectInfoDialog.qml
    qml/menus/MenuUpdatesDialog.qml
    qml/components/WorkspaceView.qml
    qml/components/DockFrame.qml
    qml/components/DockLayoutBar.qml
    qml/components/DockState.js
    qml/components/ComponentInstallationActions.qml
    qml/inspectors/InspectorHost.qml
    qml/inspectors/GenericComponentInspector.qml
    qml/inspectors/controls/InspectorActionButton.qml
    qml/inspectors/controls/InspectorChangeList.qml
    qml/inspectors/controls/InspectorColorField.qml
    qml/inspectors/controls/InspectorContrastMetric.qml
    qml/inspectors/controls/InspectorComboBox.qml
    qml/inspectors/controls/InspectorNumberField.qml
    qml/inspectors/controls/InspectorPropertyRow.qml
    qml/inspectors/controls/InspectorScaffold.qml
    qml/inspectors/controls/InspectorSection.qml
    qml/inspectors/controls/InspectorTextField.qml
    qml/inspectors/controls/InspectorToggle.qml
    qml/panels/ComponentLibraryPanel.qml
    qml/panels/LibraryModel.js
    qml/panels/library/LibraryToolbar.qml
    qml/panels/library/LibraryIconButton.qml
    qml/panels/library/LibraryFilterChip.qml
    qml/panels/library/LibraryCategoryRow.qml
    qml/panels/library/LibraryComponentRow.qml
    qml/panels/library/LibraryDetails.qml
    qml/panels/PreviewPanel.qml
    qml/panels/InspectorPanel.qml
    qml/panels/OutputPanel.qml
    qml/panels/output/OutputLogStore.qml
    qml/panels/output/OutputLogRow.qml
    qml/panels/output/OutputHeader.qml
    qml/panels/output/OutputToolbar.qml
    qml/panels/output/OutputFilters.qml
    qml/panels/output/OutputFilterChip.qml
    qml/panels/output/OutputIconButton.qml
    qml/panels/output/OutputStatusBar.qml
    qml/panels/output/OutputFormat.js
    qml/panels/ProjectFilesPanel.qml
    qml/panels/projectfiles/ProjectExplorerFormat.js
    qml/panels/projectfiles/ProjectExplorerIconButton.qml
    qml/panels/projectfiles/ProjectExplorerActionButton.qml
    qml/panels/projectfiles/ProjectExplorerFilterChip.qml
    qml/panels/projectfiles/ProjectExplorerHeader.qml
    qml/panels/projectfiles/ProjectExplorerActions.qml
    qml/panels/projectfiles/ProjectExplorerFileRow.qml
    qml/panels/projectfiles/ProjectExplorerDetails.qml
    qml/dialogs/CreateProjectDialog.qml
    qml/dialogs/newproject/ProjectProfiles.js
    qml/dialogs/newproject/ProjectTypeSidebar.qml
    qml/dialogs/newproject/ProjectDetailsStep.qml
    qml/dialogs/newproject/ProjectOptionsStep.qml
    qml/dialogs/newproject/ProjectReviewStep.qml
    qml/dialogs/newproject/ProjectDependenciesStep.qml
    qml/dialogs/newproject/ProjectWizardInspector.qml
    qml/dialogs/newproject/WizardInput.qml
    qml/dialogs/newproject/WizardCombo.qml
    qml/dialogs/newproject/WizardActionButton.qml
    qml/dialogs/newproject/WizardFormRow.qml
    qml/dialogs/newproject/WizardSectionHeader.qml
    qml/dialogs/newproject/WizardCheckRow.qml
    qml/dialogs/newproject/WizardFrameworkIcon.qml
    qml/dialogs/newproject/WizardStyle.js
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
    qml/panels/EditorActionBar.qml
    qml/panels/EditorFindBar.qml
    qml/panels/EditorNavigationPanel.qml
    qml/panels/EditorImagePreview.qml
    qml/panels/EditorIntelligence.js

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

# Temporarily skip QML ahead-of-time compilation
# for ProjectFilesPanel while diagnosing the crash.
set_source_files_properties(
    qml/panels/ProjectFilesPanel.qml
    PROPERTIES
        QT_QML_SKIP_CACHEGEN TRUE
)

qt_add_qml_module(appJeridiEngine
    URI JeridiEngine
    VERSION 1.0
    QML_FILES ${engine_qml_files}
    SOURCES
        src/application/startupservice.h
        src/application/startupservice.cpp
        src/application/projectcontroller.h
        src/application/projectcontroller.cpp
        src/application/projectscaffolder.h
        src/application/projectscaffolder.cpp
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
    Qt6::Network
)

set_target_properties(appJeridiEngine PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_NAME "JeridiEngine"
    MACOSX_BUNDLE_GUI_IDENTIFIER "dev.jeridi.engine"
    MACOSX_BUNDLE_ICON_FILE "JeridiEngine.icns"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
    MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
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
        src/application/projectscaffolder.cpp
        src/components/componentinstaller.cpp
        src/components/componentinstallationstore.cpp
        src/components/componentlifecycle.cpp
    )
    target_include_directories(component_lifecycle_tests PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/src/components"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/application")
    target_link_libraries(component_lifecycle_tests PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME component_lifecycle_tests COMMAND component_lifecycle_tests)
endif()
