ALTER TABLE fraud_reports
ADD COLUMN insurer_reference VARCHAR(100);

ALTER TABLE fraud_reports
ADD COLUMN insurer_message VARCHAR(255);