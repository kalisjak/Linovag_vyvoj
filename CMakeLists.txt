cmake_minimum_required(VERSION 3.10)
project(lnvg_app LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)   # zapne auto-zpracování .qrc
set(CMAKE_AUTOUIC ON)

# Qt5 + MQTT
find_package(Qt5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Mqtt)


add_executable(lnvg_app
    src/main.cpp

    src/backend.cpp
    src/backend.hpp
    
    src/mqttWorker.cpp
    src/mqttWorker.hpp
    
    src/sensorWorker.cpp
    src/sensorWorker.hpp
    
    src/coolingWorker.cpp
    src/coolingWorker.hpp
    
    src/telemetryBuilder.cpp
    src/telemetryBuilder.hpp
    
    src/watchdogWorker.cpp
    src/watchdogWorker.hpp

    src/logManager.cpp
    src/logManager.hpp
    
    src/runtimeConfig.cpp
    src/runtimeConfig.hpp
    src/config.hpp
    
    qml/qml.qrc
    )
    
    # include path – aby bylo možné psát #include "xxx.hpp"
target_include_directories(lnvg_app
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    )
    
target_link_libraries(lnvg_app
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Mqtt
    # pigpio           # pro PWM/GPIO
    )
    
option(LNVG_USE_PIGPIO "Use pigpio GPIO control (on Raspberry Pi)" ON)
    
if(LNVG_USE_PIGPIO)
    target_compile_definitions(lnvg_app PRIVATE LNVG_USE_PIGPIO)
    target_link_libraries(lnvg_app pigpio)
endif()
# cmake -DLNVG_USE_PIGPIO=OFF ..

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
