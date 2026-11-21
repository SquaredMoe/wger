# Windows 11 local-first wger bootstrap. Run in PowerShell after installing
# Docker Desktop (WSL2 backend) and Git. Does NOT start containers.
# All generated secrets remain on this machine; never push prod.env to GitHub.
param(
    [string]$Destination = (Join-Path $HOME "wger-personal-stack")
)
$ErrorActionPreference = "Stop"

function Get-SecureHex([int]$ByteCount) {
    $bytes = New-Object byte[] $ByteCount
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return ([BitConverter]::ToString($bytes)).Replace("-", "").ToLowerInvariant()
}

function Replace-Env([string]$Source, [string]$Key, [string]$Value) {
    $pattern = "(?m)^" + [regex]::Escape($Key) + "=.*$"
    if (-not [regex]::IsMatch($Source, $pattern)) {
        throw "Expected key missing from upstream config/prod.env: $Key"
    }
    return [regex]::Replace($Source, $pattern, ($Key + "=" + $Value))
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Install Git for Windows first."
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Install Docker Desktop with the WSL2 backend first."
}
$composeVersionOutput = (& docker compose version --short | Out-String)
if ($LASTEXITCODE -ne 0) { throw "Docker Compose is unavailable." }
$match = [regex]::Match($composeVersionOutput, "[0-9]+\.[0-9]+\.[0-9]+")
if (-not $match.Success -or ([version]$match.Value -lt [version]"2.24.4")) {
    throw "Docker Compose 2.24.4 or later is required for the local-only port override."
}
& docker info *> $null
if ($LASTEXITCODE -ne 0) { throw "Start Docker Desktop and wait for its engine to be ready." }
if (Test-Path $Destination) {
    throw "Destination already exists: $Destination. Nothing was changed; choose a new directory to avoid overwriting data."
}

& git clone --depth 1 "https://github.com/wger-project/docker.git" $Destination
if ($LASTEXITCODE -ne 0) { throw "Could not clone the official wger Docker stack." }
Set-Location $Destination

# The upstream docker stack tracks config/prod.env. Remove its Git metadata
# from this local *runtime* checkout to prevent accidentally publishing secrets.
Remove-Item -LiteralPath (Join-Path $Destination ".git") -Recurse -Force

$envPath = Join-Path $Destination "config/prod.env"
$settings = Get-Content -LiteralPath $envPath -Raw
$databasePassword = Get-SecureHex 24
$syncPassword = Get-SecureHex 24
$settings = Replace-Env $settings "SECRET_KEY" (Get-SecureHex 48)
$settings = Replace-Env $settings "POSTGRES_PASSWORD" $databasePassword
$settings = Replace-Env $settings "PS_DATABASE_URI" ("postgres://wger:" + $databasePassword + "@db:5432/wger")
$settings = Replace-Env $settings "PS_STORAGE_PG_URI" ("postgres://powersync_storage:" + $syncPassword + "@db:5432/wger")
$settings = Replace-Env $settings "SITE_URL" "http://localhost:8080"
$settings = Replace-Env $settings "TIME_ZONE" "Asia/Beirut"
$settings = Replace-Env $settings "TZ" "Asia/Beirut"
$settings = Replace-Env $settings "ALLOW_REGISTRATION" "False"
$settings = Replace-Env $settings "CELERY_FLOWER_PASSWORD" (Get-SecureHex 24)
[System.IO.File]::WriteAllText($envPath, $settings, (New-Object System.Text.UTF8Encoding($false)))

$override = @'
services:
  nginx:
    ports: !override
      - "127.0.0.1:8080:80"
'@
[System.IO.File]::WriteAllText(
    (Join-Path $Destination "docker-compose.override.yml"),
    ($override + "`n"),
    (New-Object System.Text.UTF8Encoding($false))
)

& docker compose config --quiet
if ($LASTEXITCODE -ne 0) { throw "Compose validation failed. Containers were not started." }
Write-Host ""
Write-Host "Validated the local-only wger stack in: $Destination"
Write-Host "Database, app secret, PowerSync storage and timezone configured."
Write-Host "NO containers started. NEXT: follow docs/personal-fitness/README.md."
Write-Host "IMPORTANT: rotate JWT signing keys and the default admin password before external access."
