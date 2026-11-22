# aw_win_version()
#
# Generate WIN32 resource (.rc) and C++ header (.h) with version info
# for use in WIN32 executables.
#
# Usage:
#   include(cmake/Windows/WinVersion)
#   aw_win_version(OUTVAR my_resource
#       NAME "My Application"
#       VERSION_MAJOR 1
#       VERSION_MINOR 0
#       VERSION_PATCH 0
#       COMPANY_NAME "My Company"
#       COMPANY_COPYRIGHT "Copyright 2024"
#       ICON "${CMAKE_SOURCE_DIR}/res/app.ico")
#
# Only works on Windows; silently returns on other platforms.
#
# Parameters:
#   OUTVAR              - output variable to receive generated files (required)
#   NAME                - product name (required)
#   VERSION_MAJOR       - major version (default: 1)
#   VERSION_MINOR       - minor version (default: 0)
#   VERSION_PATCH       - patch version (default: 0)
#   VERSION_REVISION    - revision (default: 0)
#   VERSION_FULL        - full version string (overrides individual parts)
#   COMPANY_NAME        - company name (default: empty)
#   COMPANY_COPYRIGHT   - copyright string (default: "${COMPANY_NAME} (C) Copyright <year>")
#   COMMENTS            - comments (default: "${NAME} v${MAJOR}.${MINOR}")
#   FILE_DESCRIPTION    - file description (default: "${NAME}")
#   ORIGINAL_FILENAME   - original filename (default: "${NAME}")
#   INTERNAL_NAME       - internal name (default: "${NAME}")

