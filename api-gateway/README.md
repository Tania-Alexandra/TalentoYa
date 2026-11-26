# API Gateway — Protección y Enrutamiento de Microservicios (IE12)

Implementa una arquitectura de doble capa perimetral para proteger el backend distribuido en Docker Swarm:

1. **Gateway interno en Swarm (`api-gateway`, puerto `8090`):**
   * Enruta por DNS interno de la red overlay `talentoya-net` hacia los 7 microservicios (`/api/perfiles`, `/api/registroLaborales`, `/api/postulaciones`, `/api/ofertaTrabajos`, `/api/notificaciones`, `/api/mensajes`, `/api/facturas`).
   * **Autenticación por API Key:** exige el header `X-API-Key` (configurable con `GATEWAY_API_KEY`, por defecto `talentoya-secret-key-2026`). Sin el header devuelve `401 Unauthorized`.
   * **Rate Limiting:** limita a `10 req/s` (`burst=20`) por IP cliente; exceder el límite devuelve `429 Too Many Requests`.
   * **Bloqueo de consolas internas:** rechaza con `403 Forbidden` cualquier intento de acceso externo a `/h2-console`.
   * **Hardening HTTP:** oculta versión del servidor y añade `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection` y `Referrer-Policy`.
2. **Amazon API Gateway (`aws-apigw-template.yaml`):**
   * Exposición HTTPS administrada en AWS (`AWS::ApiGatewayV2::Api`) con throttling (`25 req/s`, `burst=50`) y CORS hacia el gateway del clúster Swarm.

## Pruebas rápidas de seguridad (para demostrar IE12 en el video)

```bash
# 1. Salud publica del Gateway -> 200 OK
curl -i http://localhost:8090/health

# 2. Peticion sin API Key -> 401 Unauthorized
curl -i http://localhost:8090/api/postulaciones

# 3. Intento de acceder a consola interna H2 -> 403 Forbidden
curl -i http://localhost:8090/h2-console

# 4. Peticion autorizada con X-API-Key -> 200 OK / 201 Created
curl -i -H "X-API-Key: talentoya-secret-key-2026" http://localhost:8090/api/postulaciones
```

## Despliegue de Amazon API Gateway en AWS

```bash
BACKEND_BASE_URL="http://<IP_PUBLICA_SWARM>:8090" ./scripts/cloud/deploy-apigw.sh
```
