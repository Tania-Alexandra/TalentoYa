package cl.duoc.jv0101.caso02.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.events.SQSBatchResponse;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ProcesadorPostulacionesHandlerTest {

    private Context mockContext() {
        Context ctx = mock(Context.class);
        LambdaLogger logger = mock(LambdaLogger.class);
        when(ctx.getLogger()).thenReturn(logger);
        return ctx;
    }

    private SQSEvent eventWithMessage(String messageId, String body) {
        SQSEvent.SQSMessage msg = new SQSEvent.SQSMessage();
        msg.setMessageId(messageId);
        msg.setBody(body);
        SQSEvent event = new SQSEvent();
        event.setRecords(List.of(msg));
        return event;
    }

    @Test
    @SuppressWarnings("unchecked")
    void procesaMensajeValidoYActualizaServicios() throws Exception {
        HttpClient http = mock(HttpClient.class);
        HttpResponse<String> okResponse = mock(HttpResponse.class);
        when(okResponse.statusCode()).thenReturn(200);
        when(http.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class)))
                .thenReturn(okResponse);

        ProcesadorPostulacionesHandler handler = new ProcesadorPostulacionesHandler(
                new ObjectMapper(),
                http,
                "http://api.talentoya.local/api/postulaciones",
                "http://api.talentoya.local/api/notificaciones",
                "talentoya-secret-key-2026");

        String json = "{\"id\":1,\"nombre\":\"Tania Gaete\",\"oferta\":\"Backend Java\",\"estado\":\"EN_COLA\",\"evento\":\"PostulacionCreada\"}";
        SQSBatchResponse response = handler.handleRequest(eventWithMessage("msg-1", json), mockContext());

        assertThat(response.getBatchItemFailures()).isEmpty();
        verify(http, times(2)).send(any(HttpRequest.class), any());
    }

    @Test
    void reportaFalloParcialCuandoMensajeEsInvalido() {
        ProcesadorPostulacionesHandler handler = new ProcesadorPostulacionesHandler(
                new ObjectMapper(),
                mock(HttpClient.class),
                "",
                "",
                "");

        String jsonInvalido = "{\"id\":null,\"nombre\":\"\"}";
        SQSBatchResponse response = handler.handleRequest(
                eventWithMessage("msg-bad", jsonInvalido), mockContext());

        assertThat(response.getBatchItemFailures())
                .extracting(SQSBatchResponse.BatchItemFailure::getItemIdentifier)
                .containsExactly("msg-bad");
    }

    @Test
    void manejaEventoVacioSinErrores() {
        ProcesadorPostulacionesHandler handler = new ProcesadorPostulacionesHandler();
        SQSBatchResponse response = handler.handleRequest(new SQSEvent(), null);
        assertThat(response.getBatchItemFailures()).isEmpty();
    }
}
