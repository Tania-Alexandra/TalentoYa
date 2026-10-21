package cl.duoc.jv0101.caso02.mensajeria.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import cl.duoc.jv0101.caso02.mensajeria.model.Mensaje;

public interface MensajeRepository extends JpaRepository<Mensaje, Long> {
}
