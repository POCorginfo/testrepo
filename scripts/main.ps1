<#
Purpose:
Single entry point for PR, CI, and local builds.
#>

param(

    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"


Write-Host "Starting build for project type: $ProjectType"

try {

    # -----------------------------
    # Restore → Build → Test
    # -----------------------------
	. "$PSScriptRoot/tasks/Restore-DotNetProject.ps1" -ProjectPath $ProjectPath
    . "$PSScriptRoot/tasks/Build-DotNetProject.ps1"   -ProjectPath $ProjectPath
    . "$PSScriptRoot/tasks/Test-DotNetProject.ps1"    -ProjectPath $ProjectPath

    # -----------------------------
    # NuGet library publish
    # -----------------------------
    $isPrerelease = $env:GITHUB_EVENT_NAME -eq "pull_request"

    . "$PSScriptRoot/tasks/Publish-NuGetPackage.ps1" `
        -ProjectPath $ProjectPath `
        -Configuration Release `
        -GitHubOwner "POCorginfo" `
        -GitHubToken $env:NUGET_TOKEN `
        -IsPrerelease $isPrerelease

    Write-Host "Library build and publish completed successfully"
    exit 0
}
catch {
    Write-Error "BUILD FAILED: $($_.Exception.Message)"
    exit 1
}