function(aw_win_version)
    if(NOT WIN32)
        return()
    endif()

    set(_oneValue OUTVAR NAME
        VERSION_MAJOR VERSION_MINOR VERSION_PATCH VERSION_REVISION VERSION_FULL
        COMPANY_NAME COMPANY_COPYRIGHT
        COMMENTS FILE_DESCRIPTION ORIGINAL_FILENAME INTERNAL_NAME
        ICON)
    set(_multiValue)
    cmake_parse_arguments(_VER "${_multiValue}" "${_oneValue}" "${_multiValue}" ${ARGN})

    if(NOT _VER_OUTVAR)
        message(FATAL_ERROR "aw_win_version() requires OUTVAR argument")
    endif()
    if(NOT _VER_NAME)
        message(FATAL_ERROR "aw_win_version() requires NAME argument")
    endif()

    # --- Bundle defaults to NAME ---
    if(NOT _VER_COMPANY_NAME OR "${_VER_COMPANY_NAME}" STREQUAL "")
        set(_VER_COMPANY_NAME "${_VER_NAME}")
    endif()

    # --- Icon defaults to project root product.ico ---
    if(NOT _VER_ICON OR "${_VER_ICON}" STREQUAL "")
        set(_VER_ICON "${CMAKE_SOURCE_DIR}/product.ico")
    endif()

    # --- Version parsing ---
    if(_VER_VERSION_FULL)
        string(REPLACE "." ";" _ver_list ${_VER_VERSION_FULL})
        list(GET _ver_list 0 _VER_VERSION_MAJOR)
        list(GET _ver_list 1 _VER_VERSION_MINOR)
        list(GET _ver_list 2 _VER_VERSION_PATCH)
        set(_VER_VERSION_REVISION 0)
    else()
        if(NOT _VER_VERSION_MAJOR EQUAL 0 AND (NOT _VER_VERSION_MAJOR OR "${_VER_VERSION_MAJOR}" STREQUAL ""))
            set(_VER_VERSION_MAJOR 1)
        endif()
        if(NOT _VER_VERSION_MINOR EQUAL 0 AND (NOT _VER_VERSION_MINOR OR "${_VER_VERSION_MINOR}" STREQUAL ""))
            set(_VER_VERSION_MINOR 0)
        endif()
        if(NOT _VER_VERSION_PATCH EQUAL 0 AND (NOT _VER_VERSION_PATCH OR "${_VER_VERSION_PATCH}" STREQUAL ""))
            set(_VER_VERSION_PATCH 0)
        endif()
        if(NOT _VER_VERSION_REVISION EQUAL 0 AND (NOT _VER_VERSION_REVISION OR "${_VER_VERSION_REVISION}" STREQUAL ""))
            set(_VER_VERSION_REVISION 0)
        endif()
    endif()

    # --- Defaults for optional strings ---
    if(NOT _VER_COMPANY_COPYRIGHT OR "${_VER_COMPANY_COPYRIGHT}" STREQUAL "")
        string(TIMESTAMP _ver_year "%Y")
        set(_VER_COMPANY_COPYRIGHT "${_VER_COMPANY_NAME} (C) Copyright ${_ver_year}")
    endif()
    if(NOT _VER_COMMENTS OR "${_VER_COMMENTS}" STREQUAL "")
        set(_VER_COMMENTS "${_VER_NAME} v${_VER_VERSION_MAJOR}.${_VER_VERSION_MINOR}")
    endif()
    if(NOT _VER_FILE_DESCRIPTION OR "${_VER_FILE_DESCRIPTION}" STREQUAL "")
        set(_VER_FILE_DESCRIPTION "${_VER_NAME}")
    endif()
    if(NOT _VER_ORIGINAL_FILENAME OR "${_VER_ORIGINAL_FILENAME}" STREQUAL "")
        set(_VER_ORIGINAL_FILENAME "${_VER_NAME}")
    endif()
    if(NOT _VER_INTERNAL_NAME OR "${_VER_INTERNAL_NAME}" STREQUAL "")
        set(_VER_INTERNAL_NAME "${_VER_NAME}")
    endif()

    # --- Generate VersionInfo.h ---
    set(_version_info_h "${CMAKE_CURRENT_BINARY_DIR}/VersionInfo.h")
    file(WRITE "${_version_info_h}"
"#pragma once\n"
"#define AW_WIN_VERSION_NAME          \"${_VER_NAME}\"\n"
"#define AW_WIN_VERSION_COMPANY       \"${_VER_COMPANY_NAME}\"\n"
"#define AW_WIN_VERSION_COPYRIGHT     \"${_VER_COMPANY_COPYRIGHT}\"\n"
"#define AW_WIN_VERSION_COMMENTS      \"${_VER_COMMENTS}\"\n"
"#define AW_WIN_VERSION_FILE_DESC     \"${_VER_FILE_DESCRIPTION}\"\n"
"#define AW_WIN_VERSION_ORIG_NAME     \"${_VER_ORIGINAL_FILENAME}\"\n"
"#define AW_WIN_VERSION_INT_NAME      \"${_VER_INTERNAL_NAME}\"\n"
"#define AW_WIN_VERSION_ICON          \"${_VER_ICON}\"\n"
"#define AW_WIN_VERSION_MAJOR         ${_VER_VERSION_MAJOR}\n"
"#define AW_WIN_VERSION_MINOR         ${_VER_VERSION_MINOR}\n"
"#define AW_WIN_VERSION_PATCH         ${_VER_VERSION_PATCH}\n"
"#define AW_WIN_VERSION_REVISION      ${_VER_VERSION_REVISION}\n"
"#define AW_WIN_VERSION_FULL          \"${_VER_VERSION_MAJOR}.${_VER_VERSION_MINOR}.${_VER_VERSION_PATCH}.${_VER_VERSION_REVISION}\"\n"
"\n"
"#define WIN32_VER(major,minor,patch,rev) \\\n"
"    major,minor,patch,rev\n"
)

    # --- Generate VersionResource.rc ---
    set(_version_rc "${CMAKE_CURRENT_BINARY_DIR}/VersionResource.rc")
    file(WRITE "${_version_rc}"
"; Version resource for ${_VER_NAME}\n"
"; Generated by aw_win_version()\n"
"\n"
"#include \"VersionInfo.h\"\n"
"\n"
"#if defined(__MINGW64__) || defined(__MINGW32__)\n"
"  // MinGW-w64, MinGW\n"
"  #if defined(__has_include) && __has_include(<winres.h>)\n"
"    #include <winres.h>\n"
"  #else\n"
"    #include <afxres.h>\n"
"    #include <winresrc.h>\n"
"  #endif\n"
"#else\n"
"  // MSVC, Windows SDK\n"
"  #include <winres.h>\n"
"#endif\n"
"\n"
"IDI_ICON1 ICON AW_WIN_VERSION_ICON\n"
"\n"
"1 VERSIONINFO\n"
"FILEVERSION ${_VER_VERSION_MAJOR},${_VER_VERSION_MINOR},${_VER_VERSION_PATCH},${_VER_VERSION_REVISION}\n"
"PRODUCTVERSION ${_VER_VERSION_MAJOR},${_VER_VERSION_MINOR},${_VER_VERSION_PATCH},${_VER_VERSION_REVISION}\n"
"BEGIN\n"
"  BLOCK \"StringFileInfo\"\n"
"  BEGIN\n"
"    BLOCK \"040904b0\"\n"
"    BEGIN\n"
"      VALUE \"CompanyName\",       \"${_VER_COMPANY_NAME}\"\n"
"      VALUE \"FileDescription\",   \"${_VER_FILE_DESCRIPTION}\"\n"
"      VALUE \"FileVersion\",       \"${_VER_VERSION_MAJOR}.${_VER_VERSION_MINOR}.${_VER_VERSION_PATCH}.${_VER_VERSION_REVISION}\"\n"
"      VALUE \"InternalName\",      \"${_VER_INTERNAL_NAME}\"\n"
"      VALUE \"LegalCopyright\",    \"${_VER_COMPANY_COPYRIGHT}\"\n"
"      VALUE \"OriginalFilename\",  \"${_VER_ORIGINAL_FILENAME}\"\n"
"      VALUE \"ProductName\",       \"${_VER_NAME}\"\n"
"      VALUE \"ProductVersion\",    \"${_VER_VERSION_MAJOR}.${_VER_VERSION_MINOR}.${_VER_VERSION_PATCH}.${_VER_VERSION_REVISION}\"\n"
"    END\n"
"  END\n"
"  BLOCK \"VarFileInfo\"\n"
"  BEGIN\n"
"    VALUE \"Translation\", 0x409, 1200\n"
"  END\n"
"END\n"
    )

    set(${_VER_OUTVAR} "${_version_info_h}" "${_version_rc}" PARENT_SCOPE)
endfunction()
