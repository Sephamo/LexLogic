package lexlogic.lexlogic.controller;

import lexlogic.lexlogic.dto.AuditLogResponse;
import lexlogic.lexlogic.service.AuditService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/audit")
public class AuditController {

    private final AuditService auditService;

    public AuditController(AuditService auditService){
        this.auditService = auditService;
    }

    @GetMapping("/my-logs")
    public List<AuditLogResponse> getMyAuditLogs(Authentication authentication){
        Long userId = (Long) authentication.getPrincipal();
        return auditService.getMyAuditLogs(userId);
    }
}
