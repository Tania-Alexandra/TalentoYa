package cl.duoc.jv0101.caso02.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSBatchResponse;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Funcion AWS Lambda (FaaS) consumidora de la cola SQS de postulaciones.
 * Implementa ReportBatchItemFailures para reintentar unicamente los mensajes con error
 * y delegarlos a la Dead Letter Queue (DLQ) tras 3 intentos fallidos.
 */
public class ProcesadorPostulacionesHandler implements RequestHandler<SQSEvent, SQSBatchResponse> {

    private static final Duration HTTP_TIMEOUT = Duration.ofSeconds(10);

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final String postulacionesApiUrl;
    private final String notificacionesApiUrl;
    private final String apiGatewayKey;

    public ProcesadorPostulacionesHandler() {
        this(
                new ObjectMapper(),
                HttpClient.newBuilder().connectTimeout(HTTP_TIMEOUT).build(),
                System.getenv("POSTULACIONES_API_URL"),
                System.getenv("NOTIFICACIONES_API_URL"),
                System.getenv("API_GATEWAY_KEY"));
    }

    ProcesadorPostulacionesHandler(
            ObjectMapper objectMapper,
            HttpClient httpClient,
            String postulacionesApiUrl,
            String notificacionesApiUrl,
            String apiGatewayKey) {
        this.objectMapper = objectMapper;
        this.httpClient = httpClient;
        this.postulacionesApiUrl = postulacionesApiUrl;
        this.notificacionesApiUrl = notificacionesApiUrl;
        this.apiGatewayKey = apiGatewayKey;
    }

    @Override
    public SQSBatchResponse handleRequest(SQSEvent event, Context context) {
        LambdaLogger logger = context != null ? context.getLogger() : null;
        List<SQSBatchResponse.BatchItemFailure> failures = new ArrayList<>();

        if (event == null || event.getRecords() == null) {
            return new SQSBatchResponse(failures);
        }

        for (SQSEvent.SQSMessage message : event.getRecords()) {
            try {
                procesarMensaje(message, logger);
            } catch (Exception ex) {
                log(logger, "[LAMBDA][ERROR] Fallo procesando messageId=" + message.getMessageId()
                        + ": " + ex.getMessage());
                failures.add(SQSBatchResponse.BatchItemFailure.builder()
                        .withItemIdentifier(message.getMessageId())
                        .build());
            }
        }

        return new SQSBatchResponse(failures);
    }

    private void procesarMensaje(SQSEvent.SQSMessage message, LambdaLogger logger)
            throws IOException, InterruptedException {
        PostulacionEvent data = objectMapper.readValue(message.getBody(), PostulacionEvent.class);

        if (data.id() == null || data.nombre() == null || data.nombre().isBlank()) {
            throw new IllegalArgumentException("Evento invalido: id y nombre son obligatorios");
        }

        log(logger, "[LAMBDA] Procesando postulacion id=" + data.id()
                + ", candidato=" + data.nombre()
                + ", oferta=" + data.oferta()
                + ", evento=" + data.evento());

        if (postulacionesApiUrl != null && !postulacionesApiUrl.isBlank()) {
            actualizarEstadoPostulacion(data, logger);
        }

        if (notificacionesApiUrl != null && !notificacionesApiUrl.isBlank()) {
            enviarNotificacion(data, logger);
        }
    }

    private void actualizarEstadoPostulacion(PostulacionEvent data, LambdaLogger logger)
            throws IOException, InterruptedException {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("nombre", data.nombre());
        body.put("oferta", data.oferta());
        body.put("estado", "PROCESADA");

        String url = postulacionesApiUrl.replaceAll("/+$", "") + "/" + data.id();
        enviarJson("PUT", url, body);
        log(logger, "[LAMBDA] Estado actualizado a PROCESADA en " + url);
    }

    private void enviarNotificacion(PostulacionEvent data, LambdaLogger logger)
            throws IOException, InterruptedException {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("nombre", data.nombre());
        body.put("canal", "EMAIL_PUSH");
        body.put("asunto", "Postulacion #" + data.id() + " procesada (" + data.oferta() + ")");

        String url = notificacionesApiUrl.replaceAll("/+$", "");
        enviarJson("POST", url, body);
        log(logger, "[LAMBDA] Notificacion registrada en " + url);
    }

    private void enviarJson(String method, String url, Map<String, Object> payload)
            throws IOException, InterruptedException {
        String json = objectMapper.writeValueAsString(payload);
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(HTTP_TIMEOUT)
                .header("Content-Type", "application/json")
                .method(method, HttpRequest.BodyPublishers.ofString(json));

        if (apiGatewayKey != null && !apiGatewayKey.isBlank()) {
            builder.header("X-API-Key", apiGatewayKey);
        }

        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalStateException(
                    "Error HTTP " + response.statusCode() + " invocando " + method + " " + url);
        }
    }

    private void log(LambdaLogger logger, String message) {
        if (logger != null) {
            logger.log(message + "\n");
        }
    }
}
