package lexlogic.lexlogic.controller;

import jakarta.servlet.http.HttpSession;
import lexlogic.lexlogic.dto.RegistrationResponse;
import lexlogic.lexlogic.dto.UserProfileResponse;
import lexlogic.lexlogic.entity.User;
import lexlogic.lexlogic.service.UserService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService){
        this.userService = userService;
    }

    @PostMapping("/register")
    public RegistrationResponse registerUser(
            @RequestBody User user,
            HttpSession session
    ){

        User savedUser = userService.userRegister(user, session);

        return new RegistrationResponse(
                "Account created successfully, Please verify your phone number.",
                savedUser.getId(),
                savedUser.getPhoneVerified()
        );
    }

    @GetMapping("/profile")
    public UserProfileResponse getProfile(Authentication authentication){

        Long userId = (Long) authentication.getPrincipal();

        User user = userService.getUserById(userId);

        return new UserProfileResponse(
                user.getId(),
                user.getFirstName(),
                user.getLastName(),
                user.getIdNumber(),
                user.getPhoneNumber(),
                user.getPhoneVerified()
        );
    }
}
