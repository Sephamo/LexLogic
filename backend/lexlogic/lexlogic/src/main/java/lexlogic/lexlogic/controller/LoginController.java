package lexlogic.lexlogic.controller;

import jakarta.servlet.http.HttpSession;
import lexlogic.lexlogic.dto.LoginOtpResponse;
import lexlogic.lexlogic.dto.PasswordLoginRequest;
import lexlogic.lexlogic.service.LoginService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class LoginController {

    private final LoginService loginService;

    public LoginController(LoginService loginService){
        this.loginService = loginService;
    }

    @RequestMapping("/login/request")
    public LoginOtpResponse requestLoginOtp(
            @RequestParam String phoneNumber,
            HttpSession session
    ){

        Long userId = loginService.requestLoginOtp(
                phoneNumber,
                session
        );

        return new LoginOtpResponse(
                "Login OTP generated successfully",
                userId
        );
    }

    @PostMapping("/password")
    public String verifyPassword(
            @RequestParam Long userId,
            @RequestBody PasswordLoginRequest request,
            HttpSession session
    ) {

        return loginService.verifyPassword(
                userId,
                request.getPassword(),
                session
        );
    }
}
