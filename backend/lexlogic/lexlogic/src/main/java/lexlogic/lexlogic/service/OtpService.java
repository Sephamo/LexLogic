package lexlogic.lexlogic.service;

import jakarta.servlet.http.HttpSession;
import lexlogic.lexlogic.dto.OtpSessionData;
import lexlogic.lexlogic.entity.OtpPurpose;
import lexlogic.lexlogic.entity.User;
import lexlogic.lexlogic.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class OtpService {

    private final UserRepository userRepository;
    private final SmsService smsService;
    private final AuditService auditService;
    private final FraudDetectionService fraudDetectionService;

    public OtpService(
            UserRepository userRepository,
            SmsService smsService,
            AuditService auditService,
            FraudDetectionService fraudDetectionService
    ){
        this.userRepository = userRepository;
        this.smsService = smsService;
        this.auditService = auditService;
        this.fraudDetectionService = fraudDetectionService;
    }

    public String generateOtp(){

        int otp = (int) (Math.random() * 900000) + 100000;

        return String.valueOf(otp);
    }

    public void createOtp(User user, HttpSession session){

        String otpCode = generateOtp();

        OtpSessionData otpData = new OtpSessionData(
                otpCode,
                user.getId(),
                OtpPurpose.REGISTRATION,
                LocalDateTime.now().plusMinutes(5),
                0
        );

        String message =
                "Your PolicyCheckSA verification code is: " + otpCode;

        smsService.sendSms(
                user.getPhoneNumber(),
                message
        );

        session.setAttribute(
                "registrationOtp",
                otpData
        );

    }

    public void verifyOtp(
            Long userId,
            String otpCode,
            HttpSession session
    ){

        OtpSessionData otpData =
                (OtpSessionData) session.getAttribute("registrationOtp");

        if(otpData == null){
            throw new IllegalArgumentException("OTP not found");
        }

        if(!otpData.getUserId().equals(userId)){
            throw new IllegalArgumentException("Invalid OTP session");
        }

        if(otpData.getAttempts() >= 3){
            throw new IllegalArgumentException(
                    "Too many incorrect OTP attempts"
            );
        }

        if(LocalDateTime.now().isAfter(otpData.getExpiresAt())){
            throw new IllegalArgumentException("OTP has expired");
        }

        if(!otpData.getOtpCode().equals(otpCode)){

            int attempts = otpData.getAttempts() + 1;

            otpData.setAttempts(attempts);

            User user = userRepository.findById(userId)
                    .orElseThrow(() ->
                            new IllegalArgumentException("User not found")
                    );

            fraudDetectionService.recordOtpFailure(
                    user,
                    attempts
            );

            if(attempts >= 3){
                throw new IllegalArgumentException(
                        "Too many incorrect OTP attempts"
                );
            }

            throw new IllegalArgumentException(
                    "Invalid OTP. Attempts remaining: "
                            + (3 - attempts)
            );
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found")
                );

        user.setPhoneVerified(true);

        userRepository.save(user);

        auditService.log(
                user.getId(),
                "OTP_VERIFIED",
                "Registration phone number successfully verified"
        );

        session.removeAttribute("registrationOtp");
    }

    public void resendOtp(
            Long userId,
            HttpSession session
    ){

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found")
                );

        OtpSessionData otpData =
                (OtpSessionData) session.getAttribute("registrationOtp");

        if(otpData == null){
            throw new IllegalArgumentException("OTP not found");
        }

        if(!otpData.getUserId().equals(userId)){
            throw new IllegalArgumentException("Invalid OTP session");
        }

        String newOtp = generateOtp();

        String message =
                "Your PolicyCheckSA verification code is: " + newOtp;

        smsService.sendSms(
                user.getPhoneNumber(),
                message
        );

        otpData.setOtpCode(newOtp);
        otpData.setExpiresAt(
                LocalDateTime.now().plusMinutes(5)
        );
        otpData.setAttempts(0);

        session.setAttribute(
                "registrationOtp",
                otpData
        );
    }

    public void createLoginOtp(
            User user,
            HttpSession session
    ){

        String otpCode = generateOtp();

        OtpSessionData otpData = new OtpSessionData(
                otpCode,
                user.getId(),
                OtpPurpose.LOGIN,
                LocalDateTime.now().plusMinutes(5),
                0
        );

        String message =
                "Your PolicyCheckSA login verification code is: "
                        + otpCode;

        smsService.sendSms(
                user.getPhoneNumber(),
                message
        );

        session.removeAttribute("loginOtpVerifiedUserId");

        session.setAttribute(
                "loginOtp",
                otpData
        );
    }

    public void resendLoginOtp(
            Long userId,
            HttpSession session
    ){

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found")
                );

        OtpSessionData otpData =
                (OtpSessionData) session.getAttribute("loginOtp");

        if(otpData == null){
            throw new IllegalArgumentException("Login OTP not found");
        }

        if(!otpData.getUserId().equals(userId)){
            throw new IllegalArgumentException(
                    "Invalid login OTP session"
            );
        }

        String newOtp = generateOtp();

        String message =
                "Your PolicyCheckSA login verification code is: "
                        + newOtp;

        smsService.sendSms(
                user.getPhoneNumber(),
                message
        );

        otpData.setOtpCode(newOtp);
        otpData.setExpiresAt(
                LocalDateTime.now().plusMinutes(5)
        );
        otpData.setAttempts(0);

        session.removeAttribute("loginOtpVerifiedUserId");

        session.setAttribute(
                "loginOtp",
                otpData
        );
    }

    public void verifyLoginOtp(
            Long userId,
            String otpCode,
            HttpSession session
    ){

        OtpSessionData otpData =
                (OtpSessionData) session.getAttribute("loginOtp");

        if(otpData == null){
            throw new IllegalArgumentException("Login OTP not found");
        }

        if(!otpData.getUserId().equals(userId)){
            throw new IllegalArgumentException(
                    "Invalid login OTP session"
            );
        }

        if(otpData.getAttempts() >= 3){
            throw new IllegalArgumentException(
                    "Too many incorrect OTP attempts"
            );
        }

        if(LocalDateTime.now().isAfter(otpData.getExpiresAt())){
            throw new IllegalArgumentException(
                    "Login OTP has expired"
            );
        }

        if(!otpData.getOtpCode().equals(otpCode)){

            int attempts = otpData.getAttempts() + 1;

            otpData.setAttempts(attempts);

            User user = userRepository.findById(userId)
                    .orElseThrow(() ->
                            new IllegalArgumentException("User not found")
                    );

            fraudDetectionService.recordOtpFailure(
                    user,
                    attempts
            );

            if(attempts >= 3){
                throw new IllegalArgumentException(
                        "Too many incorrect OTP attempts"
                );
            }

            throw new IllegalArgumentException(
                    "Invalid OTP. Attempts remaining: "
                            + (3 - attempts)
            );
        }

        session.removeAttribute("loginOtp");

        session.setAttribute(
                "loginOtpVerifiedUserId",
                userId
        );

        auditService.log(
                userId,
                "LOGIN OTP VERIFIED",
                "Login OTP was successfully verified"
        );
    }

    public boolean isLoginOtpVerified(
            Long userId,
            HttpSession session
    ){

        Long verifiedUserId =
                (Long) session.getAttribute(
                        "loginOtpVerifiedUserId"
                );

        if(verifiedUserId == null){
            return false;
        }

        return verifiedUserId.equals(userId);
    }
}
