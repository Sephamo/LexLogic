package lexlogic.lexlogic.controller;

import lexlogic.lexlogic.integration.biometric.BiometricResponse;
import lexlogic.lexlogic.service.BiometricService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/biometric")
public class BiometricController {

    private final BiometricService biometricService;

    public BiometricController(
            BiometricService biometricService) {

        this.biometricService = biometricService;
    }

    @PostMapping(
            value = "/verify",
            consumes = "multipart/form-data"
    )
    public BiometricResponse verifyIdentity(
            Authentication authentication,
            @RequestParam("id_image") MultipartFile idImage,
            @RequestParam("selfie_image") MultipartFile selfieImage) {

        Long userId =
                (Long) authentication.getPrincipal();

        return biometricService.verifyIdentity(
                userId,
                idImage,
                selfieImage
        );
    }
}