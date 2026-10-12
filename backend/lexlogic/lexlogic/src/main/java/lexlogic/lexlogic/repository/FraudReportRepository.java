package lexlogic.lexlogic.repository;

import lexlogic.lexlogic.entity.FraudReport;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FraudReportRepository extends JpaRepository<FraudReport, Long> {

    List<FraudReport> findByUserId(Long userId);
    List<FraudReport> findByPolicyId(Long policyId);
}
