# aw_code_sign_target()
#
# Sign a target binary using signtool.exe from the Windows SDK.
# Falls back to signing without timestamp if all timestamp servers
# are unavailable or rate-limited.
#
# Usage:
#   include(cmake/Windows/CodeSign)
#   aw_code_sign_target(my_target
#       CERT_NAME "My Certificate"
#       TIMESTAMP_SERVERS "http://timestamp.digicert.com"
#                         "http://timestamp.acs.microsoft.com")
#
# Only works on Windows; silently returns on other platforms.
#
# Parameters:
#   TARGET              - target name (required)
#   CERT_NAME           - certificate subject name (default: "Code Signing")
#   TIMESTAMP_SERVERS   - list of timestamp URLs (default: 5 well-known servers)
#   SKIP_TIMESTAMP      - if ON, sign without timestamp

function(aw_code_sign_target)
    if(NOT WIN32)
        return()
    endif()

    set(_oneValue TARGET CERT_NAME SKIP_TIMESTAMP)
    set(_multiValue TIMESTAMP_SERVERS)
    cmake_parse_arguments(_SIGN "" "${_oneValue}" "${_multiValue}" ${ARGN})

    if(NOT _SIGN_TARGET)
        message(FATAL_ERROR "aw_code_sign_target() requires TARGET argument")
    endif()

    if(NOT _SIGN_CERT_NAME)
        set(_SIGN_CERT_NAME "Code Signing")
    endif()

    if(NOT _SIGN_TIMESTAMP_SERVERS)
        set(_SIGN_TIMESTAMP_SERVERS
            "http://timestamp.digicert.com"
            "http://comodoca.com"
            "http://globalsign.com"
            "http://certum.pl"
            "http://timestamp.acs.microsoft.com"
        )
    endif()

    # Find signtool.exe
    include(Windows/WindowsSDK)
    aw_find_winsdk_tool(VAR _sign_tool TOOL_NAME signtool.exe TYPE PROGRAM PLATFORM x64)

    if(NOT _sign_tool)
        message(WARNING "aw_code_sign_target(): signtool.exe not found — skipping signing for ${_SIGN_TARGET}")
        return()
    endif()

    if(_SIGN_SKIP_TIMESTAMP)
        # Sign without timestamp (ignore errors if no cert)
        add_custom_command(TARGET ${_SIGN_TARGET} POST_BUILD
            COMMAND powershell.exe -Command "& '${_sign_tool}' sign /s MY /n '${_SIGN_CERT_NAME}' /fd SHA256 '$<TARGET_FILE:${_SIGN_TARGET}>' 2>$null; exit 0"
            COMMENT "Signing ${_SIGN_TARGET} without timestamp..."
            VERBATIM
        )
    else()
        # Sign with resilient timestamp fallback
        string(REPLACE ";" "','" _servers_array "${_SIGN_TIMESTAMP_SERVERS}")
        set(_servers_array "'${_servers_array}'")

        add_custom_command(TARGET ${_SIGN_TARGET} POST_BUILD
            COMMAND powershell.exe -Command
                "$servers = @(${_servers_array}); "
                "$signed = $false; "
                "foreach ($server in $servers) { "
                "    Write-Host '[template_cpp] Trying timestamp server:' $server; "
                "    & '${_sign_tool}' sign /s MY /n '${_SIGN_CERT_NAME}' /tr $server /td sha256 /fd SHA256 '$<TARGET_FILE:${_SIGN_TARGET}>' 2>`$null; "
                "    if ($LASTEXITCODE -eq 0) { $signed = $true; break } "
                "}; "
                "if (-not $signed) { "
                "    Write-Warning '[template_cpp] All timestamp servers failed. Signing locally without timestamp...'; "
                "    & '${_sign_tool}' sign /s MY /n '${_SIGN_CERT_NAME}' /fd SHA256 '$<TARGET_FILE:${_SIGN_TARGET}>' 2>`$null "
                "}; "
                "exit 0"
            COMMENT "Signing ${_SIGN_TARGET} with resilient timestamp fallback..."
            VERBATIM
        )
    endif()
endfunction()
