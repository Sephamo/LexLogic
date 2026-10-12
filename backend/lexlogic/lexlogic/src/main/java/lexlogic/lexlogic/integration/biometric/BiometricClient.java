package lexlogic.lexlogic.integration.biometric;

import org.springframework.web.multipart.MultipartFile;

public interface BiometricClient {

    BiometricResponse verifyIdentity(MultipartFile idImage, MultipartFile selfieImage);

}
