#!/usr/bin/env bash
set -euo pipefail

# Demostracion de escalado dinamico en Docker Swarm (IE8).
# Uso:
#   ./scripts/swarm/04-scale-demo.sh [SERVICIO] [REPLICAS]
# Ejemplo:
#   ./scripts/swarm/04-scale-demo.sh talentoya_postulaciones-svc 4

SERVICE_NAME="${1:-talentoya_postulaciones-svc}"
REPLICAS="${2:-4}"

echo "Estado actual de ${SERVICE_NAME}:"
docker service ps "${SERVICE_NAME}"

echo ""
echo "Escalando ${SERVICE_NAME} a ${REPLICAS} replicas..."
docker service scale "${SERVICE_NAME}=${REPLICAS}"

echo ""
echo "Replicas activas tras el escalado:"
docker service ps "${SERVICE_NAME}"
