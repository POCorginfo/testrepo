<#
Purpose:
Restores .NET dependencies for the project.
#>

param(
    [Parameter(Mandatory)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"

try {
    Write-Host "Restoring .NET dependencies in $ProjectPath"

    Push-Location $ProjectPath

    dotnet restore

    if ($LASTEXITCODE -ne 0) {
        throw "dotnet restore failed for $ProjectPath"
    }

    Write-Host "Restore completed successfully"
}
catch {
    Write-Error "Restore failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Pop-Location -ErrorAction SilentlyContinue
}
