package cl.duoc.jv0101.caso02.historial.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import cl.duoc.jv0101.caso02.historial.model.RegistroLaboral;

public interface RegistroLaboralRepository extends JpaRepository<RegistroLaboral, Long> {
}
