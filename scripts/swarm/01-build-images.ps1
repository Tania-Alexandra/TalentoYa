param(
    [string]$Registry = $(if ($env:DOCKER_REGISTRY) { $env:DOCKER_REGISTRY } else { "duoc" }),
    [string]$Tag = $(if ($env:IMAGE_TAG) { $env:IMAGE_TAG } else { "1.0.0" }),
    [switch]$Push
)

$ErrorActionPreference = "Stop"
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $RootDir

try {
    $env:DOCKER_REGISTRY = $Registry
    $env:IMAGE_TAG = $Tag

    Write-Host "Construyendo imagenes ($Registry/jv0101-caso02-*:$Tag)..." -ForegroundColor Cyan
    docker compose -f docker-compose.yml -f docker-compose.build.yml build

    if ($Push) {
        Write-Host "Publicando imagenes en $Registry..." -ForegroundColor Cyan
        docker compose -f docker-compose.yml -f docker-compose.build.yml push
    }

    Write-Host "Imagenes listas:" -ForegroundColor Green
    docker images --format "table {{.Repository}}`t{{.Tag}}`t{{.Size}}" | Select-String "jv0101-caso02"
}
finally {
    Pop-Location
}
