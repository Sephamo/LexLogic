package lexlogic.lexlogic.dto;

import java.time.LocalDateTime;

public record AuditLogResponse(
        Long id,
        String eventType,
        String description,
        LocalDateTime createdAt
) {
}
