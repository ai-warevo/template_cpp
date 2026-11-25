cmake_minimum_required(VERSION 3.23)

include(FetchContent)
FetchContent_Declare(
    aw_cmake_modules
    GIT_REPOSITORY https://github.com/ai-warevo/template_cpp
    GIT_TAG main
    GIT_SHALLOW ON)
FetchContent_MakeAvailable(aw_cmake_modules)
list(APPEND CMAKE_MODULE_PATH "${aw_cmake_modules_SOURCE_DIR}/cmake")

include(AWProject)
aw_project_prepare(NAME @@NAME@@ NAMESPACE @@NS@@)
project(${AW_PROJECT_NAME} VERSION ${AW_PROJECT_VERSION} LANGUAGES CXX)
aw_project_setup(PREFIX @@NAME_UPPER@@ BUILD_TESTS BUILD_APP BUILD_OVERLAY)

find_package(Threads REQUIRED)
find_package(OpenGL REQUIRED)
aw_check_cxx23_runtime()

include(DependencyCache)

# ── Dependencies ──────────────────────────────────────────────────────────────
# aw::tpl (TPL: Task Parallel Library) - check parent directory first
if(NOT TARGET aw::tpl)
    aw_fetch_dependency(
        NAME aw_tpl
        GIT_REPOSITORY https://github.com/ai-warevo/tpl.git
        GIT_TAG v3.1.0
        OPTIONS
            AW_TPL_BUILD_TESTS OFF
            AW_TPL_BUILD_EXAMPLES OFF
            AW_TPL_INSTALL OFF)
endif()

# aw::tobus (Event Bus)
if(NOT TARGET aw::tobus)
    aw_fetch_dependency(
        NAME aw_tobus
        GIT_REPOSITORY https://github.com/ai-warevo/tobus.git
        GIT_TAG main
        OPTIONS
            TOBUS_BUILD_TESTS OFF
            TOBUS_BUILD_EXAMPLES OFF
            TOBUS_INSTALL OFF)
endif()

# GLFW and ImGui (only needed if building app or overlay)
if(@@NAME_UPPER@@_BUILD_APP OR @@NAME_UPPER@@_BUILD_OVERLAY)
    # GLFW (windowing + input)
    if(NOT TARGET glfw)
        # Platform-specific GLFW options.
        # Linux: use X11 only (Wayland support requires extra libraries).
        if(UNIX AND NOT APPLE)
            set(_glfw_options
                GLFW_BUILD_DOCS OFF
                GLFW_BUILD_TESTS OFF
                GLFW_BUILD_EXAMPLES OFF
                GLFW_BUILD_X11 ON
                GLFW_BUILD_WAYLAND OFF
                GLFW_BUILD_WAYLAND_LIBDECOR OFF
                GLFW_INSTALL OFF)
        else()
            set(_glfw_options
                GLFW_BUILD_DOCS OFF
                GLFW_BUILD_TESTS OFF
                GLFW_BUILD_EXAMPLES OFF
                GLFW_INSTALL OFF)
        endif()

        aw_fetch_dependency(
            NAME glfw
            GIT_REPOSITORY https://github.com/glfw/glfw.git
            GIT_TAG 3.3.10
            OPTIONS ${_glfw_options})
    endif()

    # Dear ImGui (docking branch)
    if(NOT TARGET imgui)
        aw_fetch_dependency(
            NAME imgui
            GIT_REPOSITORY https://github.com/ocornut/imgui.git
            GIT_TAG v1.91.8-docking)

        add_library(imgui STATIC
            ${imgui_SOURCE_DIR}/imgui.cpp
            ${imgui_SOURCE_DIR}/imgui_demo.cpp
            ${imgui_SOURCE_DIR}/imgui_draw.cpp
            ${imgui_SOURCE_DIR}/imgui_tables.cpp
            ${imgui_SOURCE_DIR}/imgui_widgets.cpp
            ${imgui_SOURCE_DIR}/backends/imgui_impl_glfw.cpp
            ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp)

        target_include_directories(imgui SYSTEM PUBLIC
            ${imgui_SOURCE_DIR}
            ${imgui_SOURCE_DIR}/backends)

        target_link_libraries(imgui PUBLIC glfw OpenGL::GL)
        set_target_properties(imgui PROPERTIES CXX_STANDARD 23)
    endif()
endif()

