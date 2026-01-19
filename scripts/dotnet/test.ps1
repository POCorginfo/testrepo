<#
Purpose:
Runs .NET tests in Release mode.
Assumes build has already been completed.
#>

param(
    [Parameter(Mandatory)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"

try {
    Write-Host "Running .NET tests in $ProjectPath"

    Push-Location $ProjectPath

    dotnet test `
        --configuration Release `
        --no-build

    if ($LASTEXITCODE -ne 0) {
        throw "dotnet test failed for $ProjectPath"
    }

    Write-Host "Tests passed successfully"
}
catch {
    Write-Error "Tests failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Pop-Location -ErrorAction SilentlyContinue
}
