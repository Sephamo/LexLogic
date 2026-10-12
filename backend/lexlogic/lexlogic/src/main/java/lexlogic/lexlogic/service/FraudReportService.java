package lexlogic.lexlogic.service;

import lexlogic.lexlogic.dto.FraudReportRequest;
import lexlogic.lexlogic.dto.FraudReportResponse;
import lexlogic.lexlogic.entity.FraudReport;
import lexlogic.lexlogic.entity.Policy;
import lexlogic.lexlogic.entity.User;
import lexlogic.lexlogic.integration.insurer.InsurerClient;
import lexlogic.lexlogic.integration.insurer.InsurerFraudResponse;
import lexlogic.lexlogic.repository.FraudReportRepository;
import lexlogic.lexlogic.repository.PolicyRepository;
import lexlogic.lexlogic.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class FraudReportService {

    private final FraudReportRepository fraudReportRepository;
    private final UserRepository userRepository;
    private final PolicyRepository policyRepository;
    private final List<InsurerClient> insurerClients;
    private final NotificationService notificationService;
    private final AuditService auditService;

    public FraudReportService(
            FraudReportRepository fraudReportRepository,
            UserRepository userRepository,
            PolicyRepository policyRepository,
            List<InsurerClient> insurerClients,
            NotificationService notificationService,
            AuditService auditService) {

        this.fraudReportRepository = fraudReportRepository;
        this.userRepository = userRepository;
        this.policyRepository = policyRepository;
        this.insurerClients = insurerClients;
        this.notificationService = notificationService;
        this.auditService = auditService;
    }

    public FraudReportResponse createReport(
            Long userId,
            FraudReportRequest request) {

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found"));

        if (!user.getPhoneVerified()) {
            throw new IllegalArgumentException(
                    "Phone number must be verified before reporting fraud"
            );
        }

        Policy policy = policyRepository.findById(request.policyId())
                .orElseThrow(() ->
                        new IllegalArgumentException("Policy not found"));

        FraudReport fraudReport = FraudReport.builder()
                .user(user)
                .policy(policy)
                .reason(request.reason())
                .status("OPEN")
                .createdAt(LocalDateTime.now())
                .build();

        FraudReport savedReport =
                fraudReportRepository.save(fraudReport);

        InsurerClient insurerClient = insurerClients.stream()
                .filter(client ->
                        client.getInsurerName().equals(
                                policy.getInsurer().getName()
                        )
                )
                .findFirst()
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "No insurer integration found for "
                                        + policy.getInsurer().getName()
                        )
                );

        InsurerFraudResponse insurerResponse =
                insurerClient.submitFraudReport(
                        policy.getPolicyNumber(),
                        request.reason()
                );

        savedReport.setStatus(insurerResponse.status());
        savedReport.setInsurerReference(
                insurerResponse.insurerReference()
        );
        savedReport.setInsurerMessage(
                insurerResponse.message()
        );

        savedReport =
                fraudReportRepository.save(savedReport);

        auditService.log(
                userId,
                "FRAUD_REPORT_SUBMITTED",
                "User submitted a fraud report for policy"
        );

        notificationService.createNotification(
                userId,
                "Fraud Report Update",
                "Your fraud report for policy "
                        + policy.getPolicyNumber()
                        + " has been received by the insurer and is now "
                        + insurerResponse.status()
                        + "."
        );

        return toResponse(savedReport);
    }

    public List<FraudReportResponse> getMyReports(Long userId) {

        userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found"));

        return fraudReportRepository.findByUserId(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    private FraudReportResponse toResponse(
            FraudReport report) {

        return new FraudReportResponse(
                report.getId(),
                report.getPolicy().getId(),
                report.getPolicy().getPolicyNumber(),
                report.getReason(),
                report.getStatus(),
                report.getCreatedAt(),
                report.getInsurerReference(),
                report.getInsurerMessage()
        );
    }
}