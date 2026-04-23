-- ============================================================
-- FRAUD DETECTION PROJECT — Core Fraud Detection Queries
-- Uses: CTEs, Window Functions, JOINs, Aggregations
-- ============================================================

-- ================================================================
-- QUERY 1: Customer Baseline — Average & Stddev per Customer
-- (Foundation for anomaly detection)
-- ================================================================
CREATE VIEW customer_baselines AS
SELECT
    customer_id,
    COUNT(*)                            AS total_transactions,
    ROUND(AVG(amount), 2)               AS avg_amount,
    ROUND(STDDEV(amount), 2)            AS stddev_amount,
    ROUND(MAX(amount), 2)               AS max_amount,
    COUNT(DISTINCT transaction_date)    AS active_days
FROM transactions
GROUP BY customer_id;


-- ================================================================
-- QUERY 2: Flag AMOUNT SPIKE Anomalies
-- Rule: Transaction > 3x the customer's average amount
-- ================================================================
SELECT
    t.transaction_id,
    t.customer_id,
    t.transaction_date,
    t.amount                                                AS txn_amount,
    cb.avg_amount                                           AS customer_avg,
    ROUND(t.amount / NULLIF(cb.avg_amount, 0), 2)          AS amount_ratio,
    t.merchant_category,
    t.location,
    'Amount Spike'                                          AS flag_reason
FROM transactions t
JOIN customer_baselines cb
    ON t.customer_id = cb.customer_id
WHERE t.amount > (cb.avg_amount * 3)
  AND cb.avg_amount > 0
ORDER BY amount_ratio DESC;


-- ================================================================
-- QUERY 3: Flag HIGH FREQUENCY Transactions
-- Rule: Customer makes > 5 transactions on a single day
-- ================================================================
WITH daily_txn_count AS (
    SELECT
        customer_id,
        transaction_date,
        COUNT(*)    AS txn_count,
        SUM(amount) AS daily_total
    FROM transactions
    GROUP BY customer_id, transaction_date
    HAVING COUNT(*) > 5
)
SELECT
    t.transaction_id,
    t.customer_id,
    t.transaction_date,
    t.amount,
    dtc.txn_count   AS transactions_that_day,
    dtc.daily_total,
    'High Frequency' AS flag_reason
FROM transactions t
JOIN daily_txn_count dtc
    ON t.customer_id = dtc.customer_id
   AND t.transaction_date = dtc.transaction_date
ORDER BY dtc.txn_count DESC, t.customer_id;


-- ================================================================
-- QUERY 4: Flag LOCATION ANOMALIES
-- Rule: International/Unknown location transactions
-- ================================================================
SELECT
    t.transaction_id,
    t.customer_id,
    t.transaction_date,
    t.transaction_time,
    t.amount,
    t.location,
    t.payment_method,
    cb.total_transactions   AS customer_txn_history,
    'Location Anomaly'      AS flag_reason
FROM transactions t
JOIN customer_baselines cb ON t.customer_id = cb.customer_id
WHERE t.location IN ('International', 'Unknown')
ORDER BY t.amount DESC;


-- ================================================================
-- QUERY 5: Flag OFF-HOURS Transactions (12AM–4AM)
-- ================================================================
SELECT
    transaction_id,
    customer_id,
    transaction_date,
    transaction_time,
    amount,
    merchant_category,
    location,
    'Off-Hours Transaction' AS flag_reason
FROM transactions
WHERE HOUR(transaction_time) BETWEEN 0 AND 3   -- MySQL
-- WHERE EXTRACT(HOUR FROM transaction_time) BETWEEN 0 AND 3  -- PostgreSQL
ORDER BY amount DESC;


-- ================================================================
-- QUERY 6: MASTER HIGH-RISK FLAG — All Rules Combined
-- Final table used for reporting
-- ================================================================
CREATE VIEW flagged_high_risk_transactions AS

WITH amount_spikes AS (
    SELECT t.transaction_id, 'Amount Spike' AS risk_type, 90 AS risk_score
    FROM transactions t
    JOIN customer_baselines cb ON t.customer_id = cb.customer_id
    WHERE t.amount > cb.avg_amount * 3 AND cb.avg_amount > 0
),
high_freq AS (
    SELECT t.transaction_id, 'High Frequency' AS risk_type, 75 AS risk_score
    FROM transactions t
    JOIN (
        SELECT customer_id, transaction_date
        FROM transactions
        GROUP BY customer_id, transaction_date
        HAVING COUNT(*) > 5
    ) hf ON t.customer_id = hf.customer_id AND t.transaction_date = hf.transaction_date
),
geo_anomaly AS (
    SELECT transaction_id, 'Location Anomaly' AS risk_type, 85 AS risk_score
    FROM transactions
    WHERE location IN ('International', 'Unknown')
),
off_hours AS (
    SELECT transaction_id, 'Off-Hours Transaction' AS risk_type, 70 AS risk_score
    FROM transactions
    WHERE HOUR(transaction_time) BETWEEN 0 AND 3  -- MySQL
)

SELECT DISTINCT
    t.transaction_id,
    t.customer_id,
    t.transaction_date,
    t.amount,
    t.merchant_category,
    t.location,
    t.payment_method,
    r.risk_type,
    r.risk_score,
    CASE
        WHEN r.risk_score >= 85 THEN 'CRITICAL'
        WHEN r.risk_score >= 75 THEN 'HIGH'
        ELSE 'MEDIUM'
    END AS risk_level
FROM transactions t
JOIN (
    SELECT * FROM amount_spikes
    UNION ALL SELECT * FROM high_freq
    UNION ALL SELECT * FROM geo_anomaly
    UNION ALL SELECT * FROM off_hours
) r ON t.transaction_id = r.transaction_id
ORDER BY r.risk_score DESC, t.amount DESC;


-- ================================================================
-- QUERY 7: SUMMARY — Risk Level Distribution
-- ================================================================
SELECT
    risk_level,
    risk_type,
    COUNT(*)                AS flagged_transactions,
    ROUND(AVG(amount), 2)   AS avg_flagged_amount,
    ROUND(SUM(amount), 2)   AS total_at_risk_volume
FROM flagged_high_risk_transactions
GROUP BY risk_level, risk_type
ORDER BY
    FIELD(risk_level, 'CRITICAL', 'HIGH', 'MEDIUM'),  -- MySQL ordering
    flagged_transactions DESC;
