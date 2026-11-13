cmake_minimum_required(VERSION 3.16)

project(JeridiEngine VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 QuickDialogs2)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appJeridiEngine
    src/main.cpp
)

set(engine_qml_files
    qml/Main.qml
    qml/components/EngineToolbar.qml
    qml/components/WorkspaceView.qml
    qml/panels/ComponentLibraryPanel.qml
    qml/panels/PreviewPanel.qml
    qml/panels/InspectorPanel.qml
    qml/panels/OutputPanel.qml
    qml/dialogs/CreateProjectDialog.qml
)

# Keep one QML module while organizing source files into folders.
foreach(qml_file IN LISTS engine_qml_files)
    get_filename_component(qml_name "${qml_file}" NAME)
    set_source_files_properties("${qml_file}" PROPERTIES
        QT_RESOURCE_ALIAS "${qml_name}"
    )
endforeach()

qt_add_qml_module(appJeridiEngine
    URI JeridiEngine
    VERSION 1.0
    QML_FILES ${engine_qml_files}
    SOURCES
        src/application/projectcontroller.h
        src/application/projectcontroller.cpp
        src/infrastructure/processrunner.h
        src/infrastructure/processrunner.cpp
)

target_include_directories(appJeridiEngine PRIVATE
    src/application
    src/infrastructure
)

target_link_libraries(appJeridiEngine PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickDialogs2
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