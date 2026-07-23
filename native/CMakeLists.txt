cmake_minimum_required(VERSION 3.10)
project(native_renderer C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

set(NATIVE_SOURCES
    src/glad.c
    src/native_renderer.cpp
)

add_library(native_renderer SHARED ${NATIVE_SOURCES})

target_link_libraries(native_renderer
    PRIVATE
    opengl32
    gdi32
    user32
)

# Standalone Win32 Test Application
add_executable(native_test WIN32 test/main.cpp)
target_link_libraries(native_test PRIVATE native_renderer opengl32 gdi32 user32)
