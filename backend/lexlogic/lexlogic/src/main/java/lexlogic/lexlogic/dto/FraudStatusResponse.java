package lexlogic.lexlogic.dto;

public record FraudStatusResponse(
        String riskLevel,
        Integer riskScore,
        Integer openFlags
) {
}
