param(
    [Parameter(Mandatory)]
    [string]$ProjectPath,

    [Parameter(Mandatory)]
    [string]$GitHubOwner
)

$ErrorActionPreference = "Stop"

# Resolve csproj
if (Test-Path $ProjectPath -PathType Container) {
    $csproj = Get-ChildItem $ProjectPath -Filter *.csproj | Select-Object -First 1
} else {
    $csproj = Get-Item $ProjectPath
}

if (-not $csproj) {
    throw "No .csproj found at $ProjectPath"
}

# Read package id + version
[xml]$xml = Get-Content $csproj.FullName
$packageId = $xml.Project.PropertyGroup.PackageId | Select-Object -First 1
$version   = $xml.Project.PropertyGroup.Version   | Select-Object -First 1

if (-not $packageId -or -not $version) {
    throw "PackageId or Version not found in csproj"
}

Write-Host "Checking NuGet package: $packageId"
Write-Host "Checking version       : $version"

$indexUrl = "https://nuget.pkg.github.com/$GitHubOwner/index.json"

# Query versions
$versions = dotnet nuget list $packageId `
    --source $indexUrl `
    --verbosity quiet 2>$null

if ($versions -match $version) {
    throw "Version $version already exists for package $packageId"
}

Write-Host "Version $version does not exist yet"
