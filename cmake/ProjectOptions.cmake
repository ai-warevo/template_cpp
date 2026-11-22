# Shared project options and subdirectory helpers.

macro(aw_project_prepare)
    set(_oneValue NAME NAMESPACE VERSION_FILE)
    cmake_parse_arguments(_PREP "" "${_oneValue}" "" ${ARGN})

    if(NOT _PREP_NAME OR NOT _PREP_NAMESPACE)
        message(FATAL_ERROR "aw_project_prepare() requires NAME and NAMESPACE arguments")
    endif()

    if(_PREP_VERSION_FILE)
        aw_project_config(
            NAME "${_PREP_NAME}"
            NS "${_PREP_NAMESPACE}"
            VERSION_FILE "${_PREP_VERSION_FILE}")
    else()
        aw_project_config(NAME "${_PREP_NAME}" NS "${_PREP_NAMESPACE}")
    endif()
endmacro()

function(aw_project_setup)
    set(_oneValue PREFIX)
    set(_options BUILD_TESTS BUILD_EXAMPLES BUILD_APP BUILD_OVERLAY INSTALL)
    cmake_parse_arguments(_SETUP "${_options}" "${_oneValue}" "" ${ARGN})

    if(NOT _SETUP_PREFIX)
        message(FATAL_ERROR "aw_project_setup() requires PREFIX argument")
    endif()

    aw_configure_warnings()
    set(AW_WARNINGS "${AW_WARNINGS}" PARENT_SCOPE)
    set(AW_STRICT_WARNINGS "${AW_STRICT_WARNINGS}" PARENT_SCOPE)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON PARENT_SCOPE)

    if(_SETUP_BUILD_TESTS)
        option(${_SETUP_PREFIX}_BUILD_TESTS
            "Build ${_SETUP_PREFIX} unit tests" ${PROJECT_IS_TOP_LEVEL})
    endif()
    if(_SETUP_BUILD_EXAMPLES)
        option(${_SETUP_PREFIX}_BUILD_EXAMPLES
            "Build ${_SETUP_PREFIX} examples" ${PROJECT_IS_TOP_LEVEL})
    endif()
    if(_SETUP_BUILD_APP)
        option(${_SETUP_PREFIX}_BUILD_APP
            "Build ${_SETUP_PREFIX} standalone application" ON)
    endif()
    if(_SETUP_BUILD_OVERLAY)
        option(${_SETUP_PREFIX}_BUILD_OVERLAY
            "Build ${_SETUP_PREFIX} embeddable overlay library" ON)
    endif()
    if(_SETUP_INSTALL)
        option(${_SETUP_PREFIX}_INSTALL
            "Generate install rules for ${_SETUP_PREFIX}" ${PROJECT_IS_TOP_LEVEL})
    endif()

    option(${_SETUP_PREFIX}_WARNINGS_AS_ERRORS
        "Build ${_SETUP_PREFIX} with strict warnings treated as errors" OFF)
    option(AW_ENABLE_COVERAGE "Enable code coverage instrumentation" OFF)
    set(AW_SANITIZE "none" CACHE STRING
        "Sanitizer to enable: none, address (ASan+UBSan) or thread (TSan)")
    set_property(CACHE AW_SANITIZE PROPERTY STRINGS none address thread)
endfunction()

function(aw_setup_optional_subdirectory)
    set(_oneValue OPTION DIRECTORY)
    cmake_parse_arguments(_SUB "" "${_oneValue}" "" ${ARGN})

    if(NOT _SUB_OPTION OR NOT _SUB_DIRECTORY)
        message(FATAL_ERROR
            "aw_setup_optional_subdirectory() requires OPTION and DIRECTORY arguments")
    endif()
    if(${_SUB_OPTION} AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${_SUB_DIRECTORY}/CMakeLists.txt")
        add_subdirectory("${_SUB_DIRECTORY}")
    endif()
endfunction()
