param(
    [Parameter(Mandatory)]
    [string]$ProjectPath,

    [Parameter(Mandatory)]
    [string]$Version,

    [string]$Configuration = "Release"
)

$projectName = Split-Path $ProjectPath -Leaf
$publishDir  = Join-Path $PSScriptRoot "..\..\artifacts\$projectName\publish"
$zipDir      = Join-Path $PSScriptRoot "..\..\artifacts\$projectName"
$zipPath     = Join-Path $zipDir "$projectName-$Version.zip"

Write-Info "Publishing $projectName ($Configuration)"

dotnet publish $ProjectPath `
    -c $Configuration `
    -o $publishDir `
    /p:Version=$Version

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Write-Info "Creating deployable zip: $zipPath"

Compress-Archive `
    -Path "$publishDir\*" `
    -DestinationPath $zipPath

Write-Info "Publish artifact created successfully"
