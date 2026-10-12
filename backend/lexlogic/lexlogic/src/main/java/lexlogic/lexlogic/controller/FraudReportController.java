package lexlogic.lexlogic.controller;

import jakarta.validation.Valid;
import lexlogic.lexlogic.dto.FraudReportRequest;
import lexlogic.lexlogic.dto.FraudReportResponse;
import lexlogic.lexlogic.service.FraudReportService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/fraud-reports")
public class FraudReportController {

    private final FraudReportService fraudReportService;

    public FraudReportController(FraudReportService fraudReportService){
        this.fraudReportService = fraudReportService;
    }

    @PostMapping
    public FraudReportResponse createReport(Authentication authentication, @Valid @RequestBody FraudReportRequest request){
        Long userId = (Long) authentication.getPrincipal();

        return fraudReportService.createReport(userId, request);
    }

    @GetMapping("/my-reports")
    public List<FraudReportResponse> getMyReports(Authentication authentication){

        Long userId = (Long) authentication.getPrincipal();
        return fraudReportService.getMyReports(userId);
    }
}
