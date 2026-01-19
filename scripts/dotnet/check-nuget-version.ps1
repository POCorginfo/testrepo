<#
Purpose:
- Fails if the NuGet package version already exists in GitHub Packages
- Passes if the version is NOT published yet
- Uses PackageId + Version from the .csproj
- Designed for CI guard checks
#>

param(
    [Parameter(Mandatory)]
    [string]$ProjectPath,   # path to .csproj or project folder

    [Parameter(Mandatory)]
    [string]$GitHubOwner,

    [string]$GitHubToken = $env:GITHUB_TOKEN
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
    throw "GITHUB_TOKEN not provided"
}

# -----------------------------
# Authenticate (temp source)
# -----------------------------
$sourceName = "github-check"
$sourceUrl  = "https://nuget.pkg.github.com/$GitHubOwner/index.json"

dotnet nuget remove source $sourceName 2>$null | Out-Null

dotnet nuget add source $sourceUrl `
    --name $sourceName `
    --username $GitHubOwner `
    --password $GitHubToken `
    --store-password-in-clear-text

# -----------------------------
# Check version
# -----------------------------
$versions = dotnet nuget list $packageId `
    --source $sourceName `
    --verbosity quiet

# dotnet nuget list returns exit code 1 if no versions exist
$global:LASTEXITCODE = 0

if ($versions -match [regex]::Escape($version)) {
    Write-Error "NuGet package $packageId version $version is already published"
    exit 1
}

Write-Host "Version $version is not published yet"
exit 0
