param(
    [string]$AdvertiseAddr = ""
)

$ErrorActionPreference = "Stop"

$swarmState = (docker info --format '{{.Swarm.LocalNodeState}}' 2>$null)
if ($swarmState -ne "active") {
    Write-Host "Inicializando cluster Docker Swarm..." -ForegroundColor Cyan
    if ($AdvertiseAddr) {
        docker swarm init --advertise-addr $AdvertiseAddr
    } else {
        docker swarm init
    }
} else {
    Write-Host "Docker Swarm ya se encuentra activo en este nodo." -ForegroundColor Yellow
}

$networks = docker network ls --format '{{.Name}}'
if ($networks -notcontains "talentoya-net") {
    Write-Host "Creando red overlay attachable 'talentoya-net'..." -ForegroundColor Cyan
    docker network create --driver overlay --attachable talentoya-net
}

Write-Host "`n=== Nodos actuales del cluster ===" -ForegroundColor Green
docker node ls

Write-Host "`n=== Comando para unir un nodo WORKER ===" -ForegroundColor Green
docker swarm join-token worker

Write-Host "`n=== Comando para unir un nodo MANAGER adicional ===" -ForegroundColor Green
docker swarm join-token manager
