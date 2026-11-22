# aw_code_sign_target()
#
# Sign a target binary using signtool.exe from the Windows SDK.
# Falls back to signing without timestamp if all timestamp servers
# are unavailable or rate-limited.
#
# Usage:
#   include(Windows/CodeSign)
#   aw_code_sign_target(TARGET my_target
#       CERT_NAME "My Certificate Subject CN")
#
# Only works on Windows; silently returns on other platforms.
#
# SETUP INSTRUCTIONS:
#
#   LOCAL BUILD (Windows Developer Machine):
#   ==========================================
#   1. Import certificate to Cert:\CurrentUser\My store:
#      powershell> Import-PfxCertificate -FilePath "cert.pfx" -CertStoreLocation "Cert:\CurrentUser\My"
#
#   2. Find certificate subject CN:
#      powershell> Get-ChildItem Cert:\CurrentUser\My | Select Subject
#      Output: CN=AI-Warevo Code Signing, O=AI-Warevo, ...
#      Use CERT_NAME: "AI-Warevo Code Signing"
#
#   CI/CD BUILD (GitHub Actions):
#   =============================
#   1. Export certificate + private key:
#      powershell> $cert = Get-ChildItem Cert:\CurrentUser\My | Where { $_.Subject -like "*YourName*" }
#      powershell> $pwd = ConvertTo-SecureString "password" -AsPlainText -Force
#      powershell> Export-PfxCertificate -Cert $cert -FilePath "cert.pfx" -Password $pwd
#
#   2. Encode to base64:
#      powershell> $bytes = [System.IO.File]::ReadAllBytes("cert.pfx")
#      powershell> [System.Convert]::ToBase64String($bytes) | Set-Content "cert.b64"
#      powershell> (Get-Content "cert.b64") | wc -c  # verify not empty
#
#   3. Add GitHub secrets:
#      - Go to repo Settings → Secrets → New secret
#      - SIGNING_CERTIFICATE = paste entire cert.b64 content
#      - CERTIFICATE_PASSWORD = your password
#
#   4. Workflow will auto-import certificate before build
#      (see .github/workflows/release.yml)
#
# PARAMETERS:
#   TARGET              - CMake target name (required)
#   CERT_NAME           - certificate Subject CN (required, case-sensitive)
#   TIMESTAMP_SERVERS   - list of timestamp URLs (optional, uses default fallback)
#   SKIP_TIMESTAMP      - if ON, sign without timestamp (not recommended)
#
# TROUBLESHOOTING:
#   - "Cannot find certificate": Check Cert:\CurrentUser\My (use Get-ChildItem)
#   - "CERT_NAME doesn't match": Must match CN exactly (case-sensitive)
#   - "signtool.exe not found": Install Windows SDK or Visual Studio with C++ tools
#   - "All timestamp servers failed": Build continues with local timestamp (not ideal)
#
# VERIFY SIGNATURE:
#   powershell> Get-AuthenticodeSignature "output.exe" | Format-List *
#   Should show Status: Valid, SignerCertificate with your CN


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
        # Sign without timestamp
        add_custom_command(TARGET ${_SIGN_TARGET} POST_BUILD
            COMMAND powershell.exe -Command "& '${_sign_tool}' sign /s MY /n '${_SIGN_CERT_NAME}' /fd SHA256 '$<TARGET_FILE:${_SIGN_TARGET}>'"
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
                "    & '${_sign_tool}' sign /s MY /n '${_SIGN_CERT_NAME}' /fd SHA256 '$<TARGET_FILE:${_SIGN_TARGET}>' "
                "}"
            COMMENT "Signing ${_SIGN_TARGET} with resilient timestamp fallback..."
            VERBATIM
        )
    endif()
endfunction()
