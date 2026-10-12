package lexlogic.lexlogic.service;

import jakarta.servlet.http.HttpSession;
import lexlogic.lexlogic.entity.User;
import lexlogic.lexlogic.repository.UserRepository;
import lexlogic.lexlogic.utility.PhoneNumberUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final OtpService otpService;
    private final AuditService auditService;

    public UserService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            OtpService otpService,
            AuditService auditService) {

        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.otpService = otpService;
        this.auditService = auditService;
    }

    @Transactional
    public User userRegister(User user, HttpSession session) {

        if (user.getFirstName() == null || user.getFirstName().isBlank()) {
            throw new IllegalArgumentException("First name is required");
        }

        if (!user.getFirstName().matches("^[A-Za-z]+(?:[ '-][A-Za-z]+)*$")) {
            throw new IllegalArgumentException(
                    "First name contains invalid characters"
            );
        }

        if (user.getLastName() == null || user.getLastName().isBlank()) {
            throw new IllegalArgumentException("Last name is required");
        }

        if (!user.getLastName().matches("^[A-Za-z]+(?:[ '-][A-Za-z]+)*$")) {
            throw new IllegalArgumentException(
                    "Last name contains invalid characters"
            );
        }

        String idNumber = user.getIdNumber();

        if (idNumber == null || idNumber.isBlank()) {
            throw new IllegalArgumentException("ID number is required");
        }

        if (!idNumber.matches("\\d{13}")) {
            throw new IllegalArgumentException(
                    "Invalid South African ID number format"
            );
        }

        if (!isValidIdNumber(idNumber)) {
            throw new IllegalArgumentException(
                    "Invalid South African ID number checksum"
            );
        }

        if (userRepository.existsByIdNumber(idNumber)) {
            throw new IllegalArgumentException("ID number already exists");
        }

        String rawPhoneNumber = user.getPhoneNumber();

        if (rawPhoneNumber == null || rawPhoneNumber.isBlank()) {
            throw new IllegalArgumentException("Phone number is required");
        }

        String phoneNumber =
                PhoneNumberUtil.normalizePhoneNumber(rawPhoneNumber);

        if (userRepository.existsByPhoneNumber(phoneNumber)) {
            throw new IllegalArgumentException("Phone number already exists");
        }

        user.setPhoneNumber(phoneNumber);

        String password = user.getPassword();

        if (password == null || password.isBlank()) {
            throw new IllegalArgumentException("Password is required");
        }

        if (password.length() < 8) {
            throw new IllegalArgumentException(
                    "Password must be at least 8 characters"
            );
        }

        if (!password.matches(".*[A-Z].*")) {
            throw new IllegalArgumentException(
                    "Password must contain at least one uppercase letter"
            );
        }

        if (!password.matches(".*[a-z].*")) {
            throw new IllegalArgumentException(
                    "Password must contain at least one lowercase letter"
            );
        }

        if (!password.matches(".*[^a-zA-Z0-9].*")) {
            throw new IllegalArgumentException(
                    "Password must contain at least one special character"
            );
        }

        if (!password.matches(".*\\d.*")) {
            throw new IllegalArgumentException(
                    "Password must contain at least one number"
            );
        }

        String hashPassword = passwordEncoder.encode(password);
        user.setPassword(hashPassword);

        user.setPhoneVerified(false);
        user.setBiometricVerified(false);

        User savedUser = userRepository.save(user);

        auditService.log(
                savedUser.getId(),
                "USER_REGISTERED",
                "User account was successfully created"
        );

        otpService.createOtp(savedUser, session);

        return savedUser;
    }

    public User getUserById(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found")
                );
    }

    private boolean isValidIdNumber(String idNumber) {

        int sum = 0;

        for (int i = 0; i < 12; i += 2) {
            sum += Character.getNumericValue(idNumber.charAt(i));
        }

        String evenDigits = "";

        for (int i = 1; i < 12; i += 2) {
            evenDigits += idNumber.charAt(i);
        }

        int doubled = Integer.parseInt(evenDigits) * 2;

        String doubledString = String.valueOf(doubled);

        for (char digit : doubledString.toCharArray()) {
            sum += Character.getNumericValue(digit);
        }

        int checkDigit = (10 - (sum % 10)) % 10;

        int actualCheckDigit =
                Character.getNumericValue(idNumber.charAt(12));

        return checkDigit == actualCheckDigit;
    }
}