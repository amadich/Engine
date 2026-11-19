package __PACKAGE__;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomRepository extends JpaRepository<Room, Long> {
    Page<Room> findAllByOwner(String owner, Pageable pageable);
    Optional<Room> findByIdAndOwner(long id, String owner);
}
