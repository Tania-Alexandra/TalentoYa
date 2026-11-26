# TalentoYa - Monorepo de Microservicios (EP02)

Proyecto correspondiente a la **Evaluación Parcial N°2 (EP02)** de la asignatura *Java: Diseño y Construcción de Soluciones Nativas en Nube* (JVY0101). La solución organiza microservicios desarrollados con Spring Boot, persistencia relacional con JPA/Hibernate y control de versiones con Git.

---

## 1. Descripción del Caso de Negocio
**Talento Ya** es una plataforma HR Tech orientada a trabajadores independientes, profesionales y freelancers. Permite centralizar el CV digital, postularse a ofertas laborales con un clic, recibir alertas en tiempo real y acumular historial y valoraciones auditables.

---

## 2. Requerimientos Clave y Drivers de Arquitectura
* **Escalabilidad (RNF-01):** Desacoplamiento asíncrono mediante colas **AWS SQS** y Workers **AWS Lambda** para procesar ráfagas masivas de postulaciones sin pérdida de datos.
* **Disponibilidad y Resiliencia (RNF-02):** Aislamiento de microservicios con **Circuit Breaker** (Resilience4j). Una degradación en el chat no bloquea el proceso de postulación.
* **Mantenibilidad (RNF-03):** Contenedores independientes desplegados en **AWS ECS Fargate** con patrón *Database-per-Service*.
* **Seguridad (RNF-04):** Cumplimiento de la Ley 19.628 (protección de datos personales), autenticación **OAuth 2.0 / JWT** vía **Amazon API Gateway** + **Cognito**, y cifrado integral at-rest con **AWS KMS**.
* **Rendimiento (RNF-05):** Notificaciones push/email distribuidas en menos de 60 segundos tras la publicación de vacantes.

---

## 3. Estructura del Proyecto

El proyecto consolida los siete microservicios en un monorepo dentro del directorio `ms/`:

| Microservicio | Responsabilidad |
| :--- | :--- |
| `ms/talento-ya-ms-perfiles` | Gestión de datos curriculares y perfiles de candidatos. |
| `ms/talento-ya-ms-postulaciones` | Orquestación y estado del ciclo de postulación en 1 clic. |
| `ms/talento-ya-ms-busqueda` | Catálogo de vacantes y búsqueda de ofertas laborales. |
| `ms/talento-ya-ms-historial` | Historial de antecedentes, contratos y valoraciones. |
| `ms/talento-ya-ms-notificaciones` | Emisión de eventos y alertas del sistema. |
| `ms/talento-ya-ms-mensajeria` | Comunicación y mensajería directa. |
| `ms/talento-ya-ms-facturacion` | Gestión de transacciones, cobros y facturación. |

Cada microservicio incluye su propio `pom.xml`, Maven Wrapper (`mvnw`), configuración y código fuente.

## 4. Requisitos Previos

* **Java JDK:** Versión 21 LTS.
* **Maven:** Apache Maven 3.9+ o el Maven Wrapper `./mvnw` incluido en cada microservicio.
* **Git:** Versión 2.x o superior.
* **Base de datos local:** H2 en memoria, configurada por microservicio.

## 5. Despliegue y Ejecución Local (IE10)

### Paso 1: Clonar el repositorio y ubicarse en `develop`

```bash
git clone https://github.com/Tania-Alexandra/TalentoYa.git
cd TalentoYa
git checkout develop
```

### Paso 2: Compilar y empaquetar (IE7)

Ejemplo con el microservicio de perfiles:

```bash
cd ms/talento-ya-ms-perfiles
./mvnw clean package -DskipTests
```

El archivo JAR ejecutable se genera en `target/`.

### Paso 3: Ejecutar el microservicio

Desde el directorio del microservicio:

```bash
./mvnw spring-boot:run
```

Para ejecutar todos los microservicios simultáneamente, cada uno usa un puerto local distinto:

| Microservicio | Puerto |
| :--- | :--- |
| Perfiles | `8080` |
| Historial | `8081` |
| Postulaciones | `8082` |
| Búsqueda | `8083` |
| Notificaciones | `8084` |
| Mensajería | `8085` |
| Facturación | `8086` |

