package __PACKAGE__;

import java.security.Principal;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("${jeridi.rooms.path:/api/v1/rooms}")
public class RoomController {
    private final RoomService rooms;

    public RoomController(RoomService rooms) { this.rooms = rooms; }

    @GetMapping
    public Page<RoomResponse> list(@RequestParam(defaultValue = "0") int page, Principal user) {
        if (page < 0)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        return rooms.list(user.getName(), PageRequest.of(page, 25, Sort.by("id"))).map(RoomResponse::from);
    }

    @GetMapping("/{id}")
    public RoomResponse get(@PathVariable long id, Principal user) {
        return RoomResponse.from(rooms.get(id, user.getName()));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RoomResponse create(@Valid @RequestBody RoomRequest body, Principal user) {
        return RoomResponse.from(rooms.create(body.name(), user.getName()));
    }

    @PutMapping("/{id}")
    public RoomResponse rename(@PathVariable long id, @Valid @RequestBody RoomRequest body, Principal user) {
        return RoomResponse.from(rooms.rename(id, body.name(), user.getName()));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable long id, Principal user) {
        rooms.delete(id, user.getName());
    }

    public record RoomRequest(@NotBlank @Size(max = 120) String name) {}
    public record RoomResponse(Long id, String name) {
        static RoomResponse from(Room room) { return new RoomResponse(room.getId(), room.getName()); }
    }
}
