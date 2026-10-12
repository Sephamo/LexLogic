package lexlogic.lexlogic.repository;

import lexlogic.lexlogic.entity.FraudFlag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FraudFlagRepository  extends JpaRepository<FraudFlag, Long> {

    List<FraudFlag> findByUserId(Long userId);
    List<FraudFlag> findByPolicyId(Long policyId);

    boolean existsByUserIdAndPolicyIdAndRuleTypeAndStatus(
            Long userId,
            Long policyId,
            String ruleType,
            String status
    );

    boolean existsByUserIdAndRuleTypeAndStatus(
            Long userId,
            String ruleType,
            String status
    );
}
