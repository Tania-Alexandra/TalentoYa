# Talento Ya - Arquitectura Cloud Native de Microservicios

Proyecto evaluativo correspondiente a la **Evaluación Parcial N°1 (EP01)** de la asignatura *Java: Diseño y Construcción de Soluciones Nativas en Nube* (JVY0101).

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

## 3. Estructura de Microservicios (`/ms`)

El sistema está dividido en 7 microservicios bajo el principio de Responsabilidad Única (SRP):

| Carpeta / Servicio | Responsabilidad de Dominio | Base de Datos / Almacén |
| :--- | :--- | :--- |
| `ms-perfiles` | Identidad, autenticación y CV digital | Amazon Aurora PostgreSQL + Amazon S3 |
| `ms-busqueda` | Catálogo de vacantes y filtrado de alto tráfico | Amazon OpenSearch + Redis Cache |
| `ms-postulaciones` | Registro y ciclo de vida de la postulación | Amazon Aurora PostgreSQL + AWS SQS |
| `ms-notificaciones` | Alertas automáticas y notificaciones push/email | Stateless (Serverless Event-Driven) |
| `ms-mensajeria` | Chat bidireccional en tiempo real | Amazon DynamoDB (WebSockets) |
| `ms-historial` | Contratos cerrados y valoraciones inmutables | Amazon Aurora PostgreSQL |
| `ms-facturacion` | Suscripciones premium y pasarelas de pago | Amazon Aurora PostgreSQL |

---

## 4. Patrones de Diseño Implementados
* **API Gateway:** Punto único de entrada, enrutamiento, rate limiting y validación de seguridad.
* **Service Discovery:** Descubrimiento dinámico de instancias mediante AWS Cloud Map / Eureka.
* **Circuit Breaker:** Tolerancia a fallos y corte de dependencias degradadas.
* **Queue-Based Load Leveling:** Amortiguación de tráfico concurrente con AWS SQS.
* **Database-per-Service:** Desacoplamiento total del modelo de datos.

---

## 5. Integrantes
* **Estudiante 1:** Tania Gaete
* **Estudiante 2:** Arianette Pavez
