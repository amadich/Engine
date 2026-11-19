package __PACKAGE__;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@Transactional
public class RoomService {
    private final RoomRepository rooms;

    public RoomService(RoomRepository rooms) { this.rooms = rooms; }

    @Transactional(readOnly = true)
    public Page<Room> list(String owner, Pageable page) {
        return rooms.findAllByOwner(owner, page);
    }

    @Transactional(readOnly = true)
    public Room get(long id, String owner) {
        return rooms.findByIdAndOwner(id, owner)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }

    public Room create(String name, String owner) {
        return rooms.save(new Room(name.strip(), owner));
    }

    public Room rename(long id, String name, String owner) {
        Room room = get(id, owner);
        room.setName(name.strip());
        return room;
    }

    public void delete(long id, String owner) {
        rooms.delete(get(id, owner));
    }
}
