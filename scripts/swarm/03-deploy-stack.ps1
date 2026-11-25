param(
    [string]$StackName = "talentoya",
    [string]$Registry = $(if ($env:DOCKER_REGISTRY) { $env:DOCKER_REGISTRY } else { "duoc" }),
    [string]$Tag = $(if ($env:IMAGE_TAG) { $env:IMAGE_TAG } else { "1.0.0" }),
    [string]$ResolveImage = ""
)

$ErrorActionPreference = "Stop"
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $RootDir

try {
    $env:DOCKER_REGISTRY = $Registry
    $env:IMAGE_TAG = $Tag

    if (-not $ResolveImage) {
        $ResolveImage = if ($Registry -eq "duoc") { "never" } else { "changed" }
    }

    Write-Host "Desplegando stack '$StackName' en Docker Swarm (resolve-image=$ResolveImage)..." -ForegroundColor Cyan
    docker stack deploy -c docker-compose.yml --resolve-image $ResolveImage $StackName

    Write-Host "`n=== Servicios del stack '$StackName' ===" -ForegroundColor Green
    docker stack services $StackName

    Write-Host "`n=== Tareas (contenedores) desplegadas ===" -ForegroundColor Green
    docker stack ps $StackName --no-trunc
}
finally {
    Pop-Location
}
