<#
Purpose:
Shared helper functions used across all scripts.
Includes logging, validation, and common error handling.
This file must be imported by every script.
#>

function Write-Info($msg) {
    Write-Host "ℹ️  $msg" -ForegroundColor Cyan
}

function Write-ErrorAndExit($msg) {
    Write-Host "❌ $msg" -ForegroundColor Red
    exit 1
}

# Ensures required CLI tools are available
function Require-Command($cmd) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-ErrorAndExit "$cmd is not installed"
    }
}
