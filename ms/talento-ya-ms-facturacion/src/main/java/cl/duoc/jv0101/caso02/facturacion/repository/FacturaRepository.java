package cl.duoc.jv0101.caso02.facturacion.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import cl.duoc.jv0101.caso02.facturacion.model.Factura;

public interface FacturaRepository extends JpaRepository<Factura, Long> {
}
