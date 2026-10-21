package cl.duoc.jv0101.caso02.historial.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.jv0101.caso02.historial.model.RegistroLaboral;
import cl.duoc.jv0101.caso02.historial.repository.RegistroLaboralRepository;

@Service
public class RegistroLaboralService {

    private final RegistroLaboralRepository repository;

    public RegistroLaboralService(RegistroLaboralRepository repository) {
        this.repository = repository;
    }

    public List<RegistroLaboral> findAll() {
        return repository.findAll();
    }

    public Optional<RegistroLaboral> findById(Long id) {
        return repository.findById(id);
    }

    public RegistroLaboral create(RegistroLaboral recurso) {
        return repository.save(recurso);
    }

    public Optional<RegistroLaboral> update(Long id, RegistroLaboral datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setEmpresa(datos.getEmpresa());
            existente.setPeriodo(datos.getPeriodo());
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
