package lexlogic.lexlogic.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class RegistrationResponse {

    private String message;
    private Long userId;
    private boolean phoneVerification;
}
