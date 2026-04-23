-- ============================================================
-- FRAUD DETECTION PROJECT — Exploratory Data Analysis (EDA)
-- ============================================================

-- ---- 1. Overview Statistics ----
SELECT
    COUNT(*)                                        AS total_transactions,
    ROUND(SUM(amount), 2)                           AS total_volume,
    ROUND(AVG(amount), 2)                           AS avg_transaction_amount,
    ROUND(MIN(amount), 2)                           AS min_amount,
    ROUND(MAX(amount), 2)                           AS max_amount,
    COUNT(DISTINCT customer_id)                     AS unique_customers,
    COUNT(CASE WHEN is_fraud = 'Yes' THEN 1 END)   AS total_fraud,
    ROUND(
        COUNT(CASE WHEN is_fraud = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2
    )                                               AS fraud_rate_pct
FROM transactions;


-- ---- 2. Fraud Distribution by Reason ----
SELECT
    fraud_reason,
    COUNT(*)                                        AS fraud_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_all_fraud,
    ROUND(AVG(amount), 2)                           AS avg_fraud_amount
FROM transactions
WHERE is_fraud = 'Yes'
GROUP BY fraud_reason
ORDER BY fraud_count DESC;


-- ---- 3. Transaction Volume by Merchant Category ----
SELECT
    merchant_category,
    COUNT(*)                                                        AS total_txns,
    COUNT(CASE WHEN is_fraud = 'Yes' THEN 1 END)                   AS fraud_txns,
    ROUND(
        COUNT(CASE WHEN is_fraud = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2
    )                                                               AS fraud_rate_pct,
    ROUND(AVG(amount), 2)                                           AS avg_amount
FROM transactions
GROUP BY merchant_category
ORDER BY fraud_rate_pct DESC;


-- ---- 4. Fraud by Location ----
SELECT
    location,
    COUNT(*)                                                        AS total_txns,
    COUNT(CASE WHEN is_fraud = 'Yes' THEN 1 END)                   AS fraud_count,
    ROUND(
        COUNT(CASE WHEN is_fraud = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2
    )                                                               AS fraud_rate_pct
FROM transactions
GROUP BY location
ORDER BY fraud_rate_pct DESC;


-- ---- 5. Fraud by Payment Method ----
SELECT
    payment_method,
    COUNT(*)                                                        AS total_txns,
    COUNT(CASE WHEN is_fraud = 'Yes' THEN 1 END)                   AS fraud_count,
    ROUND(AVG(amount), 2)                                           AS avg_amount
FROM transactions
GROUP BY payment_method
ORDER BY fraud_count DESC;


-- ---- 6. Monthly Fraud Trend ----
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m')                          AS month,   -- MySQL
    -- TO_CHAR(transaction_date, 'YYYY-MM')                         AS month,   -- PostgreSQL
    COUNT(*)                                                        AS total_txns,
    COUNT(CASE WHEN is_fraud = 'Yes' THEN 1 END)                   AS fraud_count,
    ROUND(SUM(CASE WHEN is_fraud = 'Yes' THEN amount ELSE 0 END), 2) AS fraud_volume
FROM transactions
GROUP BY 1
ORDER BY 1;
