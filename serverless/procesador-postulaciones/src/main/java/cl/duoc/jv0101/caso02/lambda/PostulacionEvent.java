package cl.duoc.jv0101.caso02.lambda;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Payload recibido desde la cola AWS SQS generado por talento-ya-ms-postulaciones.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PostulacionEvent(
        Long id,
        String nombre,
        String oferta,
        String estado,
        String evento,
        String timestamp) {
}
