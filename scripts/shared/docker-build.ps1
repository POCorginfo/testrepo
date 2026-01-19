<#
Purpose:
Builds a Docker image locally.
Used in PR and CI pipelines.
Does NOT push the image to any registry.
#>

param(
    [string]$Registry,
    [string]$ImageName,
    [string]$Version
)

. "$PSScriptRoot/common.ps1"
Require-Command docker

# Build image tag correctly
if ([string]::IsNullOrWhiteSpace($Registry)) {
    $FullImage = "${ImageName}:${Version}"
}
else {
    $FullImage = "${Registry}/${ImageName}:${Version}"
}

Write-Info "Building Docker image: $FullImage"

docker build -t $FullImage .
if ($LASTEXITCODE -ne 0) {
    Write-ErrorAndExit "Docker build failed"
}
