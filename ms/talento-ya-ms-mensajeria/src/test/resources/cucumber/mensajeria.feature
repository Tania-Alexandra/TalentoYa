# language: es
Característica: Servicio Mensajería (microservicio mensajeria del caso caso02)
  Los escenarios validan el contrato REST del microservicio alineado a sus endpoints.

  Escenario: el listado del recurso responde 200
    Dado el servicio "Mensajería" está disponible
    Cuando consulto el listado de "mensajes"
    Entonces el listado responde con código 200

  Escenario: ciclo de vida completo del recurso
    Dado un nuevo "mensaje" con nombre "hola-cucumber"
    Cuando consulto el "mensaje" recién creado
    Entonces el recurso tiene nombre "hola-cucumber" y código 200
    Cuando actualizo el "mensaje" con nombre "cucumber-actualizado"
    Entonces el recurso queda con nombre "cucumber-actualizado" y código 200
    Cuando elimino el "mensaje"
    Entonces la eliminación responde con código 204
    Y al consultar el "mensaje" eliminado responde 404
