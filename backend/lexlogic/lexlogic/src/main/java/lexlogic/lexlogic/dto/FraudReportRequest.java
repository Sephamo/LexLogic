package lexlogic.lexlogic.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record FraudReportRequest(
        @NotNull
        Long policyId,

        @NotBlank
        String reason
){
}
