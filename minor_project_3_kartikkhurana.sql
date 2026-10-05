-- =====================================================================
-- RedFlag — Fraud Detection Submission
-- Student: Kartik Khurana
-- Batch: DA-DS-1
-- =====================================================================
-- NOTE:
-- This file contains only the 12 fraud-detection queries.
-- Dataset CREATE/INSERT statements and exploratory queries are intentionally
-- excluded from the final submission.
-- =====================================================================

USE redflag;


-- =====================================================================
-- PATTERN 1 · VELOCITY FRAUD
-- What I'm looking for: users with 30+ transactions on a single day.
-- Expected suspects: approximately 45-55 user-days.
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS attack_date,
    COUNT(*) AS daily_txn_count
FROM transactions
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY daily_txn_count DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 2 · ROUND-AMOUNT CLUSTERING
-- What I'm looking for: users with 15+ transactions using the specified
-- round-number amounts.
-- Expected suspects: exactly 25.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS round_txn_count
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_txn_count DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 3 · CARD TESTING
-- What I'm looking for: users with 30+ transactions below ₹10 on the
-- same calendar day.
-- Expected suspects: exactly 20.
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS txn_date,
    COUNT(*) AS tiny_txn_count
FROM transactions
WHERE amount < 10
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY tiny_txn_count DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 4 · FAILED-THEN-SUCCEEDED
-- What I'm looking for: users with 20+ FAILED transactions.
-- This is the simplified version specified in the project brief.
-- Expected suspects: exactly 25.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS failed_txn_count
FROM transactions
WHERE status = 'FAILED'
GROUP BY user_id
HAVING COUNT(*) >= 20
ORDER BY failed_txn_count DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 5 · ODD-HOUR CONCENTRATION
-- What I'm looking for: users with at least 30 total transactions where
-- 80% or more occur between 2 AM and 5 AM (hours 2, 3, and 4).
-- Expected suspects: exactly 20.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_txns,
    SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
    ) AS overnight_txns
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
   AND SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
    ) / COUNT(*) >= 0.80
ORDER BY overnight_txns DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 6 · MULE ACCOUNTS
-- What I'm looking for: users with 8+ CREDIT transactions.
-- This is the simplified version specified in the project brief.
-- Expected suspects: exactly 30.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS credit_txn_count
FROM transactions
WHERE txn_type = 'CREDIT'
GROUP BY user_id
HAVING COUNT(*) >= 8
ORDER BY credit_txn_count DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 7 · REFUND ABUSE
-- What I'm looking for: users with at least 20 transactions where more
-- than 40% of their transactions are REFUND transactions.
-- Expected suspects: approximately 24-25.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_txns,
    SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
    ) AS refund_txns
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
   AND SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
    ) / COUNT(*) > 0.40
ORDER BY refund_txns DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 8 · MERCHANT COLLUSION
-- What I'm looking for: merchants where the top 5 users by transaction
-- volume account for more than 60% of the merchant's total transaction
-- value.
-- Expected suspects: exactly 15 merchants.
-- =====================================================================

WITH merchant_user_volume AS (
    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_volume
    FROM transactions
    GROUP BY
        merchant_id,
        user_id
),

ranked_users AS (
    SELECT
        merchant_id,
        user_id,
        user_volume,
        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_volume DESC
        ) AS user_rank
    FROM merchant_user_volume
),

merchant_totals AS (
    SELECT
        merchant_id,
        SUM(user_volume) AS total_volume
    FROM merchant_user_volume
    GROUP BY merchant_id
)

SELECT
    r.merchant_id,
    m.total_volume,
    SUM(
        CASE
            WHEN r.user_rank <= 5 THEN r.user_volume
            ELSE 0
        END
    ) AS top_5_volume,
    SUM(
        CASE
            WHEN r.user_rank <= 5 THEN r.user_volume
            ELSE 0
        END
    ) / m.total_volume AS top_5_ratio
FROM ranked_users r
JOIN merchant_totals m
    ON r.merchant_id = m.merchant_id
GROUP BY
    r.merchant_id,
    m.total_volume
HAVING
    SUM(
        CASE
            WHEN r.user_rank <= 5 THEN r.user_volume
            ELSE 0
        END
    ) / m.total_volume > 0.60
ORDER BY top_5_ratio DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 9 · JUST-UNDER-THRESHOLD (STRUCTURING)
-- What I'm looking for: users with 10+ transactions of exactly ₹9,999.
-- Expected suspects: exactly 20.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS threshold_txn_count
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY threshold_txn_count DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 10 · DORMANT-THEN-ACTIVE
-- What I'm looking for: users with a gap of at least 90 days between
-- consecutive transactions, followed by at least 15 transactions.
-- Expected suspects: approximately 25-27.
-- =====================================================================

WITH transaction_history AS (
    SELECT
        user_id,
        txn_time,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
),

dormant_gaps AS (
    SELECT
        user_id,
        txn_time AS active_start
    FROM transaction_history
    WHERE previous_txn_time IS NOT NULL
      AND DATEDIFF(txn_time, previous_txn_time) >= 90
),

post_gap_activity AS (
    SELECT
        d.user_id,
        d.active_start,
        COUNT(t.txn_id) AS post_gap_txns
    FROM dormant_gaps d
    JOIN transactions t
        ON t.user_id = d.user_id
       AND t.txn_time >= d.active_start
    GROUP BY
        d.user_id,
        d.active_start
)

SELECT
    user_id,
    MAX(post_gap_txns) AS max_post_gap_txns
FROM post_gap_activity
GROUP BY user_id
HAVING MAX(post_gap_txns) >= 15
ORDER BY max_post_gap_txns DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 11 · VELOCITY SPIKE
-- What I'm looking for: users whose peak monthly transaction count is
-- at least 5x their average monthly transaction count, with a peak of
-- at least 20 transactions.
-- Expected suspects: approximately 35-45.
-- =====================================================================

WITH monthly_txns AS (
    SELECT
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m') AS txn_month,
        COUNT(*) AS monthly_count
    FROM transactions
    GROUP BY
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m')
),

user_stats AS (
    SELECT
        user_id,
        AVG(monthly_count) AS avg_monthly_txns,
        MAX(monthly_count) AS peak_monthly_txns
    FROM monthly_txns
    GROUP BY user_id
)

SELECT
    user_id,
    ROUND(avg_monthly_txns, 2) AS avg_monthly_txns,
    peak_monthly_txns,
    ROUND(
        peak_monthly_txns / avg_monthly_txns,
        2
    ) AS spike_ratio
FROM user_stats
WHERE peak_monthly_txns >= 20
  AND peak_monthly_txns >= 5 * avg_monthly_txns
ORDER BY spike_ratio DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- PATTERN 12 · GEOGRAPHIC IMPOSSIBILITY
-- What I'm looking for: users whose consecutive transactions occur in
-- different cities within 60 minutes.
-- Expected suspects: exactly 15.
-- =====================================================================

WITH transaction_history AS (
    SELECT
        user_id,
        txn_time,
        city,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time,
        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_city
    FROM transactions
)

SELECT
    user_id,
    COUNT(*) AS impossible_trips
FROM transaction_history
WHERE previous_city IS NOT NULL
  AND city <> previous_city
  AND TIMESTAMPDIFF(
        MINUTE,
        previous_txn_time,
        txn_time
      ) BETWEEN 0 AND 60
GROUP BY user_id
ORDER BY impossible_trips DESC;

-- Findings: Record the actual suspect count after running the query.


-- =====================================================================
-- END OF REDFLAG FRAUD DETECTION SUBMISSION
-- =====================================================================
