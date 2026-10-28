# Starts the API against an in-memory database — no Supabase or Firebase
# account needed. All data is wiped when the server stops.
#
#   .\run-local.ps1
#
# Why this script exists: PowerShell 5.1 mangles the Maven flag form
#   mvn spring-boot:run -Dspring-boot.run.profiles=local
# splitting it at the dot into an unknown lifecycle phase, and quoting does
# not help. Setting the environment variable instead avoids the parser
# entirely.
#
# Stop the server with Ctrl+C.
$ErrorActionPreference = 'Stop'

$backend = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $backend

if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    Write-Host "Maven is not on your PATH." -ForegroundColor Red
    Write-Host "See backend/SETUP.md, section 1, for install steps."
    exit 1
}

# In-memory H2 instead of Supabase.
$env:SPRING_PROFILES_ACTIVE = 'local'

Write-Host "Starting the seller API on http://localhost:8080" -ForegroundColor Cyan
Write-Host "  health:      http://localhost:8080/actuator/health" -ForegroundColor DarkGray
Write-Host "  profile:     local (in-memory database, data is lost on stop)" -ForegroundColor DarkGray
Write-Host "  auth:        disabled - Firebase is not configured" -ForegroundColor DarkGray
Write-Host "  stop:        Ctrl+C" -ForegroundColor DarkGray
Write-Host ""

mvn spring-boot:run
