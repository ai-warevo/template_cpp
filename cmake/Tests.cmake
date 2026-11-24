# aw_setup_tests()
#
# Top-level CMakeLists.txt: include CTest and add tests/ subdirectory if present.
#
# Usage:
#   include(cmake/Tests)
#   aw_setup_tests()

macro(aw_setup_tests)
    set(_oneValue OPTION DIRECTORY)
    cmake_parse_arguments(_SETUP "" "${_oneValue}" "" ${ARGN})

    if(NOT _SETUP_OPTION AND NOT _SETUP_DIRECTORY)
        if(PROJECT_IS_TOP_LEVEL AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/CMakeLists.txt")
            include(CTest)
            if(BUILD_TESTING)
                add_subdirectory(tests)
            endif()
        endif()
    elseif(NOT _SETUP_OPTION OR NOT _SETUP_DIRECTORY)
        message(FATAL_ERROR "aw_setup_tests() requires OPTION and DIRECTORY arguments")
    elseif(${_SETUP_OPTION} AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${_SETUP_DIRECTORY}/CMakeLists.txt")
        include(CTest)
        if(BUILD_TESTING)
            add_subdirectory("${_SETUP_DIRECTORY}")
        endif()
    endif()
endmacro()

# aw_test_target()
#
# tests/CMakeLists.txt: declare a test executable with Catch2.
#
# Usage:
#   include(cmake/Tests)
#   aw_test_target(NAME MyLib SOURCES a_tests.cpp b_tests.cpp LINK_TARGET aw::MyLib)
#   aw_test_target(NAME MyLib TESTS_SOURCE mylib_tests.cpp LINK_TARGET aw::MyLib)   # single file, still supported
#
# Link target can be:
#   - core variant:  aw::MyLib::MyLib_core
#   - main lib:      aw::MyLib
#   - shared lib:    aw::MyLib

function(aw_test_target)
    set(_oneValue NAME TESTS_SOURCE LINK_TARGET)
    set(_multiValue SOURCES)
    set(_options STRICT_WARNINGS)
    cmake_parse_arguments(_TEST "${_options}" "${_oneValue}" "${_multiValue}" ${ARGN})

    if(NOT _TEST_NAME)
        message(FATAL_ERROR "aw_test_target() requires NAME argument")
    endif()
    list(APPEND _TEST_SOURCES ${_TEST_TESTS_SOURCE})
    if(NOT _TEST_SOURCES)
        message(FATAL_ERROR "aw_test_target() requires SOURCES (or TESTS_SOURCE) argument")
    endif()
    if(NOT _TEST_LINK_TARGET)
        message(FATAL_ERROR "aw_test_target() requires LINK_TARGET argument")
    endif()

    # --- Catch2 v3 (use enhanced dependency resolution) ---
    include(DependencyCache)
    aw_fetch_dependency(
        NAME Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG v3.7.1
        OPTIONS
            BUILD_TESTING OFF
            CATCH_INSTALL_DOCS OFF)
    list(APPEND CMAKE_MODULE_PATH "${Catch2_SOURCE_DIR}/extras" "${catch2_SOURCE_DIR}/extras")
    include(Catch)

    # --- Test executable ---
    add_executable(${_TEST_NAME}_tests ${_TEST_SOURCES})
    target_link_libraries(${_TEST_NAME}_tests PRIVATE ${_TEST_LINK_TARGET} Catch2::Catch2WithMain)
    if(COMMAND aw_configure_compiler)
        if(_TEST_STRICT_WARNINGS)
            aw_configure_compiler(TARGET ${_TEST_NAME}_tests STRICT_WARNINGS)
        else()
            aw_configure_compiler(TARGET ${_TEST_NAME}_tests)
        endif()
    else()
        target_compile_options(${_TEST_NAME}_tests PRIVATE ${AW_WARNINGS})
    endif()
    catch_discover_tests(${_TEST_NAME}_tests)
endfunction()
