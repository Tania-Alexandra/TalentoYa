#!/usr/bin/env bash
set -euo pipefail

# Despliega el stack 'talentoya' en Docker Swarm.
# Uso:
#   ./scripts/swarm/03-deploy-stack.sh [STACK_NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

STACK_NAME="${1:-talentoya}"
export DOCKER_REGISTRY="${DOCKER_REGISTRY:-duoc}"
export IMAGE_TAG="${IMAGE_TAG:-1.0.0}"

echo "Desplegando stack '${STACK_NAME}' en Docker Swarm..."
docker stack deploy -c docker-compose.yml --resolve-image changed "${STACK_NAME}"

echo ""
echo "=== Servicios del stack '${STACK_NAME}' ==="
docker stack services "${STACK_NAME}"

echo ""
echo "=== Tareas (contenedores) desplegadas ==="
docker stack ps "${STACK_NAME}" --no-trunc
