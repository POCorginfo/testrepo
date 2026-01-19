<#
Purpose:
Scans a Docker image for vulnerabilities using Trivy.

Fails the build if HIGH or CRITICAL vulnerabilities are found.
Safe for local and CI usage.
#>

param(
    [Parameter(Mandatory)]
    [string]$ImageName,

    [Parameter(Mandatory)]
    [string]$Version,

    [string]$Registry
)

. "$PSScriptRoot/common.ps1"

$FullImage = if ($Registry) {
    "$Registry/$ImageName:$Version"
} else {
    "$ImageName:$Version"
}

Write-Info "Scanning Docker image: $FullImage"

# -----------------------------
# Ensure Trivy is available
# -----------------------------
if (-not (Get-Command trivy -ErrorAction SilentlyContinue)) {

    Write-Warn "Trivy not found"

    if ($IsLinux) {
        Write-Info "Installing Trivy on Linux..."
        sudo apt-get update
        sudo apt-get install -y trivy
    }
    elseif ($IsWindows) {
        Write-ErrorAndExit @"
Trivy is not installed.

Install using one of the following:
  choco install trivy
  winget install AquaSecurity.Trivy

Then re-run the build.
"@
    }
    elseif ($IsMacOS) {
        Write-ErrorAndExit @"
Trivy is not installed.

Install using:
  brew install trivy
"@
    }
    else {
        Write-ErrorAndExit "Unsupported OS for Trivy installation"
    }
}

# -----------------------------
# Run vulnerability scan
# -----------------------------
trivy image `
    --exit-code 1 `
    --severity HIGH,CRITICAL `
    --no-progress `
    $FullImage

Write-Success "Docker image vulnerability scan passed"
