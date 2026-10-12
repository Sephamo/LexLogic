UPDATE fraud_flags
SET risk_score = 90
WHERE rule_type = 'ID_MISMATCH'
  AND risk_score = 0;

UPDATE fraud_flags
SET risk_score = 60
WHERE rule_type = 'OTP_FAILURE'
  AND risk_score = 0;