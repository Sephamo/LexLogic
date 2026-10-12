package lexlogic.lexlogic.integration.insurer;

public record InsurerFraudResponse(
        String insurerReference,
        String status,
        String message
) {
}
