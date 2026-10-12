package lexlogic.lexlogic.dto;

public record UserProfileResponse(
        Long id,
        String firstName,
        String lastName,
        String idNumber,
        String phoneNumber,
        Boolean phoneVerified
) {

}
