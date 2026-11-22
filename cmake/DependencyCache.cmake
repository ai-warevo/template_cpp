# DependencyCache.cmake — Local-first dependency resolution with fallback to FetchContent
#
# Unified helper for cached/local dependencies:
#   1. Check FETCHCONTENT_SOURCE_DIR_<NAME> (explicit local override)
#   2. Check /opt/deps (Docker cache)
#   3. Check $ENV{AW_DEPS_DIR} (user-defined cache)
#   4. Try find_package(... QUIET)
#   5. Fall back to FetchContent
#
# Usage:
#   aw_fetch_dependency(
#       NAME Catch2
#       GIT_REPOSITORY https://github.com/catchorg/Catch2.git
#       GIT_TAG v3.5.0
#       OPTIONS
#           BUILD_TESTING OFF
#           CATCH_INSTALL_DOCS OFF)

function(aw_fetch_dependency)
    set(_oneValue NAME GIT_REPOSITORY GIT_TAG)
    set(_multiValue OPTIONS)
    cmake_parse_arguments(_DEP "" "${_oneValue}" "${_multiValue}" ${ARGN})

    if(NOT _DEP_NAME)
        message(FATAL_ERROR "aw_fetch_dependency() requires NAME")
    endif()

    string(TOUPPER "${_DEP_NAME}" _DEP_NAME_UPPER)

    # 1. Explicit local override (FETCHCONTENT_SOURCE_DIR_<NAME>)
    if(DEFINED FETCHCONTENT_SOURCE_DIR_${_DEP_NAME_UPPER})
        message(STATUS "Using local ${_DEP_NAME} from FETCHCONTENT_SOURCE_DIR_${_DEP_NAME_UPPER}")
        return()
    endif()

    # 2. Check /opt/deps (Docker cache)
    if(EXISTS "/opt/deps/lib/cmake/${_DEP_NAME}")
        list(PREPEND CMAKE_PREFIX_PATH "/opt/deps")
        message(STATUS "Found ${_DEP_NAME} in /opt/deps")
    endif()

    # 3. Check $ENV{AW_DEPS_DIR} (user-defined cache)
    if(DEFINED ENV{AW_DEPS_DIR} AND EXISTS "$ENV{AW_DEPS_DIR}/lib/cmake/${_DEP_NAME}")
        list(PREPEND CMAKE_PREFIX_PATH "$ENV{AW_DEPS_DIR}")
        message(STATUS "Found ${_DEP_NAME} in $ENV{AW_DEPS_DIR}")
    endif()

    # 4. Try find_package
    find_package(${_DEP_NAME} QUIET)
    if(${_DEP_NAME}_FOUND OR TARGET ${_DEP_NAME} OR TARGET ${_DEP_NAME}::${_DEP_NAME})
        message(STATUS "Using system ${_DEP_NAME}")
        return()
    endif()

    # 5. Fall back to FetchContent
    message(STATUS "Fetching ${_DEP_NAME} via FetchContent")
    include(FetchContent)
    FetchContent_Declare(
        ${_DEP_NAME}
        GIT_REPOSITORY ${_DEP_GIT_REPOSITORY}
        GIT_TAG ${_DEP_GIT_TAG}
        GIT_SHALLOW ON)

    # Apply options
    foreach(_opt IN LISTS _DEP_OPTIONS)
        if(_opt MATCHES "^([A-Za-z0-9_]+) (.+)$")
            set(${CMAKE_MATCH_1} ${CMAKE_MATCH_2} CACHE BOOL "" FORCE)
        endif()
    endforeach()

    FetchContent_MakeAvailable(${_DEP_NAME})
endfunction()
