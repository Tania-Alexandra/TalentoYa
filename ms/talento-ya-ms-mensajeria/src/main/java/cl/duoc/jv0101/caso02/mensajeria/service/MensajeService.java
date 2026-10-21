package cl.duoc.jv0101.caso02.mensajeria.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.jv0101.caso02.mensajeria.model.Mensaje;
import cl.duoc.jv0101.caso02.mensajeria.repository.MensajeRepository;

@Service
public class MensajeService {

    private final MensajeRepository repository;

    public MensajeService(MensajeRepository repository) {
        this.repository = repository;
    }

    public List<Mensaje> findAll() {
        return repository.findAll();
    }

    public Optional<Mensaje> findById(Long id) {
        return repository.findById(id);
    }

    public Mensaje create(Mensaje recurso) {
        return repository.save(recurso);
    }

    public Optional<Mensaje> update(Long id, Mensaje datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setEmisor(datos.getEmisor());
            existente.setReceptor(datos.getReceptor());
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
