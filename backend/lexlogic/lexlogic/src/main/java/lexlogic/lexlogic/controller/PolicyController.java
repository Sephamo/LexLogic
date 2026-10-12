package lexlogic.lexlogic.controller;

import lexlogic.lexlogic.entity.Policy;
import lexlogic.lexlogic.service.PolicyService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/policies")
public class PolicyController {

    private final PolicyService policyService;

    public PolicyController(PolicyService policyService){
        this.policyService = policyService;
    }

    @GetMapping("/my-policies")
    public List<Policy> getMyPolicies(Authentication authentication){
        Long userId = (Long) authentication.getPrincipal();

        return policyService.getMyPolicies(userId);
    }
}
