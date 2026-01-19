<#
Purpose:
Generates a Docker image version for a specific app using:
<BaseVersion from app/version.txt>-<short git commit SHA>

Why:
- Supports monorepo with multiple apps
- Keeps scripts reusable
- Ensures independent versioning per app
#>

param(
    [Parameter(Mandatory)]
    [string]$AppPath   # Example: apps/product-api
)

# Load shared helpers (logging, error handling)
. "$PSScriptRoot/common.ps1"

try {
    if ($env:GITHUB_SHA) {
        $Commit = $env:GITHUB_SHA.Substring(0,7)
    }
    elseif (Test-Path ".git") {
        $Commit = (git rev-parse --short HEAD)
    }
    else {
        $Commit = "local"
    }
}
catch {
    $Commit = "local"
}

$FinalVersion = "1.0.0+$Commit"

Write-Info "Resolved image version for [$AppPath]: $FinalVersion"
$FinalVersion
