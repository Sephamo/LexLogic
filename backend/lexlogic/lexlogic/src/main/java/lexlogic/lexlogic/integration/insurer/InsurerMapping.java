package lexlogic.lexlogic.integration.insurer;

public class InsurerMapping {

    private String insurerName;
    private String baseUrl;

    private String policiesPath;

    private String policyNumberField;
    private String policyTypeField;
    private String statusField;
    private String startDateField;
    private String endDateField;
    private String premiumField;
    private String policyHolderIdField;

    public InsurerMapping(
            String insurerName,
            String baseUrl,
            String policiesPath,
            String policyNumberField,
            String policyTypeField,
            String statusField,
            String startDateField,
            String endDateField,
            String premiumField,
            String policyHolderIdField
    ) {
        this.insurerName = insurerName;
        this.baseUrl = baseUrl;
        this.policiesPath = policiesPath;
        this.policyNumberField = policyNumberField;
        this.policyTypeField = policyTypeField;
        this.statusField = statusField;
        this.startDateField = startDateField;
        this.endDateField = endDateField;
        this.premiumField = premiumField;
        this.policyHolderIdField = policyHolderIdField;
    }

    public String getInsurerName() {
        return insurerName;
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public String getPoliciesPath() {
        return policiesPath;
    }

    public String getPolicyNumberField() {
        return policyNumberField;
    }

    public String getPolicyTypeField() {
        return policyTypeField;
    }

    public String getStatusField() {
        return statusField;
    }

    public String getStartDateField() {
        return startDateField;
    }

    public String getEndDateField() {
        return endDateField;
    }

    public String getPremiumField() {
        return premiumField;
    }

    public String getPolicyHolderIdField() {
        return policyHolderIdField;
    }
}
