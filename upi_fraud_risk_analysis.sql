/* ============================================================
   PROJECT: UPI Transaction Fraud Risk Analysis
   TOOL: MySQL
   TABLE: upi_transactions

   PURPOSE:
   1. Inspect and validate transaction data
   2. Create time-based analysis columns
   3. Calculate fraud KPIs
   4. Analyze fraud patterns
   5. Create rule-based fraud risk scores
   6. Identify high-risk transactions

   NOTE:
   fraud_flag = 1 means synthetic fraud/suspicious transaction
   fraud_flag = 0 means legitimate transaction
   ============================================================ */


-- ============================================================
-- SECTION 1: DATABASE AND TABLE PREVIEW
-- ============================================================

-- View the first records from the imported dataset
SELECT *
FROM upi_transactions
LIMIT 10;

-- View table structure, columns, and data types
DESCRIBE upi_transactions;


-- ============================================================
-- SECTION 2: INITIAL DATA QUALITY CHECKS
-- ============================================================

-- Check total transactions, fraud transactions, and overall fraud rate
SELECT
    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,
    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct
FROM upi_transactions;


-- Check records with missing mandatory values or invalid amounts
-- These records should be reviewed before analysis
SELECT *
FROM upi_transactions
WHERE transaction_id IS NULL
   OR transaction_datetime IS NULL
   OR sender_id IS NULL
   OR transaction_amount IS NULL
   OR transaction_amount <= 0;


-- Check duplicate transaction IDs
-- transaction_id should be unique for each transaction
SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM upi_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- Check missing values in important categorical columns
SELECT
    SUM(merchant_category IS NULL) AS missing_merchant_category,
    SUM(network_type IS NULL) AS missing_network_type,
    SUM(device_type IS NULL) AS missing_device_type
FROM upi_transactions;


-- Check invalid transaction amounts separately
SELECT *
FROM upi_transactions
WHERE transaction_amount IS NULL
   OR transaction_amount <= 0;


-- ============================================================
-- SECTION 3: REMOVE DUPLICATES (OPTIONAL)
-- ============================================================

-- Run this section only if duplicate transaction IDs exist.
-- First, create a backup before deleting any records.

/*
CREATE TABLE upi_transactions_backup AS
SELECT *
FROM upi_transactions;
*/


-- ============================================================
-- SECTION 4: CREATE TIME-BASED ANALYSIS COLUMNS
-- ============================================================

-- Check whether these derived columns already exist before running ALTER TABLE:
-- transaction_date
-- transaction_hour
-- transaction_day
-- is_night_transaction

SHOW COLUMNS FROM upi_transactions
WHERE Field IN (
    'transaction_date',
    'transaction_hour',
    'transaction_day',
    'is_night_transaction'
);


/*
Run this ALTER TABLE statement ONLY if the columns do not exist.

ALTER TABLE upi_transactions
ADD COLUMN transaction_date DATE,
ADD COLUMN transaction_hour INT,
ADD COLUMN transaction_day VARCHAR(15),
ADD COLUMN is_night_transaction TINYINT;
*/


-- If your MySQL version supports it, use this safer version:
ALTER TABLE upi_transactions
ADD COLUMN IF NOT EXISTS transaction_date DATE,
ADD COLUMN IF NOT EXISTS transaction_hour INT,
ADD COLUMN IF NOT EXISTS transaction_day VARCHAR(15),
ADD COLUMN IF NOT EXISTS is_night_transaction TINYINT;


-- ============================================================
-- SECTION 5: POPULATE TIME-BASED COLUMNS
-- ============================================================

-- Disable safe update mode temporarily because all records must be updated
SET SQL_SAFE_UPDATES = 0;


-- Extract date, hour, day name, and night transaction flag
-- Night transaction = transaction occurring from 12 AM to 5 AM
UPDATE upi_transactions
SET
    transaction_date = DATE(transaction_datetime),
    transaction_hour = HOUR(transaction_datetime),
    transaction_day = DAYNAME(transaction_datetime),
    is_night_transaction = CASE
        WHEN HOUR(transaction_datetime) BETWEEN 0 AND 5 THEN 1
        ELSE 0
    END;


-- Turn safe update mode back on after the update
SET SQL_SAFE_UPDATES = 1;


