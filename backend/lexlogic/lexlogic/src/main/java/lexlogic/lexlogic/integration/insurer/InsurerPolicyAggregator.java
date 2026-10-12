package lexlogic.lexlogic.integration.insurer;


import lexlogic.lexlogic.entity.Policy;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class InsurerPolicyAggregator {

    private final List<InsurerClient> insurerClients;

    public InsurerPolicyAggregator(List<InsurerClient> insurerClients){
        this.insurerClients = insurerClients;
    }

    public List<Policy> getPoliciesByIdNumber(String idNumber){
        List<Policy> allPolicies = new ArrayList<>();

        for (InsurerClient insurerClient : insurerClients){
           List<Policy> policies = insurerClient.getPoliciesByIdNumber(idNumber);

           if (policies != null){
               allPolicies.addAll(policies);
           }

        }
        return allPolicies;
    }
}
