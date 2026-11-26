# Función Serverless (AWS Lambda) — Procesador de Postulaciones (IE10, IE11, IE13, IE14)

Función FaaS desarrollada en **Java 21** que consume mensajes desde **AWS SQS** generados por el microservicio `talento-ya-ms-postulaciones`, procesa cada evento `PostulacionCreada` y actualiza el estado de la postulación a `PROCESADA` (además de registrar la notificación correspondiente si está configurada).

## 1. Flujo Asíncrono

```text
POST /api/postulaciones (Productor)
   │  Guarda en BD con estado = EN_COLA
   ▼
AWS SQS (talentoya-postulaciones-queue-dev)  ──(3 fallos)──▶ DLQ
   │  Event Source Mapping (BatchSize=10, ReportBatchItemFailures)
   ▼
AWS Lambda (ProcesadorPostulacionesHandler)
   ├──▶ PUT {POSTULACIONES_API_URL}/{id}  (estado -> PROCESADA)
   └──▶ POST {NOTIFICACIONES_API_URL}     (registra alerta)
```

## 2. Compilar y probar localmente

```bash
cd serverless/procesador-postulaciones
mvn clean verify
```

El JAR empaquetado para AWS Lambda se genera en `target/procesador-postulaciones-1.0.0.jar`.

## 3. Despliegue en AWS

### Opción A: Usando AWS SAM (`serverless/template.yaml`)

```bash
cd serverless
mvn -f procesador-postulaciones/pom.xml clean package
sam deploy --guided --template-file template.yaml --stack-name talentoya-serverless
```

### Opción B: Usando AWS CLI (`scripts/cloud/`)

```bash
# Linux / macOS / Git Bash
POSTULACIONES_API_URL="https://<API-GATEWAY>/api/postulaciones" \
NOTIFICACIONES_API_URL="https://<API-GATEWAY>/api/notificaciones" \
./scripts/cloud/deploy-sqs-lambda.sh

# Windows PowerShell
.\scripts\cloud\deploy-sqs-lambda.ps1 `
  -PostulacionesApiUrl "https://<API-GATEWAY>/api/postulaciones" `
  -NotificacionesApiUrl "https://<API-GATEWAY>/api/notificaciones"
```

## 4. Conectar el productor (`talento-ya-ms-postulaciones`)

Configura estas variables de entorno al desplegar `postulaciones-svc` en Docker Swarm o local:

```bash
export AWS_SQS_ENABLED=true
export AWS_REGION=us-east-1
export AWS_SQS_QUEUE_URL="<URL entregada por el despliegue>"
```

## 5. Prueba de la función y del flujo E2E

1. **Prueba unitaria de invocación directa en AWS Lambda** usando [`event-sqs-sample.json`](event-sqs-sample.json):
   ```bash
   aws lambda invoke \
     --function-name talentoya-procesador-postulaciones-dev \
     --payload fileb://event-sqs-sample.json \
     --cli-binary-format raw-in-base64-out \
     response.json
   cat response.json
   ```
2. **Prueba End-to-End (Productor → SQS → Lambda → Callback):**
   ```bash
   curl -X POST http://<HOST>:8082/api/postulaciones \
     -H "Content-Type: application/json" \
     -d '{"nombre":"Tania Gaete","oferta":"Desarrollador Java Cloud"}'
   ```
   * Respuesta inicial: `"estado": "EN_COLA"`.
   * Logs en CloudWatch (`/aws/lambda/talentoya-procesador-postulaciones-dev`) muestran el consumo automático del mensaje desde SQS.
   * Al consultar `GET /api/postulaciones/{id}` (si `POSTULACIONES_API_URL` está configurada), el estado cambia a `"PROCESADA"`.
