package cl.duoc.jv0101.caso02.busquedaofertas.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import cl.duoc.jv0101.caso02.busquedaofertas.model.OfertaTrabajo;

public interface OfertaTrabajoRepository extends JpaRepository<OfertaTrabajo, Long> {
}
