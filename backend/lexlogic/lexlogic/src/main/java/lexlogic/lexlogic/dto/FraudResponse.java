package lexlogic.lexlogic.dto;

import java.time.LocalDateTime;

public record FraudResponse(
        Long id,
        Long policyId,
        String ruleType,
        String description,
        String riskLevel,
        Integer riskScore,
        String status,
        LocalDateTime createdAt
) {
}
