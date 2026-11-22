# Windows Code Signing Setup

This document explains how to set up code signing for Windows binaries using the CMake modules in this project.

## Overview

The `CodeSign.cmake` module automatically signs executables with:
- **Digital signature** using your code signing certificate
- **SHA256** hash algorithm
- **Timestamp** from multiple servers (fallback chain)
- **Resilient** retry logic if timestamp servers are unavailable

## Local Development Setup

### 1. Obtain a Code Signing Certificate

You need a valid code signing certificate. Options:
- **Self-signed** (for testing only, will show "Unknown Publisher" warnings)
- **Commercial CA** (DigiCert, Sectigo, GlobalSign, etc.) — required for production

### 2. Import Certificate to Windows Certificate Store

The certificate must be in `Cert:\CurrentUser\My` (Personal store):

```powershell
# If you have a .pfx file:
Import-PfxCertificate -FilePath "path\to\your-cert.pfx" -CertStoreLocation "Cert:\CurrentUser\My"

# If you have a .cer file (public key only):
Import-Certificate -FilePath "path\to\your-cert.cer" -CertStoreLocation "Cert:\CurrentUser\My"
```

**Verify** the certificate is installed:
```powershell
Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*YourCompanyName*" }
```

Note the **Subject** field — you'll need the CN (Common Name) part.

### 3. Configure CMake

In your `CMakeLists.txt`:

```cmake
if(WIN32)
    include(Windows/CodeSign)
    aw_code_sign_target(
        TARGET your_executable_name
        CERT_NAME "Your Company Name"  # Must match certificate Subject CN
    )
endif()
```

**Find your CERT_NAME**:
```powershell
Get-ChildItem Cert:\CurrentUser\My | Select-Object Subject
# Output: CN=AI-Warevo Code Signing, O=AI-Warevo, ... 
# Use: "AI-Warevo Code Signing"
```

### 4. Build

```bash
cmake --preset your-preset
cmake --build build/your-preset --config Release
```

The signing happens **post-build** automatically. Check the output:
```
[template_cpp] Trying timestamp server: http://timestamp.digicert.com
Signing your_executable.exe with resilient timestamp fallback...
```

## CI/CD Setup (GitHub Actions)

### 1. Export Certificate as Base64

On your Windows machine with the certificate:

```powershell
# Export certificate + private key to .pfx (requires password)
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*YourCompanyName*" }
$password = ConvertTo-SecureString "YourStrongPassword" -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath "signing-cert.pfx" -Password $password

# Encode to base64
$bytes = [System.IO.File]::ReadAllBytes("signing-cert.pfx")
$base64 = [System.Convert]::ToBase64String($bytes)
$base64 | Set-Content "signing-cert.b64"

# Or use certutil:
certutil -encode signing-cert.pfx signing-cert.b64
```

**Security**: Delete `signing-cert.pfx` and `signing-cert.b64` from your machine after uploading to GitHub secrets.

### 2. Add GitHub Secrets

Go to your repository: **Settings → Secrets and variables → Actions → New repository secret**

Add two secrets:
- **`SIGNING_CERTIFICATE`**: paste the base64 content (entire .b64 file content)
- **`CERTIFICATE_PASSWORD`**: the password you used when exporting

### 3. Update GitHub Workflow

Add this step **before** the build step in `.github/workflows/release.yml`:

```yaml
- name: Import code signing certificate
  if: secrets.SIGNING_CERTIFICATE != ''
  shell: powershell
  run: |
    # Decode base64 certificate
    $certBytes = [System.Convert]::FromBase64String("${{ secrets.SIGNING_CERTIFICATE }}")
    $certPath = Join-Path $env:TEMP "cert.pfx"
    [System.IO.File]::WriteAllBytes($certPath, $certBytes)
    
    # Import to CurrentUser\My store
    $cert = Import-PfxCertificate -FilePath $certPath `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -Password (ConvertTo-SecureString "${{ secrets.CERTIFICATE_PASSWORD }}" -AsPlainText -Force)
    
    Write-Host "Certificate imported: $($cert.Subject)"
    
    # Optional: import to Trusted Root (may suppress warnings in CI)
    $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "CurrentUser")
    $rootStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $rootStore.Add($cert)
    $rootStore.Close()
    
    Remove-Item $certPath
```

The build step will automatically use the imported certificate.

## Advanced Options

### Skip Timestamp

If you don't need timestamp (not recommended — signatures without timestamps expire with the certificate):

```cmake
aw_code_sign_target(
    TARGET your_executable
    CERT_NAME "Your Company Name"
    SKIP_TIMESTAMP
)
```

### Custom Timestamp Servers

Override the default fallback chain:

```cmake
aw_code_sign_target(
    TARGET your_executable
    CERT_NAME "Your Company Name"
    TIMESTAMP_SERVERS
        "http://your-timestamp-server.com"
        "http://backup-server.com"
)
```

Default servers (tried in order):
1. `http://timestamp.digicert.com`
2. `http://timestamp.comodoca.com`
3. `http://timestamp.globalsign.com/tsa/r6advanced1`
4. `http://time.certum.pl`
5. `http://timestamp.acs.microsoft.com`

### Verify Signing

After build:

```powershell
# Check signature details
Get-AuthenticodeSignature "build\Release\your_executable.exe" | Format-List *

# Should show:
# Status        : Valid
# SignerCertificate : [Subject]
#   CN=Your Company Name
# TimeStamperCertificate : [Subject]
#   CN=DigiCert Timestamp 2023
```

## Troubleshooting

### "Cannot find the certificate and private key for decryption"

- Certificate is not in `Cert:\CurrentUser\My`
- Run: `Get-ChildItem Cert:\CurrentUser\My` to verify
- Re-import the certificate

### "CERT_NAME doesn't match any installed certificate"

- Check exact spelling: `Get-ChildItem Cert:\CurrentUser\My | Select Subject`
- Must match the **CN** part exactly (case-sensitive)

### "signtool.exe not found"

- Windows SDK not installed
- Install Visual Studio with "Windows 10 SDK" component
- Or install standalone Windows SDK

### "All timestamp servers failed"

- Network issue or all servers temporarily down
- Signing proceeds **without timestamp** (warning, not error)
- Fallback: signs locally with `/fd SHA256` only
- Signature valid but expires with certificate

### CI Build Fails: "No certificates were found that met all the given criteria"

- `SIGNING_CERTIFICATE` or `CERTIFICATE_PASSWORD` secrets not set
- Base64 encoding corrupted — re-export and re-encode
- Certificate expired — renew it

## Security Best Practices

1. **Never commit** `.pfx` or certificate files to git
2. **Use strong passwords** for `.pfx` export (min 16 chars)
3. **Rotate secrets** if exposed
4. **Use HSM/hardware tokens** for production certificates (not covered here)
5. **Restrict access** to GitHub secrets (only maintainers)

## References

- [Microsoft: Sign a file](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signing-a-file)
- [signtool.exe documentation](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool)
- [RFC 3161: Time-Stamp Protocol](https://www.ietf.org/rfc/rfc3161.txt)
