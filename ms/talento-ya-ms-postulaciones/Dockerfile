# syntax=docker/dockerfile:1

# ==============================================================================
# Stage 1: Build & Layer Extraction (Maven + JDK 21 Alpine)
# ==============================================================================
FROM maven:3.9.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Descarga y cachea dependencias antes de copiar el codigo fuente
COPY pom.xml ./
RUN mvn -B -q dependency:go-offline

# Compila y extrae capas de Spring Boot para optimizar la cache de Docker
COPY src ./src
RUN mvn -B -q package -DskipTests \
    && mv target/*.jar app.jar \
    && java -Djarmode=tools -jar app.jar extract --layers --destination /app/extracted

# ==============================================================================
# Stage 2: Runtime (JRE 21 Alpine, usuario no-root y Healthcheck)
# ==============================================================================
FROM eclipse-temurin:21-jre-alpine AS runtime

LABEL org.opencontainers.image.title="talento-ya-ms-postulaciones" \
      org.opencontainers.image.vendor="TalentoYa - JVY0101"

# Usuario sin privilegios para endurecer la seguridad del contenedor
RUN addgroup -S appgroup && adduser -S -G appgroup appuser
WORKDIR /app

# Copia las capas en orden de menor a mayor frecuencia de cambio
COPY --from=build --chown=appuser:appgroup /app/extracted/dependencies/ ./
COPY --from=build --chown=appuser:appgroup /app/extracted/snapshot-dependencies/ ./
COPY --from=build --chown=appuser:appgroup /app/extracted/application/ ./

# Estandariza puerto interno 8080 y configura limites de memoria para contenedores
ENV PORT=8080 \
    JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/urandom"

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget -qO /dev/null "http://127.0.0.1:${PORT}/v3/api-docs" || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
