# DependencyCache.cmake — Multi-tier dependency resolution (monorepo + Docker + system + network)
#
# Resolution priority by library type:
#
# INTERNAL LIBRARIES (aw::tpl, aw::tobus):
#   1. FETCHCONTENT_SOURCE_DIR_<NAME> (explicit override)
#   2. ../<NAME> (parent directory - monorepo)
#   3. build/_deps (local build cache from prior fetches)
#   4. /opt/deps/<toolchain>/ (Docker pre-compiled, ABI-matched)
#   5. find_package() (system install)
#   6. FetchContent (GitHub fallback)
#
# EXTERNAL LIBRARIES (Catch2, spdlog, etc.):
#   1. FETCHCONTENT_SOURCE_DIR_<NAME> (explicit override)
#   2. build/_deps (local build cache)
#   3. /opt/deps/<toolchain>/ (Docker pre-compiled, ABI-matched)
#      - gcc-15: /opt/deps/gcc-15/
#      - clang-18 libstdc++: /opt/deps/clang-18-libstdc/
#      - clang-18 libc++: /opt/deps/clang-18-libc++/
#   4. /opt/deps/include (header-only: json, stb)
#   5. $ENV{AW_DEPS_DIR} (user-defined cache)
#   6. find_package() (system install)
#   7. FetchContent (network fallback)
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
        set(${_DEP_NAME}_SOURCE_DIR "${FETCHCONTENT_SOURCE_DIR_${_DEP_NAME_UPPER}}" PARENT_SCOPE)
        include(FetchContent)
        FetchContent_Declare(${_DEP_NAME} SOURCE_DIR "${FETCHCONTENT_SOURCE_DIR_${_DEP_NAME_UPPER}}")
        FetchContent_MakeAvailable(${_DEP_NAME})
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
            include(FetchContent)
            FetchContent_Declare(${_DEP_NAME} SOURCE_DIR "${CMAKE_SOURCE_DIR}/../${_DEP_DIR_NAME}")
            FetchContent_MakeAvailable(${_DEP_NAME})
            set(${_DEP_NAME}_SOURCE_DIR "${CMAKE_SOURCE_DIR}/../${_DEP_DIR_NAME}" PARENT_SCOPE)
            list(APPEND CMAKE_MODULE_PATH "${${_DEP_NAME}_SOURCE_DIR}/cmake")
            return()
        endif()
    endif()

    # 3. Check build/_deps (local build cache from previous FetchContent runs)
    if(EXISTS "${CMAKE_BINARY_DIR}/_deps/${_DEP_NAME_LOWER}-src")
        message(STATUS "Found ${_DEP_NAME} in build cache (build/_deps)")
        set(FETCHCONTENT_SOURCE_DIR_${_DEP_NAME_UPPER} "${CMAKE_BINARY_DIR}/_deps/${_DEP_NAME_LOWER}-src" PARENT_SCOPE)
        set(${_DEP_NAME}_SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/${_DEP_NAME_LOWER}-src" PARENT_SCOPE)
        include(FetchContent)
        FetchContent_Declare(${_DEP_NAME} SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/${_DEP_NAME_LOWER}-src")
        FetchContent_MakeAvailable(${_DEP_NAME})
        return()
    endif()

    # 4. Check /opt/deps/<toolchain> (Docker pre-compiled deps, ABI-matched)
    # Detect toolchain and stdlib to select correct cache directory
    set(_DEPS_VARIANT "")
    
    if(CMAKE_CXX_FLAGS MATCHES "stdlib=libc\\+\\+")
        # Using libc++
        set(_DEPS_VARIANT "clang-18-libc++")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        # clang-18 with libstdc++ (default)
        set(_DEPS_VARIANT "clang-18-libstdc")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        # gcc-15 with libstdc++
        set(_DEPS_VARIANT "gcc-15")
    endif()
    
    if(_DEPS_VARIANT)
        set(_DEPS_DIR "/opt/deps/${_DEPS_VARIANT}")
        if(EXISTS "${_DEPS_DIR}/lib/cmake/${_DEP_NAME}")
            list(PREPEND CMAKE_PREFIX_PATH "${_DEPS_DIR}")
            message(STATUS "Found ${_DEP_NAME} in ${_DEPS_DIR} (Docker ${_DEPS_VARIANT} cache)")
        endif()
    endif()
    
    # Header-only deps in shared /opt/deps/include
    if(EXISTS "/opt/deps/include")
        list(PREPEND CMAKE_PREFIX_PATH "/opt/deps")
        # Note: CMAKE_PREFIX_PATH now includes both toolchain-specific and shared header dirs
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
        # Try to find SOURCE_DIR from the found package (some packages export it)
        if(NOT DEFINED ${_DEP_NAME}_SOURCE_DIR)
            # Fallback: check Docker cache directory (toolchain-specific or shared)
            if(_DEPS_VARIANT AND EXISTS "/opt/deps/${_DEPS_VARIANT}/src/${_DEP_NAME}")
                set(${_DEP_NAME}_SOURCE_DIR "/opt/deps/${_DEPS_VARIANT}/src/${_DEP_NAME}" PARENT_SCOPE)
                message(STATUS "Set ${_DEP_NAME}_SOURCE_DIR to /opt/deps/${_DEPS_VARIANT}/src/${_DEP_NAME}")
            elseif(EXISTS "/opt/deps/src/${_DEP_NAME}")
                set(${_DEP_NAME}_SOURCE_DIR "/opt/deps/src/${_DEP_NAME}" PARENT_SCOPE)
                message(STATUS "Set ${_DEP_NAME}_SOURCE_DIR to /opt/deps/src/${_DEP_NAME}")
            endif()
        else()
            set(${_DEP_NAME}_SOURCE_DIR "${${_DEP_NAME}_SOURCE_DIR}" PARENT_SCOPE)
        endif()
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
    set(${_DEP_NAME}_SOURCE_DIR "${${_DEP_NAME}_SOURCE_DIR}" PARENT_SCOPE)
endfunction()