En ejecución local, el puerto se puede cambiar con la variable de entorno `PORT`. Docker Compose publica cada servicio en el puerto de la tabla y conserva el puerto interno `8080`; para personalizar el puerto publicado, usa una variable específica: `PERFILES_PORT`, `HISTORIAL_PORT`, `POSTULACIONES_PORT`, `BUSQUEDA_PORT`, `NOTIFICACIONES_PORT`, `MENSAJERIA_PORT` o `FACTURACION_PORT`.

## 6. Persistencia y Consola H2 (IE4 e IE5)

Cada microservicio tiene una base H2 en memoria configurada con JPA/Hibernate. Para perfiles, con el servicio en ejecución:

* **Consola:** `http://localhost:8080/h2-console` (Perfiles; usa el puerto correspondiente para los demás microservicios)
* **Driver:** `org.h2.Driver`
* **JDBC URL:** `jdbc:h2:mem:perfilesdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE`
* **Usuario:** `sa`
* **Contraseña:** vacía

Los datos en memoria se pierden al detener el servicio.

## 7. Endpoints, Swagger y Postman (IE1 e IE3)

Con el servicio en ejecución:

* **Swagger UI:** `http://localhost:8080/swagger-ui.html`
* **Especificación OpenAPI:** `http://localhost:8080/v3/api-docs`

No hay actualmente una colección Postman incluida en el repositorio. Los endpoints CRUD pueden probarse desde Swagger UI.

## 8. Patrones y Drivers de Arquitectura

Los siguientes elementos forman parte de los drivers y patrones definidos para la arquitectura del caso:

* **API Gateway:** Punto único de entrada, enrutamiento, rate limiting y validación de seguridad.
* **Service Discovery:** Descubrimiento dinámico de instancias mediante AWS Cloud Map / Eureka.
* **Circuit Breaker:** Tolerancia a fallos y corte de dependencias degradadas.
* **Queue-Based Load Leveling:** Amortiguación de tráfico concurrente con AWS SQS.
* **Database-per-Service:** Desacoplamiento del modelo de datos por servicio.

## 9. Despliegue Distribuido con Docker Swarm (EP03 - IE3, IE7, IE8, IE9)

El repositorio incluye un [`docker-compose.yml`](docker-compose.yml) global adaptado a **Docker Swarm** (sin directivas incompatibles como `build` o `container_name`, con red `overlay`, límites de recursos, políticas de actualización *zero-downtime* y réplicas configurables), junto con [`docker-compose.build.yml`](docker-compose.build.yml) para construir las 7 imágenes y scripts de administración en [`scripts/swarm/`](scripts/swarm/).

### 9.1. Construir las imágenes Docker

Antes de desplegar en Swarm, construye las 7 imágenes optimizadas (multi-stage Alpine + Spring Boot layered JAR + usuario no-root):

```bash
# Linux / macOS / Git Bash
./scripts/swarm/01-build-images.sh

# Windows PowerShell
.\scripts\swarm\01-build-images.ps1
```

Para publicar en un registry remoto (por ejemplo GitHub Container Registry):

```bash
DOCKER_REGISTRY=ghcr.io/tania-alexandra IMAGE_TAG=1.0.0 PUSH=true ./scripts/swarm/01-build-images.sh
```

### 9.2. Inicializar el clúster (nodo Manager principal)

```bash
# Linux / macOS / Git Bash (opcional: pasar IP anunciada como argumento)
./scripts/swarm/02-init-swarm.sh

# Windows PowerShell
.\scripts\swarm\02-init-swarm.ps1
```

Este paso ejecuta `docker swarm init`, crea la red `overlay` (`talentoya-net`) e imprime los tokens de unión para nodos **worker** y **manager**.

### 9.3. Añadir nodos Worker y Manager al clúster

1. **Obtener los tokens de unión** desde el nodo Manager principal:
   ```bash
   docker swarm join-token worker    # Token para nodos de cómputo (workers)
   docker swarm join-token manager   # Token para nodos de control (managers)
   ```
