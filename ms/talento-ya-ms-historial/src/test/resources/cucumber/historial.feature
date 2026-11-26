# language: es
Característica: Servicio Historial y Reputación (microservicio historial del caso caso02)
  Los escenarios validan el contrato REST del microservicio alineado a sus endpoints.

  Escenario: el listado del recurso responde 200
    Dado el servicio "Historial y Reputación" está disponible
    Cuando consulto el listado de "registroLaborales"
    Entonces el listado responde con código 200

  Escenario: ciclo de vida completo del recurso
    Dado un nuevo "registroLaboral" con nombre "hola-cucumber"
    Cuando consulto el "registroLaboral" recién creado
    Entonces el recurso tiene nombre "hola-cucumber" y código 200
    Cuando actualizo el "registroLaboral" con nombre "cucumber-actualizado"
    Entonces el recurso queda con nombre "cucumber-actualizado" y código 200
    Cuando elimino el "registroLaboral"
    Entonces la eliminación responde con código 204
    Y al consultar el "registroLaboral" eliminado responde 404
