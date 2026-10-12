package lexlogic.lexlogic.integration.biometric;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@Component
public class HttpBiometricClient implements BiometricClient {

    private final RestClient restClient;

    public HttpBiometricClient(
            @Value("${biometric.api.url}") String biometricApiUrl) {

        this.restClient = RestClient.builder()
                .baseUrl(biometricApiUrl)
                .build();
    }

    @Override
    public BiometricResponse verifyIdentity(
            MultipartFile idImage,
            MultipartFile selfieImage) {

        try {

            ByteArrayResource idResource =
                    new ByteArrayResource(idImage.getBytes()) {

                        @Override
                        public String getFilename() {
                            return idImage.getOriginalFilename();
                        }
                    };

            ByteArrayResource selfieResource =
                    new ByteArrayResource(selfieImage.getBytes()) {

                        @Override
                        public String getFilename() {
                            return selfieImage.getOriginalFilename();
                        }
                    };

            MultiValueMap<String, Object> body =
                    new LinkedMultiValueMap<>();

            body.add("id_image", idResource);
            body.add("selfie_image", selfieResource);

            return restClient.post()
                    .uri("/verify")
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body)
                    .retrieve()
                    .body(BiometricResponse.class);

        } catch (IOException e) {

            throw new IllegalArgumentException(
                    "Could not read biometric images",
                    e
            );
        }
    }
}
