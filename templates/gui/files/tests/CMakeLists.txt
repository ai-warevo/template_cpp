cmake_minimum_required(VERSION 3.25)

enable_testing()

# Fetch Catch2 v3 for testing
include(FetchContent)
FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG v3.4.0
)
FetchContent_MakeAvailable(Catch2)

# Test executable
add_executable(@@NAME@@_tests
    config_tests.cpp
    panel_registry_tests.cpp
    overlay_canvas_tests.cpp
)

target_link_libraries(@@NAME@@_tests PRIVATE
    @@NAME@@_core
    Catch2::Catch2WithMain
    Threads::Threads
)

set_target_properties(@@NAME@@_tests PROPERTIES CXX_STANDARD 23)

# Register tests with CMake
include(Catch)
catch_discover_tests(@@NAME@@_tests)