2. **Unir un nodo Worker** (ejecutar el comando generado en la máquina worker):
   ```bash
   docker swarm join --token <SWMTKN-WORKER> <IP-MANAGER>:2377
   ```
3. **Unir un nodo Manager adicional** (para alta disponibilidad del plano de control mediante quórum Raft; se recomienda número impar de managers: 1, 3 o 5):
   ```bash
   docker swarm join --token <SWMTKN-MANAGER> <IP-MANAGER>:2377
   ```
4. **Verificar y administrar roles de nodos** desde cualquier Manager:
   ```bash
   docker node ls                        # Lista nodos, estado y rol (Leader / Reachable / Worker)
   docker node promote <NODE-HOSTNAME>   # Promueve un worker a manager
   docker node demote <NODE-HOSTNAME>    # Degrada un manager a worker
   ```

### 9.4. Desplegar los servicios distribuidos (`docker stack deploy`)

```bash
# Linux / macOS / Git Bash
./scripts/swarm/03-deploy-stack.sh

# Windows PowerShell
.\scripts\swarm\03-deploy-stack.ps1
```

Comandos útiles de verificación:

```bash
docker stack services talentoya               # Estado y réplicas (ej. 2/2) de los 7 servicios
docker stack ps talentoya                     # Distribución de tareas/contenedores por nodo
docker service logs -f talentoya_postulaciones-svc
```

> El enrutamiento **ingress (Routing Mesh)** de Swarm permite consultar cualquier servicio usando el puerto publicado (`8080`–`8086`) en la IP de **cualquier** nodo del clúster.

### 9.5. Escalado dinámico de réplicas (IE8)

Para ajustar réplicas hacia arriba o abajo según demanda sin detener el servicio:

```bash
# Usando el script incluido
./scripts/swarm/04-scale-demo.sh talentoya_postulaciones-svc 4

# O directamente con Docker CLI
docker service scale talentoya_postulaciones-svc=4 talentoya_busqueda-ofertas-svc=3
docker service ps talentoya_postulaciones-svc

# Reducir réplicas tras el pico de carga
docker service scale talentoya_postulaciones-svc=2
```

### 9.6. Decisiones técnicas del clúster (IE9)

* **Escalabilidad:** Servicios críticos de mayor tráfico (`perfiles-svc`, `postulaciones-svc`, `busqueda-ofertas-svc`) inician con `replicas: 2` y el resto con `1`, parametrizables por variables de entorno (`*_REPLICAS`) y escalables en caliente con `docker service scale`. La preferencia `spread: node.id` distribuye las réplicas equitativamente entre nodos.
* **Disponibilidad:** Red `overlay` (`talentoya-net`) + **Ingress Routing Mesh** balancean carga automáticamente entre réplicas saludables. Los `HEALTHCHECK` HTTP sobre `/v3/api-docs` junto con `restart_policy: on-failure` y `update_config` (`order: start-first`, `failure_action: rollback`) evitan cortes durante despliegues o fallos.
* **Mantenibilidad:** Límites explícitos de CPU/RAM (`limits`/`reservations`) alineados con `-XX:MaxRAMPercentage=75.0` en la JVM evitan contención de recursos entre microservicios, mientras que el archivo único `docker-compose.yml` versionado centraliza la topología distribuida.

### 9.7. Eliminar el stack o salir del clúster

```bash
docker stack rm talentoya       # Elimina los servicios del stack
docker swarm leave --force      # Saca el nodo del clúster Swarm
```

## 10. Pipeline CI/CD, API Gateway y Serverless (EP03 - IE4, IE5, IE10, IE11, IE12)

### 10.1. Pipeline CI/CD en GitHub Actions

Definido en [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml), se ejecuta automáticamente ante `push` o `pull_request` sobre `main` y `develop`:

