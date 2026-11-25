#!/usr/bin/env bash
set -euo pipefail

# Despliega Amazon API Gateway HTTP API (v2) mediante CloudFormation.
# Uso:
#   BACKEND_BASE_URL=http://<IP_SWARM>:8090 ./scripts/cloud/deploy-apigw.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

AWS_REGION="${AWS_REGION:-us-east-1}"
ENV_NAME="${ENV_NAME:-dev}"
STACK_NAME="talentoya-apigw-${ENV_NAME}"
BACKEND_BASE_URL="${BACKEND_BASE_URL:?Define BACKEND_BASE_URL (ej. http://1.2.3.4:8090)}"

echo "Desplegando Amazon API Gateway (${STACK_NAME}) -> ${BACKEND_BASE_URL}..."
aws cloudformation deploy \
  --region "${AWS_REGION}" \
  --stack-name "${STACK_NAME}" \
  --template-file "${ROOT_DIR}/api-gateway/aws-apigw-template.yaml" \
  --parameter-overrides \
    EnvironmentName="${ENV_NAME}" \
    BackendBaseUrl="${BACKEND_BASE_URL}" \
  --no-fail-on-empty-changeset

APIGW_URL="$(aws cloudformation describe-stacks \
  --region "${AWS_REGION}" \
  --stack-name "${STACK_NAME}" \
  --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrl'].OutputValue" \
  --output text)"

echo ""
echo "=== Amazon API Gateway desplegado ==="
echo "APIGW_URL=${APIGW_URL}"
