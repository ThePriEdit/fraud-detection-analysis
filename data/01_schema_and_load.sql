-- ============================================================
-- FRAUD DETECTION PROJECT — Schema & Table Setup
-- Author: [Your Name] | Portfolio Project
-- Database: PostgreSQL / MySQL / SQLite compatible
-- ============================================================

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id      VARCHAR(20)     PRIMARY KEY,
    customer_id         VARCHAR(15)     NOT NULL,
    transaction_date    DATE            NOT NULL,
    transaction_time    TIME            NOT NULL,
    amount              DECIMAL(12,2)   NOT NULL,
    merchant_category   VARCHAR(50),
    location            VARCHAR(50),
    payment_method      VARCHAR(30),
    is_fraud            VARCHAR(5),
    fraud_reason        VARCHAR(50)
);

-- Load CSV (adjust path as needed)
-- COPY transactions FROM '/path/to/transactions.csv' DELIMITER ',' CSV HEADER;

-- Verify load
SELECT COUNT(*) AS total_records FROM transactions;
SELECT is_fraud, COUNT(*) AS count FROM transactions GROUP BY is_fraud;
