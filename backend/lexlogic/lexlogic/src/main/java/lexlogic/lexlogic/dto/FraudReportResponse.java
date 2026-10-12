package lexlogic.lexlogic.dto;

import java.time.LocalDateTime;

public record FraudReportResponse(
        Long id,
        Long policyId,
        String policyNumber,
        String reason,
        String status,
        LocalDateTime createdAt,
        String insurerReference,
        String insurerMessage
) {
}
