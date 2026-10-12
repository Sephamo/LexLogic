package lexlogic.lexlogic.service;

import lexlogic.lexlogic.dto.NotificationResponse;
import lexlogic.lexlogic.entity.Notification;
import lexlogic.lexlogic.entity.User;
import lexlogic.lexlogic.repository.NotificationRepository;
import lexlogic.lexlogic.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final SmsService smsService;
    private final AuditService auditService;

    public NotificationService(
            NotificationRepository notificationRepository,
            UserRepository userRepository,
            SmsService smsService,
            AuditService auditService) {

        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.smsService = smsService;
        this.auditService = auditService;
    }

    public NotificationResponse createNotification(
            Long userId,
            String title,
            String message) {

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found"));

        Notification notification = Notification.builder()
                .user(user)
                .title(title)
                .message(message)
                .read(false)
                .createdAt(LocalDateTime.now())
                .build();

        Notification savedNotification =
                notificationRepository.save(notification);

        smsService.sendSms(
                user.getPhoneNumber(),
                title + ": " + message
        );

        auditService.log(
                userId,
                "NOTIFICATION_SENT",
                "Notification was sent in-app and by SMS:" + title
        );

        return toResponse(savedNotification);
    }

    public List<NotificationResponse> getMyNotifications(
            Long userId) {

        userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found"));

        return notificationRepository
                .findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    private NotificationResponse toResponse(
            Notification notification) {

        return new NotificationResponse(
                notification.getId(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getRead(),
                notification.getCreatedAt()
        );
    }
}
