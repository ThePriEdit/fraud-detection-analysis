-- ============================================================
-- FRAUD DETECTION PROJECT — Rule-Based Scoring System
-- Assigns composite risk scores to every transaction
-- ============================================================

-- ================================================================
-- COMPOSITE RISK SCORE MODEL
-- Each rule contributes points → final score 0–100
--   Amount Spike  (>3x avg)   : +40 pts
--   Location Risk             : +25 pts
--   Off-Hours (12AM-4AM)      : +20 pts
--   High Daily Frequency      : +15 pts
-- ================================================================

WITH customer_stats AS (
    SELECT
        customer_id,
        AVG(amount)                 AS avg_amount,
        STDDEV(amount)              AS std_amount,
        COUNT(*)                    AS total_txns
    FROM transactions
    GROUP BY customer_id
),
daily_freq AS (
    SELECT
        customer_id,
        transaction_date,
        COUNT(*)                    AS daily_count
    FROM transactions
    GROUP BY customer_id, transaction_date
),
scored AS (
    SELECT
        t.transaction_id,
        t.customer_id,
        t.transaction_date,
        t.transaction_time,
        t.amount,
        t.merchant_category,
        t.location,
        t.payment_method,
        cs.avg_amount,
        ROUND(t.amount / NULLIF(cs.avg_amount, 0), 2)      AS amount_ratio,
        df.daily_count,

        -- Rule 1: Amount Spike
        CASE WHEN t.amount > cs.avg_amount * 3 THEN 40 ELSE 0 END AS score_amount_spike,

        -- Rule 2: Geographic Risk
        CASE
            WHEN t.location = 'International' THEN 25
            WHEN t.location = 'Unknown'       THEN 20
            ELSE 0
        END AS score_location,

        -- Rule 3: Off-Hours
        CASE WHEN HOUR(t.transaction_time) BETWEEN 0 AND 3 THEN 20 ELSE 0 END
            AS score_off_hours,

        -- Rule 4: High Frequency
        CASE
            WHEN df.daily_count > 10 THEN 15
            WHEN df.daily_count > 5  THEN 10
            ELSE 0
        END AS score_frequency

    FROM transactions t
    JOIN customer_stats cs  ON t.customer_id = cs.customer_id
    JOIN daily_freq df      ON t.customer_id = df.customer_id
                           AND t.transaction_date = df.transaction_date
)
SELECT
    transaction_id,
    customer_id,
    transaction_date,
    transaction_time,
    ROUND(amount, 2)                                                            AS amount,
    merchant_category,
    location,
    payment_method,
    ROUND(amount_ratio, 2)                                                      AS amount_ratio,
    daily_count,
    score_amount_spike,
    score_location,
    score_off_hours,
    score_frequency,
    (score_amount_spike + score_location + score_off_hours + score_frequency)   AS composite_risk_score,
    CASE
        WHEN (score_amount_spike + score_location + score_off_hours + score_frequency) >= 60 THEN '🔴 CRITICAL'
        WHEN (score_amount_spike + score_location + score_off_hours + score_frequency) >= 40 THEN '🟠 HIGH'
        WHEN (score_amount_spike + score_location + score_off_hours + score_frequency) >= 20 THEN '🟡 MEDIUM'
        ELSE '🟢 LOW'
    END AS risk_category
FROM scored
WHERE (score_amount_spike + score_location + score_off_hours + score_frequency) > 0
ORDER BY composite_risk_score DESC;


-- ================================================================
-- SCORECARD SUMMARY — How many transactions per risk tier
-- ================================================================
WITH risk_summary AS (
    -- (paste the full scored CTE above here in production)
    SELECT
        is_fraud,
        COUNT(*) AS count
    FROM transactions
    GROUP BY is_fraud
)
SELECT * FROM risk_summary;
