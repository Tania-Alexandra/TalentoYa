package cl.duoc.jv0101.caso02.notificaciones;

import org.junit.jupiter.api.Test;
import cl.duoc.jv0101.caso02.notificaciones.config.OpenApiConfig;

import static org.assertj.core.api.Assertions.assertThat;

class OpenApiConfigTest {

    @Test
    void beanOpenApiGenerado() {
        assertThat(new OpenApiConfig().customOpenAPI()).isNotNull();
    }
}
