# language: es
Característica: Servicio Búsqueda de Ofertas (microservicio busqueda-ofertas del caso caso02)
  Los escenarios validan el contrato REST del microservicio alineado a sus endpoints.

  Escenario: el listado del recurso responde 200
    Dado el servicio "Búsqueda de Ofertas" está disponible
    Cuando consulto el listado de "ofertaTrabajos"
    Entonces el listado responde con código 200

  Escenario: ciclo de vida completo del recurso
    Dado un nuevo "ofertaTrabajo" con nombre "hola-cucumber"
    Cuando consulto el "ofertaTrabajo" recién creado
    Entonces el recurso tiene nombre "hola-cucumber" y código 200
    Cuando actualizo el "ofertaTrabajo" con nombre "cucumber-actualizado"
    Entonces el recurso queda con nombre "cucumber-actualizado" y código 200
    Cuando elimino el "ofertaTrabajo"
    Entonces la eliminación responde con código 204
    Y al consultar el "ofertaTrabajo" eliminado responde 404
