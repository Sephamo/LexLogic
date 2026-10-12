package lexlogic.lexlogic.service;

import lexlogic.lexlogic.dto.FraudStatusResponse;
import lexlogic.lexlogic.entity.FraudFlag;
import lexlogic.lexlogic.entity.Policy;
import lexlogic.lexlogic.entity.User;
import lexlogic.lexlogic.repository.FraudFlagRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class FraudDetectionService {

    private final FraudFlagRepository fraudFlagRepository;
    private final AuditService auditService;

    public FraudDetectionService(
            FraudFlagRepository fraudFlagRepository,
            AuditService auditService) {

        this.fraudFlagRepository = fraudFlagRepository;
        this.auditService = auditService;
    }

    public void checkPolicy(User user, Policy policy) {

        if (!user.getIdNumber()
                .equals(policy.getPolicyHolderIdNumber())) {

            boolean alreadyFlagged =
                    fraudFlagRepository
                            .existsByUserIdAndPolicyIdAndRuleTypeAndStatus(
                                    user.getId(),
                                    policy.getId(),
                                    "ID_MISMATCH",
                                    "OPEN"
                            );

            if (alreadyFlagged) {
                return;
            }

            FraudFlag fraudFlag = FraudFlag.builder()
                    .user(user)
                    .policy(policy)
                    .ruleType("ID_MISMATCH")
                    .description(
                            "Policy holder ID does not match the authenticated user's ID."
                    )
                    .riskLevel("HIGH")
                    .riskScore(90)
                    .status("OPEN")
                    .createdAt(LocalDateTime.now())
                    .build();

            fraudFlagRepository.save(fraudFlag);

            auditService.log(
                    user.getId(),
                    "FRAUD_FLAG_CREATED",
                    "A high-risk policy ID mismatch was detected."
            );
        }
    }

    public void recordOtpFailure(
            User user,
            int attempts) {

        if (attempts < 3) {
            return;
        }

        boolean alreadyFlagged =
                fraudFlagRepository
                        .existsByUserIdAndRuleTypeAndStatus(
                                user.getId(),
                                "OTP_FAILURE",
                                "OPEN"
                        );

        if (alreadyFlagged) {
            return;
        }

        FraudFlag fraudFlag = FraudFlag.builder()
                .user(user)
                .policy(null)
                .ruleType("OTP_FAILURE")
                .description(
                        "Multiple incorrect OTP attempts were detected."
                )
                .riskLevel("MEDIUM")
                .riskScore(60)
                .status("OPEN")
                .createdAt(LocalDateTime.now())
                .build();

        fraudFlagRepository.save(fraudFlag);

        auditService.log(
                user.getId(),
                "FRAUD_FLAG_CREATED",
                "Multiple incorrect OTP attempts were detected."
        );
    }

    public FraudStatusResponse getUserRiskStatus(Long userId) {

        List<FraudFlag> flags =
                fraudFlagRepository.findByUserId(userId)
                        .stream()
                        .filter(flag -> "OPEN".equals(flag.getStatus()))
                        .toList();

        int totalRiskScore = flags.stream()
                .mapToInt(FraudFlag::getRiskScore)
                .sum();

        totalRiskScore = Math.min(totalRiskScore, 100);

        String riskLevel;

        if (totalRiskScore >= 70) {
            riskLevel = "HIGH";
        } else if (totalRiskScore >= 40) {
            riskLevel = "MEDIUM";
        } else if (totalRiskScore > 0) {
            riskLevel = "LOW";
        } else {
            riskLevel = "CLEAR";
        }

        return new FraudStatusResponse(
                riskLevel,
                totalRiskScore,
                flags.size()
        );
    }
}