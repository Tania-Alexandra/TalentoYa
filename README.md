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

El servicio usa el puerto `8080` por defecto. Se puede cambiar con la variable de entorno `PORT`.

## 6. Persistencia y Consola H2 (IE4 e IE5)

Cada microservicio tiene una base H2 en memoria configurada con JPA/Hibernate. Para perfiles, con el servicio en ejecución:

* **Consola:** `http://localhost:8080/h2-console`
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

## 9. Integrantes

* **Estudiante 1:** Tania Gaete
* **Estudiante 2:** Arianette Pavez
