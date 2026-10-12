package lexlogic.lexlogic.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Service
public class SmsService {

    private final String email;
    private final String token;
    private final boolean smsEnabled;
    private final RestClient restClient;

    public SmsService(
            @Value("${smsmessenger.email}") String email,
            @Value("${smsmessenger.token}") String token,
            @Value("${sms.enabled:false}") boolean smsEnabled
    ) {
        this.email = email;
        this.token = token;
        this.smsEnabled = smsEnabled;

        this.restClient = RestClient.builder()
                .baseUrl("https://sms1.smsmessenger.co.za/app/api/rest/v1")
                .build();
    }

    public void sendSms(String toPhoneNumber, String messageBody) {

        if (!smsEnabled) {
            return;
        }

        String recipientNumber = toPhoneNumber.replace("+", "");

        Map<String, String> requestBody = Map.of(
                "recipientNumber", recipientNumber,
                "message", messageBody
        );

        restClient.post()
                .uri("/sms/send.json")
                .header("email", email)
                .header("token", token)
                .header(
                        HttpHeaders.CONTENT_TYPE,
                        MediaType.APPLICATION_JSON_VALUE
                )
                .body(requestBody)
                .retrieve()
                .toBodilessEntity();
    }
}
