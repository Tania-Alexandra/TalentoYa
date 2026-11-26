#!/usr/bin/env bash
set -euo pipefail

# Inicializa el nodo Manager de Docker Swarm y muestra los comandos para unir nodos.
# Uso:
#   ./scripts/swarm/02-init-swarm.sh [ADVERTISE_ADDR]

ADVERTISE_ADDR="${1:-}"
SWARM_STATE="$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo 'inactive')"

if [[ "${SWARM_STATE}" != "active" ]]; then
  echo "Inicializando cluster Docker Swarm..."
  if [[ -n "${ADVERTISE_ADDR}" ]]; then
    docker swarm init --advertise-addr "${ADVERTISE_ADDR}"
  else
    docker swarm init
  fi
else
  echo "Docker Swarm ya se encuentra activo en este nodo."
fi

if ! docker network ls --format '{{.Name}}' | grep -qx "talentoya-net"; then
  echo "Creando red overlay attachable 'talentoya-net'..."
  docker network create --driver overlay --attachable talentoya-net
fi

echo ""
echo "=== Nodos actuales del cluster ==="
docker node ls

echo ""
echo "=== Comando para unir un nodo WORKER ==="
docker swarm join-token worker

echo "=== Comando para unir un nodo MANAGER adicional ==="
docker swarm join-token manager
