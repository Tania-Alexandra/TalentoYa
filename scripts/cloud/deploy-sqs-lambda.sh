#!/usr/bin/env bash
set -euo pipefail

# Provisiona en AWS la DLQ, la cola SQS principal, la funcion Lambda Java 21
# y el Event Source Mapping (SQS -> Lambda) usando AWS CLI.
# Uso:
#   ./scripts/cloud/deploy-sqs-lambda.sh
#   POSTULACIONES_API_URL=https://.../api/postulaciones ./scripts/cloud/deploy-sqs-lambda.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

AWS_REGION="${AWS_REGION:-us-east-1}"
ENV_NAME="${ENV_NAME:-dev}"
DLQ_NAME="talentoya-postulaciones-dlq-${ENV_NAME}"
QUEUE_NAME="talentoya-postulaciones-queue-${ENV_NAME}"
LAMBDA_NAME="talentoya-procesador-postulaciones-${ENV_NAME}"
ROLE_NAME="talentoya-lambda-sqs-role-${ENV_NAME}"
POSTULACIONES_API_URL="${POSTULACIONES_API_URL:-}"
NOTIFICACIONES_API_URL="${NOTIFICACIONES_API_URL:-}"
API_GATEWAY_KEY="${API_GATEWAY_KEY:-talentoya-secret-key-2026}"

LAMBDA_DIR="${ROOT_DIR}/serverless/procesador-postulaciones"
JAR_PATH="${LAMBDA_DIR}/target/procesador-postulaciones-1.0.0.jar"

if [[ "${SKIP_BUILD:-false}" != "true" ]]; then
  echo "1. Compilando y empaquetando funcion Lambda Java 21..."
  mvn -B -f "${LAMBDA_DIR}/pom.xml" clean package
else
  echo "1. Usando JAR precompilado: ${JAR_PATH}"
fi

echo "2. Creando Dead Letter Queue (${DLQ_NAME})..."
DLQ_URL="$(aws sqs create-queue --region "${AWS_REGION}" --queue-name "${DLQ_NAME}" --query 'QueueUrl' --output text)"
DLQ_ARN="$(aws sqs get-queue-attributes --region "${AWS_REGION}" --queue-url "${DLQ_URL}" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)"

echo "3. Creando cola SQS principal (${QUEUE_NAME}) con RedrivePolicy hacia DLQ..."
REDRIVE_POLICY="{\"deadLetterTargetArn\":\"${DLQ_ARN}\",\"maxReceiveCount\":\"3\"}"
QUEUE_URL="$(aws sqs create-queue \
  --region "${AWS_REGION}" \
  --queue-name "${QUEUE_NAME}" \
  --attributes "VisibilityTimeout=60,MessageRetentionPeriod=345600,RedrivePolicy=${REDRIVE_POLICY//\"/\\\"}" \
  --query 'QueueUrl' --output text)"
QUEUE_ARN="$(aws sqs get-queue-attributes --region "${AWS_REGION}" --queue-url "${QUEUE_URL}" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)"

echo "4. Verificando/creando rol IAM (${ROLE_NAME})..."
if ! aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]
  }' >/dev/null
  aws iam attach-role-policy --role-name "${ROLE_NAME}" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
  echo "Esperando propagacion del rol IAM (10s)..."
  sleep 10
fi
ROLE_ARN="$(aws iam get-role --role-name "${ROLE_NAME}" --query 'Role.Arn' --output text)"

ENV_VARS="Variables={POSTULACIONES_API_URL=${POSTULACIONES_API_URL},NOTIFICACIONES_API_URL=${NOTIFICACIONES_API_URL},API_GATEWAY_KEY=${API_GATEWAY_KEY}}"

echo "5. Desplegando funcion Lambda (${LAMBDA_NAME})..."
if aws lambda get-function --region "${AWS_REGION}" --function-name "${LAMBDA_NAME}" >/dev/null 2>&1; then
  aws lambda update-function-code --region "${AWS_REGION}" --function-name "${LAMBDA_NAME}" --zip-file "fileb://${JAR_PATH}" >/dev/null
  aws lambda wait function-updated --region "${AWS_REGION}" --function-name "${LAMBDA_NAME}"
  aws lambda update-function-configuration --region "${AWS_REGION}" --function-name "${LAMBDA_NAME}" --environment "${ENV_VARS}" >/dev/null
else
  aws lambda create-function \
    --region "${AWS_REGION}" \
    --function-name "${LAMBDA_NAME}" \
    --runtime java21 \
    --role "${ROLE_ARN}" \
    --handler cl.duoc.jv0101.caso02.lambda.ProcesadorPostulacionesHandler::handleRequest \
    --zip-file "fileb://${JAR_PATH}" \
    --timeout 30 \
    --memory-size 512 \
    --environment "${ENV_VARS}" >/dev/null
fi

echo "6. Conectando trigger SQS -> Lambda..."
EXISTING_UUID="$(aws lambda list-event-source-mappings --region "${AWS_REGION}" --function-name "${LAMBDA_NAME}" --event-source-arn "${QUEUE_ARN}" --query 'EventSourceMappings[0].UUID' --output text)"
if [[ -z "${EXISTING_UUID}" || "${EXISTING_UUID}" == "None" ]]; then
  aws lambda create-event-source-mapping \
    --region "${AWS_REGION}" \
    --function-name "${LAMBDA_NAME}" \
    --event-source-arn "${QUEUE_ARN}" \
    --batch-size 10 \
    --function-response-types ReportBatchItemFailures >/dev/null
fi

echo ""
echo "=== Despliegue Cloud completado ==="
echo "AWS_SQS_ENABLED=true"
echo "AWS_REGION=${AWS_REGION}"
echo "AWS_SQS_QUEUE_URL=${QUEUE_URL}"
echo "DLQ_URL=${DLQ_URL}"
echo "LAMBDA_NAME=${LAMBDA_NAME}"
