CREATE TABLE fraud_reports (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    policy_id BIGINT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL,

    CONSTRAINT fk_fraud_reports_user
        FOREIGN KEY (user_id)
        REFERENCES users(id),

    CONSTRAINT fk_fraud_reports_policy
        FOREIGN KEY (policy_id)
        REFERENCES policies(id)
);