package lexlogic.lexlogic.dto;

import java.time.LocalDateTime;

public record NotificationResponse(
        Long id,
        String title,
        String message,
        Boolean read,
        LocalDateTime createdAt
) {
}
