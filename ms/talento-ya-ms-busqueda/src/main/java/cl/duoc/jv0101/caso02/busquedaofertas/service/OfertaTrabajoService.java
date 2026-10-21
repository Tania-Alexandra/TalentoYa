package cl.duoc.jv0101.caso02.busquedaofertas.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.jv0101.caso02.busquedaofertas.model.OfertaTrabajo;
import cl.duoc.jv0101.caso02.busquedaofertas.repository.OfertaTrabajoRepository;

@Service
public class OfertaTrabajoService {

    private final OfertaTrabajoRepository repository;

    public OfertaTrabajoService(OfertaTrabajoRepository repository) {
        this.repository = repository;
    }

    public List<OfertaTrabajo> findAll() {
        return repository.findAll();
    }

    public Optional<OfertaTrabajo> findById(Long id) {
        return repository.findById(id);
    }

    public OfertaTrabajo create(OfertaTrabajo recurso) {
        return repository.save(recurso);
    }

    public Optional<OfertaTrabajo> update(Long id, OfertaTrabajo datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setCargo(datos.getCargo());
            existente.setUbicacion(datos.getUbicacion());
            return repository.save(existente);
        });
    }

    public boolean delete(Long id) {
        return repository.findById(id).map(existente -> {
            repository.delete(existente);
            return true;
        }).orElse(false);
    }
}
