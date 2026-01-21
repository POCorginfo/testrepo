<#
Purpose:
Builds the .NET project in Release mode.
Assumes restore has already been completed.
#>

param(
    [Parameter(Mandatory)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"

try {
    Write-Host "Building .NET project in $ProjectPath"

    Push-Location $ProjectPath

    dotnet build --configuration Release --no-restore

    if ($LASTEXITCODE -ne 0) {
        throw "dotnet build failed for $ProjectPath"
    }

    Write-Host "Build succeeded"
}
catch {
    Write-Error "Build failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Pop-Location -ErrorAction SilentlyContinue
}
