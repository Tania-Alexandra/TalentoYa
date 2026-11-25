#!/usr/bin/env bash
set -euo pipefail

# Construye las 7 imagenes Docker de TalentoYa.
# Uso:
#   ./scripts/swarm/01-build-images.sh
#   DOCKER_REGISTRY=ghcr.io/usuario IMAGE_TAG=1.0.0 PUSH=true ./scripts/swarm/01-build-images.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

export DOCKER_REGISTRY="${DOCKER_REGISTRY:-duoc}"
export IMAGE_TAG="${IMAGE_TAG:-1.0.0}"
PUSH="${PUSH:-false}"

echo "Construyendo imagenes (${DOCKER_REGISTRY}/jv0101-caso02-*:${IMAGE_TAG})..."
docker compose -f docker-compose.yml -f docker-compose.build.yml build

if [[ "${PUSH}" == "true" ]]; then
  echo "Publicando imagenes en ${DOCKER_REGISTRY}..."
  docker compose -f docker-compose.yml -f docker-compose.build.yml push
fi

echo "Imagenes listas:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep "jv0101-caso02" || true
