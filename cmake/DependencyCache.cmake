# DependencyCache.cmake — Multi-tier dependency resolution (monorepo + Docker + system + network)
#
# Resolution priority by library type:
#
# INTERNAL LIBRARIES (aw::tpl, aw::tobus):
#   1. FETCHCONTENT_SOURCE_DIR_<NAME> (explicit override)
#   2. ../<NAME> (parent directory - monorepo)
#   3. build/_deps (local build cache from prior fetches)
#   4. /opt/deps (Docker pre-compiled stable)
#   5. find_package() (system install)
#   6. FetchContent (GitHub fallback)
#
# EXTERNAL LIBRARIES (Catch2, spdlog, etc.):
#   1. FETCHCONTENT_SOURCE_DIR_<NAME> (explicit override)
#   2. build/_deps (local build cache)
#   3. /opt/deps (Docker pre-compiled stable)
#   4. $ENV{AW_DEPS_DIR} (user-defined cache)
#   5. find_package() (system install)
#   6. FetchContent (network fallback)
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
    string(TOLOWER "${_DEP_NAME}" _DEP_NAME_LOWER)

    # 1. Explicit local override (FETCHCONTENT_SOURCE_DIR_<NAME>)
    if(DEFINED FETCHCONTENT_SOURCE_DIR_${_DEP_NAME_UPPER})
        message(STATUS "Using ${_DEP_NAME} from FETCHCONTENT_SOURCE_DIR")
        return()
    endif()

    # Detect if this is an internal library (aw_* convention for cmake vars vs aw:: for namespaces)
    string(REGEX MATCH "^aw" _IS_INTERNAL "${_DEP_NAME_LOWER}")

    if(_IS_INTERNAL)
        # 2a. For INTERNAL LIBS: Check parent directory (monorepo workflow)
        # Convert aw_tpl → tpl, aw_tobus → tobus
        string(REPLACE "aw_" "" _DEP_DIR_NAME "${_DEP_NAME_LOWER}")
        if(EXISTS "${CMAKE_SOURCE_DIR}/../${_DEP_DIR_NAME}")
            message(STATUS "Found ${_DEP_NAME} in parent directory (../${_DEP_DIR_NAME})")
            set(FETCHCONTENT_SOURCE_DIR_${_DEP_NAME_UPPER} "${CMAKE_SOURCE_DIR}/../${_DEP_DIR_NAME}" PARENT_SCOPE)
            include(FetchContent)
            FetchContent_Populate(${_DEP_NAME})
            list(APPEND CMAKE_MODULE_PATH "${${_DEP_NAME}_SOURCE_DIR}/cmake")
            return()
        endif()
    endif()

    # 3. Check build/_deps (local build cache from previous FetchContent runs)
    if(EXISTS "${CMAKE_BINARY_DIR}/_deps/${_DEP_NAME_LOWER}-src")
        message(STATUS "Found ${_DEP_NAME} in build cache (build/_deps)")
        set(FETCHCONTENT_SOURCE_DIR_${_DEP_NAME_UPPER} "${CMAKE_BINARY_DIR}/_deps/${_DEP_NAME_LOWER}-src" PARENT_SCOPE)
        return()
    endif()

    # 4. Check /opt/deps (Docker pre-compiled stable deps)
    if(EXISTS "/opt/deps/lib/cmake/${_DEP_NAME}")
        list(PREPEND CMAKE_PREFIX_PATH "/opt/deps")
        message(STATUS "Found ${_DEP_NAME} in /opt/deps (Docker cache)")
    endif()

    # 5. Check $ENV{AW_DEPS_DIR} (user-defined cache directory)
    if(DEFINED ENV{AW_DEPS_DIR} AND EXISTS "$ENV{AW_DEPS_DIR}/lib/cmake/${_DEP_NAME}")
        list(PREPEND CMAKE_PREFIX_PATH "$ENV{AW_DEPS_DIR}")
        message(STATUS "Found ${_DEP_NAME} in $ENV{AW_DEPS_DIR} (user cache)")
    endif()

    # 6. Try find_package (system install)
    find_package(${_DEP_NAME} QUIET)
    if(${_DEP_NAME}_FOUND OR TARGET ${_DEP_NAME} OR TARGET ${_DEP_NAME}::${_DEP_NAME})
        message(STATUS "Using system ${_DEP_NAME}")
        return()
    endif()

    # 7. Fall back to FetchContent (network)
    message(STATUS "Fetching ${_DEP_NAME} from GitHub (${_DEP_GIT_TAG})")
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
