package lexlogic.lexlogic.integration.biometric;

import com.fasterxml.jackson.annotation.JsonProperty;

public record BiometricResponse(
        String status,
        Boolean verified,
        String message,
        String reason,

        @JsonProperty("liveness_passed")
        Boolean livenessPassed,

        @JsonProperty("face_match")
        Boolean faceMatch,

        Double distance,

        @JsonProperty("quality_check")
        Boolean qualityCheck
) {
}
