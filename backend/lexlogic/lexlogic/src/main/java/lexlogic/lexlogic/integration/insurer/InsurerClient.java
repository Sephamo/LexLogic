package lexlogic.lexlogic.integration.insurer;

import lexlogic.lexlogic.entity.Policy;

import java.util.List;

public interface InsurerClient {

    String getInsurerName();

    List<Policy> getPoliciesByIdNumber(String idNumber);

    InsurerFraudResponse submitFraudReport(
            String policyNumber,
            String reason
    );
}