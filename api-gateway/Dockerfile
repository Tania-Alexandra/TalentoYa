# syntax=docker/dockerfile:1
FROM nginxinc/nginx-unprivileged:1.27-alpine

LABEL org.opencontainers.image.title="talento-ya-api-gateway" \
      org.opencontainers.image.vendor="TalentoYa - JVY0101"

COPY default.conf.template /etc/nginx/templates/default.conf.template

ENV GATEWAY_API_KEY="talentoya-secret-key-2026"

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO /dev/null http://127.0.0.1:8080/health || exit 1
