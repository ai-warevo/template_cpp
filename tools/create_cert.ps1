# Create self-signed code signing certificate for GitSync
# Run as Administrator:
# powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\create_cert.ps1

# Check Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script MUST be run as Administrator! Please restart PowerShell as Admin."
    exit
}

# 1. Generate code signing certificate directly into CurrentUser Personal Store
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=AI-Warevo Code Signing" -NotAfter (Get-Date).AddYears(5) -CertStoreLocation "Cert:\CurrentUser\My"
if ($null -eq $cert) {
    Write-Error "Failed to generate self-signed certificate."
    exit
}

$thumb = $cert.Thumbprint
Write-Host "Certificate created inside CurrentUser\My with Thumbprint: $thumb" -ForegroundColor Cyan

try {
    # 2. Open CurrentUser Trusted Root Certification Authorities store
    $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "CurrentUser")
    $rootStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $rootStore.Add($cert)
    $rootStore.Close()

    # 3. Open CurrentUser Trusted Publishers store (Removes SmartScreen window)
    $pubStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPublisher", "CurrentUser")
    $pubStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $pubStore.Add($cert)
    $pubStore.Close()

    Write-Host "Success! Certificate 'AI-Warevo Code Signing' is ready for use." -ForegroundColor Green
}
catch {
    Write-Error "Failed to register certificate. Details: $($_.Exception.Message)"
}