-- Verify that derived time columns were populated correctly
SELECT
    transaction_id,
    transaction_datetime,
    transaction_date,
    transaction_hour,
    transaction_day,
    is_night_transaction
FROM upi_transactions
LIMIT 10;


-- ============================================================
-- SECTION 6: OVERALL FRAUD KPIs
-- ============================================================

-- Main fraud summary for the dashboard
SELECT
    COUNT(*) AS total_transactions,

    ROUND(
        SUM(transaction_amount),
        2
    ) AS total_transaction_value,

    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN fraud_flag = 1 THEN transaction_amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_amount

FROM upi_transactions;


-- ============================================================
-- SECTION 7: FRAUD ANALYSIS BY TRANSACTION TYPE
-- ============================================================

-- Identify which transaction types have the highest fraud rate
SELECT
    transaction_type,
    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN fraud_flag = 1 THEN transaction_amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_amount

FROM upi_transactions
GROUP BY transaction_type
ORDER BY fraud_rate_pct DESC;


-- ============================================================
-- SECTION 8: FRAUD ANALYSIS BY CITY
-- ============================================================

-- Identify cities with high fraud rate and fraud amount
-- HAVING condition avoids misleading rates from very small groups
SELECT
    city,
    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN fraud_flag = 1 THEN transaction_amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_amount

FROM upi_transactions
GROUP BY city
HAVING COUNT(*) >= 20
ORDER BY fraud_rate_pct DESC;


-- ============================================================
-- SECTION 9: FRAUD ANALYSIS BY TRANSACTION HOUR
-- ============================================================

-- Identify hours with the highest fraud rate
SELECT
    transaction_hour,
    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM upi_transactions
GROUP BY transaction_hour
ORDER BY fraud_rate_pct DESC;


-- ============================================================
-- SECTION 10: FRAUD ANALYSIS BY DEVICE TYPE
-- ============================================================

-- Compare fraud rates across Android, iOS, Web, and unknown devices
SELECT
    COALESCE(device_type, 'Unknown') AS device_type,
    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM upi_transactions
GROUP BY COALESCE(device_type, 'Unknown')
ORDER BY fraud_rate_pct DESC;


-- ============================================================
-- SECTION 11: FRAUD ANALYSIS BY PAYMENT METHOD
-- ============================================================

-- Compare fraud rates across QR Code, UPI ID, Mobile Number, etc.
SELECT
    payment_method,
    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM upi_transactions
GROUP BY payment_method
ORDER BY fraud_rate_pct DESC;


-- ============================================================
-- SECTION 12: NEW DEVICE RISK ANALYSIS
-- ============================================================

-- Compare fraud rate for transactions from new and known devices
SELECT
    CASE
        WHEN is_new_device = 1 THEN 'New Device'
        ELSE 'Known Device'
    END AS device_status,

    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM upi_transactions
GROUP BY is_new_device
ORDER BY fraud_rate_pct DESC;


-- ============================================================
-- SECTION 13: NEW BENEFICIARY RISK ANALYSIS
-- ============================================================

-- Compare fraud rate for new and known beneficiaries
SELECT
    CASE
        WHEN is_new_beneficiary = 1 THEN 'New Beneficiary'
        ELSE 'Known Beneficiary'
    END AS beneficiary_status,

    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM upi_transactions
GROUP BY is_new_beneficiary
ORDER BY fraud_rate_pct DESC;


-- ============================================================
-- SECTION 14: TRANSACTION AMOUNT RISK ANALYSIS
-- ============================================================

-- Group transactions by amount to identify high-value risk patterns
SELECT
    CASE
        WHEN transaction_amount >= 10000 THEN 'High Value: Rs. 10,000+'
        WHEN transaction_amount >= 5000 THEN 'Medium Value: Rs. 5,000 to Rs. 9,999'
        ELSE 'Low Value: Below Rs. 5,000'
    END AS amount_category,

    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN fraud_flag = 1 THEN transaction_amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_amount

FROM upi_transactions
GROUP BY amount_category
ORDER BY fraud_rate_pct DESC;


-- ============================================================
-- SECTION 15: FAILED ATTEMPTS RISK ANALYSIS
-- ============================================================

