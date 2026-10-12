package lexlogic.lexlogic.controller;

import jakarta.servlet.http.HttpSession;
import lexlogic.lexlogic.service.OtpService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/otp")
public class OtpController {

    private final OtpService otpService;

    public OtpController(OtpService otpService){
        this.otpService = otpService;
    }

    @PostMapping("/verify")
    public String verifyOtp(
            @RequestParam Long userId,
            @RequestParam String otpCode,
            HttpSession session
    ){
        otpService.verifyOtp(userId, otpCode, session);

        return "OTP verified successfully";
    }

    @PostMapping("/resend")
    public String resendOtp(
            @RequestParam Long userId,
            HttpSession session
    ){
        otpService.resendOtp(userId, session);

        return "OTP resent Successfully";
    }

    @PostMapping("/login/verify")
    public String verifyLoginOtp(
            @RequestParam Long userId,
            @RequestParam String otpCode,
            HttpSession session
    ){
        otpService.verifyLoginOtp(userId, otpCode, session);

        return "Login OTP verified successfully";
    }

    @PostMapping("/login/resend")
    public String resendLoginOtp(
            @RequestParam long userId,
            HttpSession session
    ){

        otpService.resendLoginOtp(userId, session);

        return "Login OTP resent successfully";
    }
}
