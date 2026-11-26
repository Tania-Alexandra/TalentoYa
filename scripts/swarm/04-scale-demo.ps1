param(
    [string]$ServiceName = "talentoya_postulaciones-svc",
    [int]$Replicas = 4
)

$ErrorActionPreference = "Stop"

Write-Host "Estado actual de ${ServiceName}:" -ForegroundColor Cyan
docker service ps $ServiceName

Write-Host "`nEscalando ${ServiceName} a $Replicas replicas..." -ForegroundColor Cyan
docker service scale "${ServiceName}=$Replicas"

Write-Host "`nReplicas activas tras el escalado:" -ForegroundColor Green
docker service ps $ServiceName
