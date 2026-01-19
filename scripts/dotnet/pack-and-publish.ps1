<#
- Packs and publishes a .NET library to GitHub Packages.
- Uses the <Version> from the .csproj
- Packs the library into a NuGet package
- Publishes to GitHub Packages using GITHUB_TOKEN
#>

param(
    [Parameter(Mandatory)]
    [string]$ProjectPath,   # path to .csproj or project folder

    [string]$Configuration = "Release",

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
# Read version from csproj
# -----------------------------
[xml]$xml = Get-Content $csproj.FullName
$version = $xml.Project.PropertyGroup.Version | Select-Object -First 1

if (-not $version) {
    throw "Version not found in csproj"
}

Write-Host "NuGet Version: $version"

# -----------------------------
# Pack
# -----------------------------
$output = "nupkg"
New-Item -ItemType Directory -Force -Path $output | Out-Null

dotnet pack $csproj.FullName `
    -c $Configuration `
    -o $output `
    --no-build

# -----------------------------
# Find package
# -----------------------------
$package = Get-ChildItem $output -Filter "*.nupkg" | Select-Object -First 1
if (-not $package) {
    throw "NuGet package not created"
}

# -----------------------------
# Publish to GitHub Packages
# -----------------------------
if (-not $GitHubOwner) {
    throw "GitHubOwner is required"
}

if (-not $GitHubToken) {
    throw "GITHUB_TOKEN not provided"
}

$source = "https://nuget.pkg.github.com/$GitHubOwner/index.json"

dotnet nuget push $package.FullName `
    --source $source `
    --api-key $GitHubToken `

Write-Host "NuGet package published successfully: $($package.Name)"
