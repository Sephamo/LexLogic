package lexlogic.lexlogic.dto;

import lexlogic.lexlogic.entity.OtpPurpose;

import java.time.LocalDateTime;

public class OtpSessionData {

    private String otpCode;
    private Long userId;
    private OtpPurpose purpose;
    private LocalDateTime expiresAt;
    private int attempts;

    public OtpSessionData(
            String otpCode,
            Long userId,
            OtpPurpose purpose,
            LocalDateTime expiresAt,
            int attempts
    ) {
        this.otpCode = otpCode;
        this.userId = userId;
        this.purpose = purpose;
        this.expiresAt = expiresAt;
        this.attempts = attempts;
    }

    public String getOtpCode() {
        return otpCode;
    }

    public Long getUserId() {
        return userId;
    }

    public OtpPurpose getPurpose() {
        return purpose;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public int getAttempts() {
        return attempts;
    }

    public void setOtpCode(String otpCode) {
        this.otpCode = otpCode;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public void setAttempts(int attempts) {
        this.attempts = attempts;
    }
}
