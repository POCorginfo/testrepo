<#
Purpose:
Single entry point for PR, CI, and local builds.
#>

param(
    [ValidateSet("dotnet", "angular")]
    [string]$ProjectType = "dotnet",

    [ValidateSet("app", "library")]
    [string]$DotnetMode = "app",

    [string]$ProjectPath,
    [string]$Version,
    [string]$ImageName,
    [string]$Registry,

    [string]$SonarProjectKey,
    [string]$SonarProjectName,
    [string]$SonarOrg,
    [string]$SonarHostUrl,
    [string]$SonarToken,

    [string]$NugetApiKey,

    [bool]$Build  = $false,
    [bool]$Publish = $false
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. "$PSScriptRoot/shared/common.ps1"

Write-Info "Starting build for project type: $ProjectType"

try {

    # -----------------------------
    # Sonar start
    # -----------------------------
    if ($SonarProjectKey) {
        . "$PSScriptRoot/shared/sonar.ps1" `
            -ProjectKey  $SonarProjectKey `
            -ProjectName $SonarProjectName `
            -Organization $SonarOrg `
            -HostUrl     $SonarHostUrl `
            -Token       $SonarToken
    }

    # -----------------------------
    # Restore → Build → Test
    # -----------------------------
    switch ($ProjectType) {

        "dotnet" {
            . "$PSScriptRoot/dotnet/restore.ps1" -ProjectPath $ProjectPath
            . "$PSScriptRoot/dotnet/build.ps1"   -ProjectPath $ProjectPath
            . "$PSScriptRoot/dotnet/test.ps1"    -ProjectPath $ProjectPath
        }

        "angular" {
            . "$PSScriptRoot/angular/restore.ps1" -ProjectPath $ProjectPath
            . "$PSScriptRoot/angular/build.ps1"   -ProjectPath $ProjectPath
            . "$PSScriptRoot/angular/test.ps1"    -ProjectPath $ProjectPath
        }
    }

    # -----------------------------
    # Sonar end
    # -----------------------------
    if ($SonarProjectKey) {
        dotnet sonarscanner end /d:sonar.login="$SonarToken"
        if ($LASTEXITCODE -ne 0) {
            throw "Sonar analysis failed"
        }
    }

    # -----------------------------
    # Version resolution
    # -----------------------------
    if (-not $Version) {
        $Version = . "$PSScriptRoot/shared/version.ps1" -AppPath $ProjectPath
    }

    Write-Info "Using version: $Version"

    # -----------------------------
    # NuGet library publish
    # -----------------------------
    if ($ProjectType -eq "dotnet" -and $DotnetMode -eq "library" -and $Publish) {

        . "$PSScriptRoot/dotnet/pack-and-publish.ps1" `
            -ProjectPath $ProjectPath `
            -Configuration Release `
            -GitHubOwner "POCorginfo" `
            -GitHubToken $env:NUGET_TOKEN

        Write-Info "Library build and publish completed successfully"
        exit 0
    }

    # -----------------------------
    # App publish
    # -----------------------------
    if ($ProjectType -eq "dotnet" -and $DotnetMode -eq "app" -and $Publish) {

        . "$PSScriptRoot/dotnet/publish.ps1" `
            -ProjectPath $ProjectPath `
            -Version $Version

        Write-Info "Deployable artifact published successfully"
    }

    Write-Info "Build completed successfully"

    exit 0
}
catch {
    Write-Error "BUILD FAILED: $($_.Exception.Message)"
    exit 1
}
