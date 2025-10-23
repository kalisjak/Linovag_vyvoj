cmake_minimum_required(VERSION 3.10)
project(lnvg_app LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

set(CMAKE_AUTORCC ON)   # zapne auto-zpracování .qrc
set(CMAKE_AUTOUIC ON)

# Qt5 + Mqtt
find_package(Qt5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Mqtt)

add_executable(lnvg_app
    src/main.cpp
    src/backend.cpp
    src/backend.hpp
    qml/qml.qrc     # vice .qml dohromady
)

target_link_libraries(lnvg_app
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Mqtt
)

# kopie QML do build adresáře
add_custom_target(copy_qml ALL
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_SOURCE_DIR}/qml
            ${CMAKE_CURRENT_BINARY_DIR}/qml
)
add_custom_target(copy_assets ALL
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_SOURCE_DIR}/assets
            ${CMAKE_BINARY_DIR}/assets
)
add_dependencies(lnvg_app copy_qml copy_assets)
