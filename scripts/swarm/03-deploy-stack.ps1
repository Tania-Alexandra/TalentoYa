param(
    [string]$StackName = "talentoya",
    [string]$Registry = $(if ($env:DOCKER_REGISTRY) { $env:DOCKER_REGISTRY } else { "duoc" }),
    [string]$Tag = $(if ($env:IMAGE_TAG) { $env:IMAGE_TAG } else { "1.0.0" })
)

$ErrorActionPreference = "Stop"
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $RootDir

try {
    $env:DOCKER_REGISTRY = $Registry
    $env:IMAGE_TAG = $Tag

    Write-Host "Desplegando stack '$StackName' en Docker Swarm..." -ForegroundColor Cyan
    docker stack deploy -c docker-compose.yml --resolve-image changed $StackName

    Write-Host "`n=== Servicios del stack '$StackName' ===" -ForegroundColor Green
    docker stack services $StackName

    Write-Host "`n=== Tareas (contenedores) desplegadas ===" -ForegroundColor Green
    docker stack ps $StackName --no-trunc
}
finally {
    Pop-Location
}
