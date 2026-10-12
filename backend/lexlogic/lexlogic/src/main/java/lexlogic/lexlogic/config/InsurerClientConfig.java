package lexlogic.lexlogic.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import lexlogic.lexlogic.integration.insurer.GenericInsurerClient;
import lexlogic.lexlogic.integration.insurer.GenericPolicyMapper;
import lexlogic.lexlogic.integration.insurer.InsurerClient;
import lexlogic.lexlogic.integration.insurer.InsurerMapping;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class InsurerClientConfig {

    @Bean
    public InsurerClient demoInsuranceClient(
            GenericPolicyMapper policyMapper,
            ObjectMapper objectMapper
    ) {

        InsurerMapping mapping = new InsurerMapping(
                "Demo Insurance",
                "http://localhost:9001",
                "/api/policies",
                "policyNumber",
                "policyType",
                "status",
                "startDate",
                "endDate",
                "premium",
                "policyHolderIdNumber"
        );

        return new GenericInsurerClient(
                mapping,
                policyMapper,
                objectMapper
        );
    }

    @Bean
    public InsurerClient secureLifeClient(
            GenericPolicyMapper policyMapper,
            ObjectMapper objectMapper
    ) {

        InsurerMapping mapping = new InsurerMapping(
                "SecureLife",
                "http://localhost:9002",
                "/securelife/contracts",
                "contractId",
                "coverType",
                "contractStatus",
                "effectiveFrom",
                "effectiveTo",
                "monthlyCost",
                "customerId"
        );

        return new GenericInsurerClient(
                mapping,
                policyMapper,
                objectMapper
        );
    }

    @Bean
    public InsurerClient shieldInsuranceClient(
            GenericPolicyMapper policyMapper,
            ObjectMapper objectMapper
    ) {

        InsurerMapping mapping = new InsurerMapping(
                "Shield Insurance",
                "http://localhost:9003",
                "/shield/policies",
                "reference",
                "product",
                "state",
                "validFrom",
                "validUntil",
                "amount",
                "nationalId"
        );

        return new GenericInsurerClient(
                mapping,
                policyMapper,
                objectMapper
        );
    }
}
