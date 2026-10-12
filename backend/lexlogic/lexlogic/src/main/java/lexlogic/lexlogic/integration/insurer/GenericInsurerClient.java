package lexlogic.lexlogic.integration.insurer;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lexlogic.lexlogic.entity.Policy;
import org.springframework.web.client.RestClient;
import org.springframework.http.MediaType;
import java.util.Map;

import java.util.ArrayList;
import java.util.List;

public class GenericInsurerClient implements InsurerClient {

    private final InsurerMapping mapping;
    private final GenericPolicyMapper policyMapper;
    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    public GenericInsurerClient(
            InsurerMapping mapping,
            GenericPolicyMapper policyMapper,
            ObjectMapper objectMapper
    ) {
        this.mapping = mapping;
        this.policyMapper = policyMapper;
        this.objectMapper = objectMapper;

        this.restClient = RestClient.builder()
                .baseUrl(mapping.getBaseUrl())
                .build();
    }

    @Override
    public List<Policy> getPoliciesByIdNumber(String idNumber) {

        String response = restClient.get()
                .uri(mapping.getPoliciesPath())
                .retrieve()
                .body(String.class);

        if (response == null || response.isBlank()) {
            return List.of();
        }

        try {
            JsonNode rootNode = objectMapper.readTree(response);

            List<Policy> policies = new ArrayList<>();

            if (rootNode.isArray()) {

                for (JsonNode policyNode : rootNode) {

                    Policy policy =
                            policyMapper.mapPolicy(
                                    policyNode,
                                    rootNode,
                                    mapping
                            );

                    if (policy.getPolicyHolderIdNumber().equals(idNumber)) {
                        policies.add(policy);
                    }
                }

            } else {

                JsonNode policyArray = findPolicyArray(rootNode);

                if (policyArray != null && policyArray.isArray()) {

                    for (JsonNode policyNode : policyArray) {

                        Policy policy =
                                policyMapper.mapPolicy(
                                        policyNode,
                                        rootNode,
                                        mapping
                                );

                        if (policy.getPolicyHolderIdNumber().equals(idNumber)) {
                            policies.add(policy);
                        }
                    }
                }
            }

            return policies;

        } catch (Exception e) {
            throw new IllegalArgumentException(
                    "Failed to process insurer response"
            );
        }
    }
    @Override
    public String getInsurerName() {
        return mapping.getInsurerName();
    }

    private JsonNode findPolicyArray(JsonNode rootNode) {

        if (rootNode.has("contracts")) {
            return rootNode.get("contracts");
        }

        if (rootNode.has("policies")) {
            return rootNode.get("policies");
        }

        if (rootNode.has("data")
                && rootNode.get("data").isArray()) {
            return rootNode.get("data");
        }

        return null;
    }

    @Override
    public InsurerFraudResponse submitFraudReport(
            String policyNumber,
            String reason
    ) {

        Map<String, String> requestBody = Map.of(
                "policyNumber", policyNumber,
                "reason", reason
        );

        InsurerFraudResponse response = restClient.post()
                .uri("/fraud-reports")
                .contentType(MediaType.APPLICATION_JSON)
                .body(requestBody)
                .retrieve()
                .body(InsurerFraudResponse.class);

        if (response == null) {
            throw new IllegalArgumentException(
                    "Insurer returned an empty fraud report response"
            );
        }

        return response;
    }
}