1. **`test-microservices` y `test-serverless`:** Compilan, ejecutan pruebas unitarias + Cucumber BDD y validan cobertura JaCoCo 100% en los 7 microservicios y la función Lambda Java 21.
2. **`build-and-push-images`:** Construyen y publican las 8 imágenes Docker (7 microservicios + `api-gateway`) en **GitHub Container Registry (`ghcr.io`)**.
3. **`provision-cloud-infra` (IE5):** Provisiona automáticamente en AWS la **cola SQS + DLQ**, la **función Lambda** (con trigger SQS) y **Amazon API Gateway** mediante [`scripts/cloud/`](scripts/cloud/) y plantillas IaC ([`serverless/template.yaml`](serverless/template.yaml), [`api-gateway/aws-apigw-template.yaml`](api-gateway/aws-apigw-template.yaml)).
4. **`deploy-swarm-cloud` (IE4 / IE6):** Despliega el stack actualizado en el nodo Manager de Docker Swarm vía SSH y ejecuta una verificación HTTP contra el API Gateway.

#### Secrets requeridos en GitHub (`Settings > Secrets and variables > Actions`)

| Secret | Descripción |
| :--- | :--- |
| `AWS_ACCESS_KEY_ID` | Access Key de AWS (IAM o AWS Academy) |
| `AWS_SECRET_ACCESS_KEY` | Secret Key de AWS |
| `AWS_SESSION_TOKEN` | Session Token (obligatorio en AWS Academy; opcional en IAM) |
| `SWARM_HOST` | IP o dominio público del nodo Manager de Docker Swarm en la nube |
| `SWARM_USER` | Usuario SSH del servidor (ej. `ubuntu` o `ec2-user`) |
| `SWARM_SSH_KEY` | Clave privada SSH para conectar al nodo Manager |
| `GATEWAY_API_KEY` | API Key para proteger rutas `/api/*` (por defecto `talentoya-secret-key-2026`) |

### 10.2. API Gateway y Arquitectura Asíncrona

* **API Gateway ([`api-gateway/`](api-gateway/README.md)):** Punto de entrada único en el puerto `8090` (y opcionalmente expuesto con Amazon API Gateway HTTP API v2). Aplica autenticación por header `X-API-Key`, *rate limiting* (`10 req/s`, `burst=20`), cabeceras de seguridad y bloqueo de `/h2-console`.
* **Cola SQS + Lambda FaaS ([`serverless/procesador-postulaciones/`](serverless/procesador-postulaciones/README.md)):** `talento-ya-ms-postulaciones` publica cada postulación creada (`estado: EN_COLA`) en AWS SQS; la función AWS Lambda Java 21 consume el lote y actualiza la postulación a `PROCESADA` a través del API Gateway.

## 10.3. Uso local y pruebas de humo

### 10.3.1. Ejecutar la arquitectura localmente
- Levanta los micro‑servicios con Docker Swarm:

```bash
./scripts/swarm/03-deploy-stack.sh
```

- El API‑Gateway escucha en el puerto **8090**. 

### 10.3.2. Prueba de extremo a extremo (smoke test)

```bash
curl -X POST -H "X-API-Key: <GATEWAY_API_KEY>" \
     http://localhost:8090/api/postulaciones \
     -H "Content-Type: application/json" \
     -d '{"candidatoId":123,"vacanteId":45}'
```

1. La petición crea una postulación con `estado=EN_COLA`.
2. La cola **AWS SQS** (simulada/local) recibe el mensaje.
3. La **Lambda** (desplegada en la nube) consume el mensaje y actualiza el estado a `PROCESADA` mediante el API‑Gateway.
4. (Opcional) Se envía una notificación al micro‑servicio `notificaciones‑svc`.

### 10.3.3. Desactivar SQS para desarrollo local
Si no deseas depender de AWS durante pruebas locales, define la variable:

```bash
export AWS_SQS_ENABLED=false   # Linux/macOS
set AWS_SQS_ENABLED=false      # Windows PowerShell
```

Con esta configuración el productor de SQS registra un mensaje **“LOCAL‑NOOP”** y la Lambda no se ejecuta.

## 11. Integrantes

* **Estudiante 1:** Tania Gaete
* **Estudiante 2:** Arianette Pavez

* **Estudiante 1:** Tania Gaete
* **Estudiante 2:** Arianette Pavez
