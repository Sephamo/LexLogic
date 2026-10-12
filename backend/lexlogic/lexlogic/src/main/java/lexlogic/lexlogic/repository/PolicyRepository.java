package lexlogic.lexlogic.repository;

import lexlogic.lexlogic.entity.Policy;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PolicyRepository extends JpaRepository<Policy, Long> {

    List<Policy> findByPolicyHolderIdNumber (String policyHolderIdNumber);

    Optional<Policy> findByPolicyNumber (String policyNumber);
}
