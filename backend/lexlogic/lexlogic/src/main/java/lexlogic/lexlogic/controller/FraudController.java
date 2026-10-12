package lexlogic.lexlogic.controller;

import lexlogic.lexlogic.dto.FraudResponse;
import lexlogic.lexlogic.dto.FraudStatusResponse;
import lexlogic.lexlogic.entity.FraudFlag;
import lexlogic.lexlogic.repository.FraudFlagRepository;
import lexlogic.lexlogic.service.FraudDetectionService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/fraud")
public class FraudController {

    private final FraudFlagRepository fraudFlagRepository;
    private final FraudDetectionService fraudDetectionService;

    public FraudController( FraudFlagRepository fraudFlagRepository, FraudDetectionService fraudDetectionService){
        this.fraudFlagRepository = fraudFlagRepository;
        this.fraudDetectionService = fraudDetectionService;
    }

    @GetMapping("/my-flags")
    public List<FraudResponse> getMyFlags(Authentication authentication){
        Long userId = (Long) authentication.getPrincipal();

        return fraudFlagRepository
                .findByUserId(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @GetMapping("my-status")
    public FraudStatusResponse getMyRiskStatus(Authentication authentication){
        Long userId = (Long) authentication.getPrincipal();

        return fraudDetectionService.getUserRiskStatus(userId);
    }

    private FraudResponse toResponse(FraudFlag flag){
        return new FraudResponse(
                flag.getId(),
                flag.getPolicy() != null
                        ? flag.getPolicy().getId()
                        : null,
                flag.getRuleType(),
                flag.getDescription(),
                flag.getRiskLevel(),
                flag.getRiskScore(),
                flag.getStatus(),
                flag.getCreatedAt()
        );
    }
}
