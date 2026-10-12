package lexlogic.lexlogic.service;

import lexlogic.lexlogic.entity.Insurer;
import lexlogic.lexlogic.entity.Policy;
import lexlogic.lexlogic.integration.insurer.InsurerPolicyAggregator;
import lexlogic.lexlogic.repository.InsurerRepository;
import lexlogic.lexlogic.repository.PolicyRepository;
import lexlogic.lexlogic.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class PolicyService {

    private final PolicyRepository policyRepository;
    private final UserRepository userRepository;
    private final InsurerRepository insurerRepository;
    private final FraudDetectionService fraudDetectionService;
    private final AuditService auditService;
    private final InsurerPolicyAggregator insurerPolicyAggregator;

    public PolicyService(
            PolicyRepository policyRepository,
            UserRepository userRepository,
            InsurerRepository insurerRepository,
            FraudDetectionService fraudDetectionService,
            AuditService auditService,
            InsurerPolicyAggregator insurerPolicyAggregator) {

        this.policyRepository = policyRepository;
        this.userRepository = userRepository;
        this.insurerRepository = insurerRepository;
        this.fraudDetectionService = fraudDetectionService;
        this.auditService = auditService;
        this.insurerPolicyAggregator = insurerPolicyAggregator;
    }

    public List<Policy> getMyPolicies(Long userId) {

        var user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found"));

        if (!user.getPhoneVerified()) {
            throw new IllegalArgumentException(
                    "Phone number must be verified before viewing policies"
            );
        }

        if (!user.getBiometricVerified()) {
            throw new IllegalArgumentException(
                    "Biometric verification is required before viewing policies"
            );
        }

        List<Policy> policies =
                insurerPolicyAggregator.getPoliciesByIdNumber(user.getIdNumber());

        auditService.log(
                user.getId(),
                "POLICY_LOOKUP",
                "User requested policy information from the insurer."
        );

        List<Policy> savedPolicies = new ArrayList<>();

        for (Policy policy : policies) {

            Insurer insurer =
                    insurerRepository
                            .findByName(policy.getInsurer().getName())
                            .orElseGet(() ->
                                    insurerRepository.save(
                                            Insurer.builder()
                                                    .name(policy.getInsurer().getName())
                                                    .apiUrl(policy.getInsurer().getApiUrl())
                                                    .build()
                                    )
                            );

            policy.setInsurer(insurer);

            Policy existingPolicy =
                    policyRepository
                            .findByPolicyNumber(policy.getPolicyNumber())
                            .orElse(null);

            Policy savedPolicy;

            if (existingPolicy == null) {

                savedPolicy =
                        policyRepository.save(policy);

            } else {

                existingPolicy.setPolicyType(
                        policy.getPolicyType()
                );

                existingPolicy.setStatus(
                        policy.getStatus()
                );

                existingPolicy.setStartDate(
                        policy.getStartDate()
                );

                existingPolicy.setEndDate(
                        policy.getEndDate()
                );

                existingPolicy.setPremium(
                        policy.getPremium()
                );

                existingPolicy.setPolicyHolderIdNumber(
                        policy.getPolicyHolderIdNumber()
                );

                existingPolicy.setInsurer(insurer);

                savedPolicy =
                        policyRepository.save(existingPolicy);
            }

            fraudDetectionService.checkPolicy(
                    user,
                    savedPolicy
            );

            savedPolicies.add(savedPolicy);
        }

        return savedPolicies;
    }
}
