package lexlogic.lexlogic.integration.insurer;

import com.fasterxml.jackson.databind.JsonNode;
import lexlogic.lexlogic.entity.Insurer;
import lexlogic.lexlogic.entity.Policy;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

@Component
public class GenericPolicyMapper {

    public Policy mapPolicy(
            JsonNode policyNode,
            JsonNode rootNode,
            InsurerMapping mapping
    ) {

        Insurer insurer = Insurer.builder()
                .name(mapping.getInsurerName())
                .apiUrl(mapping.getBaseUrl())
                .build();

        String policyHolderId;

        if (policyNode.has(mapping.getPolicyHolderIdField())) {
            policyHolderId =
                    policyNode.get(mapping.getPolicyHolderIdField()).asText();
        } else {
            policyHolderId =
                    rootNode.get(mapping.getPolicyHolderIdField()).asText();
        }

        return Policy.builder()
                .policyNumber(
                        policyNode.get(
                                mapping.getPolicyNumberField()
                        ).asText()
                )
                .policyType(
                        policyNode.get(
                                mapping.getPolicyTypeField()
                        ).asText()
                )
                .status(
                        policyNode.get(
                                mapping.getStatusField()
                        ).asText()
                )
                .startDate(
                        LocalDate.parse(
                                policyNode.get(
                                        mapping.getStartDateField()
                                ).asText()
                        )
                )
                .endDate(
                        LocalDate.parse(
                                policyNode.get(
                                        mapping.getEndDateField()
                                ).asText()
                        )
                )
                .premium(
                        policyNode.get(
                                mapping.getPremiumField()
                        ).asDouble()
                )
                .policyHolderIdNumber(policyHolderId)
                .insurer(insurer)
                .build();
    }
}
