package lexlogic.lexlogic.service;

import lexlogic.lexlogic.dto.AuditLogResponse;
import lexlogic.lexlogic.entity.AuditLog;
import lexlogic.lexlogic.entity.User;
import lexlogic.lexlogic.repository.AuditLogRepository;
import lexlogic.lexlogic.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AuditService {

    private final AuditLogRepository auditLogRepository;
    private final UserRepository userRepository;

    public AuditService(AuditLogRepository auditLogRepository, UserRepository userRepository){
        this.auditLogRepository = auditLogRepository;
        this.userRepository = userRepository;
    }

    public void log(Long userId, String eventType, String description){
        User user = userRepository.findById(userId)
                .orElse(null);

        AuditLog auditLog = AuditLog.builder()
                .user(user)
                .eventType(eventType)
                .description(description)
                .createdAt(LocalDateTime.now())
                .build();

        auditLogRepository.save(auditLog);
    }

    public List<AuditLogResponse> getMyAuditLogs(Long userId){
        userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return auditLogRepository
                .findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    private AuditLogResponse toResponse(AuditLog auditLog){

        return new AuditLogResponse(
                auditLog.getId(),
                auditLog.getEventType(),
                auditLog.getDescription(),
                auditLog.getCreatedAt()
        );
    }
}

