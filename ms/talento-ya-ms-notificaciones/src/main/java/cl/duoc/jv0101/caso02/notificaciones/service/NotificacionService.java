package cl.duoc.jv0101.caso02.notificaciones.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.jv0101.caso02.notificaciones.model.Notificacion;
import cl.duoc.jv0101.caso02.notificaciones.repository.NotificacionRepository;

@Service
public class NotificacionService {

    private final NotificacionRepository repository;

    public NotificacionService(NotificacionRepository repository) {
        this.repository = repository;
    }

    public List<Notificacion> findAll() {
        return repository.findAll();
    }

    public Optional<Notificacion> findById(Long id) {
        return repository.findById(id);
    }

    public Notificacion create(Notificacion recurso) {
        return repository.save(recurso);
    }

    public Optional<Notificacion> update(Long id, Notificacion datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setCanal(datos.getCanal());
            existente.setAsunto(datos.getAsunto());
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
