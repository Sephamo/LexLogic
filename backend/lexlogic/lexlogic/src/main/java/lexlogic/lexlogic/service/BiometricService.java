package lexlogic.lexlogic.service;

import lexlogic.lexlogic.integration.biometric.BiometricClient;
import lexlogic.lexlogic.integration.biometric.BiometricResponse;
import lexlogic.lexlogic.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class BiometricService {

    private final UserRepository userRepository;
    private final BiometricClient biometricClient;
    private final AuditService auditService;

    public BiometricService(
            UserRepository userRepository,
            BiometricClient biometricClient,
            AuditService auditService) {

        this.userRepository = userRepository;
        this.biometricClient = biometricClient;
        this.auditService = auditService;
    }

    public BiometricResponse verifyIdentity(
            Long userId,
            MultipartFile idImage,
            MultipartFile selfieImage) {

        if (idImage == null || idImage.isEmpty()) {
            throw new IllegalArgumentException(
                    "ID document is required"
            );
        }

        if (selfieImage == null || selfieImage.isEmpty()) {
            throw new IllegalArgumentException(
                    "Selfie image is required"
            );
        }

        var user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "User not found"
                        ));

        if (!user.getPhoneVerified()) {
            throw new IllegalArgumentException(
                    "Phone number must be verified before biometric verification"
            );
        }

        BiometricResponse response =
                biometricClient.verifyIdentity(
                        idImage,
                        selfieImage
                );

        if (Boolean.TRUE.equals(response.verified())) {

            user.setBiometricVerified(true);

            userRepository.save(user);

            auditService.log(
                    userId,
                    "BIOMETRIC_VERIFIED",
                    "User successfully completed biometric identity verification."
            );

        } else {

            auditService.log(
                    userId,
                    "BIOMETRIC_FAILED",
                    "User failed biometric identity verification."
            );
        }

        return response;
    }
}