# ── Target 1: @@NAME@@_core (static lib, pure C++23, zero imgui.h) ──
aw_add_library(TARGET @@NAME@@_core TYPE STATIC ALIAS @@NS@@::core
    SOURCES
        src/config.cpp
        src/panel_registry.cpp
        src/overlay_canvas.cpp
    HEADERS
        include/@@NS_PATH@@/config.hpp
        include/@@NS_PATH@@/types.hpp
    PUBLIC_INCLUDE_DIRS include
    PUBLIC_LINKS aw::tpl aw::tobus Threads::Threads)

if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
    aw_configure_compiler(TARGET @@NAME@@_core STRICT_WARNINGS)
endif()

# ── Target 2: @@NAME@@_ui (static lib, ImGui + @@NAME@@_core) ──
# UI target is only needed if building app or overlay
if(@@NAME_UPPER@@_BUILD_APP OR @@NAME_UPPER@@_BUILD_OVERLAY)
    aw_add_library(TARGET @@NAME@@_ui TYPE STATIC ALIAS @@NS@@::ui
        SOURCES
            src/ui.cpp
            src/panels/general_panel.cpp
            src/panels/overlay_demo_panel.cpp
        HEADERS
            include/@@NS_PATH@@/ui.hpp
        PUBLIC_INCLUDE_DIRS include
        PUBLIC_LINKS @@NS@@::core imgui)

    if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
        aw_configure_compiler(TARGET @@NAME@@_ui STRICT_WARNINGS)
    endif()
endif()

# ── Target 3: @@NAME@@_app (executable, GLFW + OpenGL host) ──
if(@@NAME_UPPER@@_BUILD_APP)
    # Windows version resource and icon (Windows only)
    if(WIN32)
        include(Windows/WinVersion)
        aw_win_version(
            OUTVAR @@NAME_UPPER@@_WIN_RESOURCES
            NAME "@@NAME@@"
            VERSION_MAJOR ${PROJECT_VERSION_MAJOR}
            VERSION_MINOR ${PROJECT_VERSION_MINOR}
            VERSION_PATCH ${PROJECT_VERSION_PATCH}
            COMPANY_NAME "Your Company"
            COMPANY_COPYRIGHT "Copyright 2026 Your Company"
            FILE_DESCRIPTION "@@NAME@@ Application"
            COMMENTS "@@NAME@@ v${PROJECT_VERSION}"
            ORIGINAL_FILENAME "@@NAME@@.exe"
            INTERNAL_NAME "@@NAME@@"
            ICON "${CMAKE_SOURCE_DIR}/product.ico"
        )
    endif()

    aw_add_executable(TARGET @@NAME@@_app
        SOURCES src/main.cpp ${@@NAME_UPPER@@_WIN_RESOURCES}
        LINK_LIBRARIES @@NS@@::ui glfw OpenGL::GL)

    # Pass version from VERSION file as compile definition
    target_compile_definitions(@@NAME@@_app PRIVATE
        APP_VERSION="${PROJECT_VERSION}")

    # Hide console window on Windows
    if(WIN32)
        if(MSVC)
            target_link_options(@@NAME@@_app PRIVATE /SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup)
        elseif(MINGW)
            target_link_options(@@NAME@@_app PRIVATE -mwindows)
        endif()
    endif()

    if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
        aw_configure_compiler(TARGET @@NAME@@_app STRICT_WARNINGS)
    endif()
endif()

# ── Target 4: @@NAME@@_overlay (shared lib, embeddable) ──
if(@@NAME_UPPER@@_BUILD_OVERLAY)
    set(_overlay_sources src/overlay_common.cpp)
    if(WIN32)
        list(APPEND _overlay_sources src/overlay_win32.cpp)
    else()
        list(APPEND _overlay_sources src/overlay_posix.cpp)
    endif()

    aw_add_library(TARGET @@NAME@@_overlay TYPE SHARED ALIAS @@NS@@::overlay
        SOURCES ${_overlay_sources}
        PUBLIC_INCLUDE_DIRS include
        PUBLIC_LINKS @@NS@@::ui)

    set_target_properties(@@NAME@@_overlay PROPERTIES
        CXX_VISIBILITY_PRESET hidden
        VISIBILITY_INLINES_HIDDEN ON
        VERSION ${PROJECT_VERSION}
        SOVERSION ${PROJECT_VERSION_MAJOR})

    if(@@NAME_UPPER@@_WARNINGS_AS_ERRORS)
        aw_configure_compiler(TARGET @@NAME@@_overlay STRICT_WARNINGS)
    endif()
endif()

# ── Tests (Catch2 v3) ──
aw_setup_tests(OPTION @@NAME_UPPER@@_BUILD_TESTS DIRECTORY tests)
