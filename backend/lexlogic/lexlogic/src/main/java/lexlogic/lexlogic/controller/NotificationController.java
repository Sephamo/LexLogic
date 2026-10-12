package lexlogic.lexlogic.controller;

import lexlogic.lexlogic.dto.NotificationResponse;
import lexlogic.lexlogic.service.NotificationService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService){
        this.notificationService = notificationService;
    }

    @GetMapping("/my-notifications")
    public List<NotificationResponse> getMyNotifications(Authentication authentication){

        Long userId = (Long) authentication.getPrincipal();
        return notificationService.getMyNotifications(userId);
    }
}
