param(
    # Root folders where .NET projects live
    [string[]]$SourceRoots = @("src")
)

Write-Host "======================================"
Write-Host "🔍 Detecting changed .NET projects"
Write-Host "Event        : $($env:GITHUB_EVENT_NAME)"
Write-Host "Ref          : $($env.GITHUB_REF)"
Write-Host "======================================"

# -------------------------------------------------
# Determine diff range (CRITICAL LOGIC)
# -------------------------------------------------

$diffRange = $null

switch ($env:GITHUB_EVENT_NAME) {

    "pull_request" {
        Write-Host "PR detected → diff against origin/main"
        git fetch origin main --quiet
        $diffRange = "origin/main...HEAD"
    }

    "push" {
        # Covers: merge commit, squash merge, multiple commits
        if (git rev-parse HEAD~1 2>$null) {
            Write-Host "Push detected → diff against previous commit"
            $diffRange = "HEAD~1...HEAD"
        }
        else {
            Write-Host "Initial commit detected → full rebuild"
            $diffRange = "HEAD"
        }
    }

    default {
        Write-Host "Unsupported event → exiting"
        "matrix=" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
        exit 0
    }
}

Write-Host "Diff range   : $diffRange"
Write-Host "--------------------------------------"

# -------------------------------------------------
# Get changed files
# -------------------------------------------------

$changedFiles = git diff --name-only $diffRange

if (-not $changedFiles) {
    Write-Host "✅ No files changed"
    "matrix=" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    exit 0
}

Write-Host "Changed files:"
$changedFiles | ForEach-Object { Write-Host " - $_" }

# -------------------------------------------------
# Detect affected projects
# -------------------------------------------------

$projects = New-Object System.Collections.Generic.HashSet[string]
$fullRebuild = $false

foreach ($file in $changedFiles) {

    # Ignore non-code changes
    if ($file -match "^docs/|\.md$") {
        continue
    }

    # Shared/common code → rebuild everything
    if ($file -match "^src/Common/") {
        Write-Host "⚠ Shared code changed → full rebuild"
        $fullRebuild = $true
        break
    }

    # If csproj itself changed
    if ($file -like "*.csproj") {
        $projects.Add((Split-Path $file -Parent)) | Out-Null
        continue
    }

    # Walk up directory tree to find nearest csproj
    $dir = Split-Path $file -Parent
    while ($dir -and $dir -ne ".") {
        $csproj = Get-ChildItem $dir -Filter *.csproj -ErrorAction SilentlyContinue
        if ($csproj) {
            $projects.Add($dir) | Out-Null
            break
        }

        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
}

# -------------------------------------------------
# Full rebuild → include all projects
# -------------------------------------------------

if ($fullRebuild) {
    Write-Host "Including all projects for full rebuild"
    foreach ($root in $SourceRoots) {
        if (Test-Path $root) {
            Get-ChildItem $root -Recurse -Filter *.csproj |
                ForEach-Object {
                    $projects.Add($_.DirectoryName) | Out-Null
                }
        }
    }
}

# -------------------------------------------------
# Output result
# -------------------------------------------------

if ($projects.Count -eq 0) {
    Write-Host "✅ No .NET project changes detected"
    "matrix=" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    exit 0
}

$matrix = @{
    include = @(
        $projects | ForEach-Object {
            @{ project = $_ }
        }
    )
}

$json = $matrix | ConvertTo-Json -Compress

Write-Host "--------------------------------------"
Write-Host "📦 Build matrix:"
Write-Host $json
Write-Host "======================================"

"matrix=$json" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
