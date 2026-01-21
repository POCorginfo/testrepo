<#
Purpose:
Single entry point for PR, CI, and local builds.
#>

param(

    [string]$ProjectPath,
    [bool]$Publish = $false
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/shared/common.ps1"

Write-Info "Starting build for project type: $ProjectType"

try {

    # -----------------------------
    # Restore → Build → Test
    # -----------------------------
	. "$PSScriptRoot/server/restore.ps1" -ProjectPath $ProjectPath
    . "$PSScriptRoot/server/build.ps1"   -ProjectPath $ProjectPath
    . "$PSScriptRoot/server/test.ps1"    -ProjectPath $ProjectPath

    # -----------------------------
    # NuGet library publish
    # -----------------------------
    if ($Publish) {

    $isPrerelease = $env:GITHUB_EVENT_NAME -eq "pull_request"

    . "$PSScriptRoot/dotnet/pack-and-publish.ps1" `
        -ProjectPath $ProjectPath `
        -Configuration Release `
        -GitHubOwner "shivaniagrawal5396" `
        -GitHubToken $env:NUGET_TOKEN `
        -IsPrerelease $isPrerelease

    Write-Info "Library build and publish completed successfully"
    exit 0
}
}
catch {
    Write-Error "BUILD FAILED: $($_.Exception.Message)"
    exit 1
}
