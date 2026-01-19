<#
Purpose:
- Fail if NuGet package version already exists in GitHub Packages
- Pass if version does NOT exist
- Reliable REST-based check (no NuGet CLI quirks)
#>

param(
    [Parameter(Mandatory)]
    [string]$ProjectPath,

    [Parameter(Mandatory)]
    [string]$GitHubOwner,

    [string]$GitHubToken = $env:NUGET_TOKEN
)

$ErrorActionPreference = "Stop"

# -----------------------------
# Resolve csproj
# -----------------------------
if (Test-Path $ProjectPath -PathType Container) {
    $csproj = Get-ChildItem $ProjectPath -Filter *.csproj | Select-Object -First 1
} else {
    $csproj = Get-Item $ProjectPath
}

if (-not $csproj) {
    throw "No .csproj found at $ProjectPath"
}

# -----------------------------
# Read PackageId + Version
# -----------------------------
[xml]$xml = Get-Content $csproj.FullName
$packageId = $xml.Project.PropertyGroup.PackageId | Select-Object -First 1
$version   = $xml.Project.PropertyGroup.Version   | Select-Object -First 1

if (-not $packageId -or -not $version) {
    throw "PackageId or Version not found in csproj"
}

Write-Host "Checking NuGet package: $packageId"
Write-Host "Checking version       : $version"

if (-not $GitHubToken) {
    throw "NUGET_TOKEN not provided"
}

# -----------------------------
# GitHub REST API check
# -----------------------------
$headers = @{
    Authorization = "Bearer $GitHubToken"
    Accept        = "application/vnd.github+json"
}

$uri = "https://api.github.com/orgs/$GitHubOwner/packages/nuget/$packageId/versions?per_page=100"

try {
    $versions = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET
} catch {
    throw "Failed to query GitHub Packages API. Check token permissions."
}

$exists = $versions | Where-Object {
    $_.name -eq $version
}

if ($exists) {
    Write-Error "NuGet package $packageId version $version is already published"
    exit 1
}

Write-Host "Version $version is not published yet"
exit 0
