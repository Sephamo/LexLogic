package lexlogic.lexlogic.repository;

import lexlogic.lexlogic.entity.Insurer;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface InsurerRepository extends JpaRepository<Insurer, Long> {

    Optional<Insurer> findByName(String name);
}
