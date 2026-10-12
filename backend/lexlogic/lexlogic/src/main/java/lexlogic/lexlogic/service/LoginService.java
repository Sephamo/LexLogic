package lexlogic.lexlogic.service;

import jakarta.servlet.http.HttpSession;
import lexlogic.lexlogic.entity.User;
import lexlogic.lexlogic.repository.UserRepository;
import lexlogic.lexlogic.utility.PhoneNumberUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class LoginService {

    private final UserRepository userRepository;
    private final OtpService otpService;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuditService auditService;

    public LoginService(
            UserRepository userRepository,
            OtpService otpService,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            AuditService auditService
    ){
        this.otpService = otpService;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.auditService = auditService;
    }

    // Normalize and validate phone number
    public Long requestLoginOtp(
            String rawPhoneNumber,
            HttpSession session
    ){

        String phoneNumber =
                PhoneNumberUtil.normalizePhoneNumber(rawPhoneNumber);

        // Find user
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Invalid phone number or account not found"
                        )
                );

        // Check if phone has been verified
        if(!user.getPhoneVerified()){
            throw new IllegalArgumentException(
                    "Please verify your phone number before logging in"
            );
        }

        // Generate login OTP and store it in the session
        otpService.createLoginOtp(user, session);

        auditService.log(
                user.getId(),
                "LOGIN OTP REQUESTED",
                "Login OTP was requested"
        );

        return user.getId();
    }

    public String verifyPassword(
            Long userId,
            String password,
            HttpSession session
    ){

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found")
                );

        if(!otpService.isLoginOtpVerified(userId, session)){
            throw new IllegalArgumentException(
                    "Please verify your login OTP first"
            );
        }

        if(!passwordEncoder.matches(password, user.getPassword())){
            throw new IllegalArgumentException("Incorrect Password");
        }

        auditService.log(
                user.getId(),
                "LOGIN SUCCESS",
                "User successfully authenticated with password"
        );

        session.removeAttribute("loginOtpVerifiedUserId");

        return jwtService.generateToken(user.getId());
    }
}