-- Analyze whether repeated failed attempts are linked to higher fraud rate
SELECT
    CASE
        WHEN failed_attempts_24h = 0 THEN 'No Failed Attempts'
        WHEN failed_attempts_24h BETWEEN 1 AND 2 THEN '1 to 2 Failed Attempts'
        ELSE '3 or More Failed Attempts'
    END AS failed_attempt_group,

    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct

FROM upi_transactions
GROUP BY failed_attempt_group
ORDER BY fraud_rate_pct DESC;


-- ============================================================
-- SECTION 16: CREATE RULE-BASED FRAUD RISK SCORE
-- ============================================================

-- Check whether risk_score and risk_category already exist
SHOW COLUMNS FROM upi_transactions
WHERE Field IN ('risk_score', 'risk_category');


-- Create risk columns only if they do not already exist
ALTER TABLE upi_transactions
ADD COLUMN IF NOT EXISTS risk_score INT,
ADD COLUMN IF NOT EXISTS risk_category VARCHAR(20);


-- ============================================================
-- SECTION 17: CALCULATE RISK SCORE
-- ============================================================

/*
Risk scoring rules:

High transaction amount (Rs. 10,000+)        = 30 points
Night transaction (12 AM to 5 AM)             = 15 points
New device                                   = 20 points
New beneficiary                              = 15 points
Three or more failed attempts in 24 hours    = 20 points

Risk category:
0 to 29 points   = Low Risk
30 to 59 points  = Medium Risk
60+ points       = High Risk
*/


-- Disable safe update mode temporarily
SET SQL_SAFE_UPDATES = 0;


-- Calculate transaction-level risk score
UPDATE upi_transactions
SET risk_score =
    CASE
        WHEN transaction_amount >= 10000 THEN 30
        ELSE 0
    END
    +
    CASE
        WHEN is_night_transaction = 1 THEN 15
        ELSE 0
    END
    +
    CASE
        WHEN is_new_device = 1 THEN 20
        ELSE 0
    END
    +
    CASE
        WHEN is_new_beneficiary = 1 THEN 15
        ELSE 0
    END
    +
    CASE
        WHEN failed_attempts_24h >= 3 THEN 20
        ELSE 0
    END;


-- Assign risk category using the calculated risk score
UPDATE upi_transactions
SET risk_category =
    CASE
        WHEN risk_score >= 60 THEN 'High Risk'
        WHEN risk_score >= 30 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END;


-- Re-enable safe update mode
SET SQL_SAFE_UPDATES = 1;


-- ============================================================
-- SECTION 18: RISK CATEGORY SUMMARY
-- ============================================================

-- Compare fraud rate and transaction value across risk categories
SELECT
    risk_category,
    COUNT(*) AS total_transactions,

    ROUND(
        SUM(transaction_amount),
        2
    ) AS transaction_value,

    SUM(fraud_flag) AS fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN fraud_flag = 1 THEN transaction_amount
                ELSE 0
            END
        ),
        2
    ) AS fraud_amount

FROM upi_transactions
GROUP BY risk_category
ORDER BY
    CASE risk_category
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
        ELSE 4
    END;


-- ============================================================
-- SECTION 19: HIGH-RISK TRANSACTION INVESTIGATION
-- ============================================================

-- List all transactions categorized as high risk
-- Use this result for the Power BI investigation table
SELECT
    transaction_id,
    transaction_datetime,
    sender_id,
    receiver_id,
    transaction_amount,
    city,
    state,
    transaction_type,
    merchant_category,
    device_type,
    network_type,
    payment_method,
    failed_attempts_24h,
    is_new_device,
    is_new_beneficiary,
    is_night_transaction,
    risk_score,
    risk_category,
    fraud_flag

FROM upi_transactions
WHERE risk_category = 'High Risk'
ORDER BY
    risk_score DESC,
    transaction_amount DESC;


-- ============================================================
-- SECTION 20: FINAL TABLE CHECK
-- ============================================================

-- Final check: view all important columns before connecting to Power BI
SELECT
    transaction_id,
    transaction_datetime,
    transaction_date,
    transaction_hour,
    transaction_day,
    transaction_amount,
    transaction_type,
    city,
    device_type,
    payment_method,
    failed_attempts_24h,
    is_new_device,
    is_new_beneficiary,
    risk_score,
    risk_category,
    fraud_flag
FROM upi_transactions
LIMIT 20;