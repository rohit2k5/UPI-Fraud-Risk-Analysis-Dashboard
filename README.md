# UPI Fraud Risk Analysis Dashboard

An end-to-end data analytics project that analyzes synthetic UPI-style transaction data to identify fraud patterns, monitor rule-based alerts, segment transaction risk, and support high-risk transaction investigation.

> **Tools Used:** MySQL | Python | Pandas | NumPy | Matplotlib | Seaborn | Power BI | DAX

---

## Project Overview

Digital payment platforms process a large number of UPI transactions every day. Fraud and operations teams need a structured way to monitor transaction activity, identify suspicious behavior, compare actual fraud labels with rule-based alerts, and prioritize high-risk transactions for investigation.

This project uses synthetic UPI-style transaction data to perform data cleaning, exploratory data analysis, rule-based fraud-risk segmentation, SQL analysis, and Power BI dashboard reporting.

The project does **not** use complex machine learning. Instead, it uses transparent business rules so that the risk logic is easy to understand, review, and explain.

---

## Business Objective

The main objective is to help a fraud or operations team answer the following questions:

- What is the overall fraud rate and fraud amount?
- Which cities, transaction types, devices, payment methods, and merchant categories have higher fraud rates?
- At which transaction hours or days does fraud occur more frequently?
- Do new devices, new beneficiaries, and repeated failed attempts show higher fraud risk?
- How many actual fraud transactions were captured by the rule-based alert process?
- How many legitimate transactions were unnecessarily flagged?
- Which transactions and senders should be prioritized for investigation?

---

## Dashboard Preview
<h1>Executive Overview</h1>
<p align="center">
  <img src="https://github.com/rohit2k5/UPI-Fraud-Risk-Analysis-Dashboard/blob/main/Img/Executive_Overview.png?raw=true" alt="Power BI Dashboard" width="900">
</p>
<h1>Fraud Pattern Analysis</h1>
<p align="center">
  <img src="https://github.com/rohit2k5/UPI-Fraud-Risk-Analysis-Dashboard/blob/main/Img/Fraud_Pattern_Analysis.png?raw=true" alt="Power BI Dashboard" width="900">
</p>
<h1>Risk Investigation</h1>
<p align="center">
  <img src="https://github.com/rohit2k5/UPI-Fraud-Risk-Analysis-Dashboard/blob/main/Img/Risk_Investigation.png?raw=true" alt="Power BI Dashboard" width="900">
</p>
---

## Project Workflow

```text
Raw UPI Transaction CSV
        |
        v
Data Cleaning and Validation
(MySQL + Python)
        |
        v
Feature Engineering
(Date, Hour, Day, Night Transaction, Risk Indicators)
        |
        v
Rule-Based Risk Classification
(Low / Medium / High)
        |
        v
Fraud Pattern Analysis
(SQL + Python EDA)
        |
        v
Power BI Dashboard
(Executive Overview, Pattern Analysis, Risk Investigation)
```

---

## Tools and Technologies

| Tool | Purpose |
|---|---|
| MySQL Workbench | Data validation, SQL analysis, KPI queries, transaction investigation |
| Python | Data cleaning, feature engineering, exploratory data analysis |
| Pandas | Data transformation and aggregation |
| NumPy | Numerical operations and conditional logic |
| Matplotlib and Seaborn | EDA charts and visual analysis |
| Power BI Desktop | Interactive dashboard, DAX measures, filters, and KPIs |
| GitHub | Project documentation and portfolio presentation |

---

## Dataset Description

The dataset contains synthetic UPI-style transaction records created for educational and portfolio purposes.

### Important Disclaimer

> This project uses synthetic or publicly available educational transaction data. It does not contain real UPI, bank, customer, Aadhaar, mobile-number, or personally identifiable information.

### Important Columns

| Column | Description |
|---|---|
| `transaction_id` | Unique transaction identifier |
| `transaction_datetime` | Transaction date and time |
| `sender_id` | Masked sender/customer ID |
| `receiver_id` | Masked receiver or merchant ID |
| `transaction_amount` | Transaction value |
| `transaction_type` | P2P, P2M, bill payment, mobile recharge, etc. |
| `merchant_category` | Merchant or transaction category |
| `city` | Transaction city |
| `state` | Transaction state |
| `device_type` | Android, iOS, Web, or Unknown |
| `network_type` | Wi-Fi, 4G, 5G, or Unknown |
| `payment_method` | QR Code, UPI ID, Mobile Number, etc. |
| `failed_attempts_24h` | Failed attempts in the previous 24 hours |
| `is_new_device` | 1 = New device, 0 = Known device |
| `is_new_beneficiary` | 1 = New beneficiary, 0 = Known beneficiary |
| `fraud_flag` | Actual dataset fraud label: 1 = Fraud, 0 = Legitimate |
| `predicted_fraud_flag` | Rule-based transaction alert: 1 = Flagged, 0 = Not Flagged |
| `risk_band` | Rule-based risk category: Low, Medium, or High |
| `risk_score` | Explainable score calculated from defined risk indicators |

---

## Repository Structure

```text
upi-fraud-risk-analysis/
│
├── data/
│   ├── raw/
│   │   └── upi_transactions_raw.csv
│   │
│   └── processed/
│       └── upi_transactions_final.csv
│
├── python/
│   └── upi_fraud_eda.py
│
├── sql/
│   └── upi_fraud_risk_analysis.sql
│
├── powerbi/
│   └── UPI_Fraud_Risk_Analysis.pbix
│
├── images/
│   ├── dashboard_page1.png
│   ├── dashboard_page2.png
│   └── dashboard_page3.png
│
├── README.md
└── requirements.txt
```

---

## Data Cleaning

The following data-quality checks were performed before analysis:

- Checked the dataset shape and column data types.
- Checked missing values across important fields.
- Removed duplicate transaction records using `transaction_id`.
- Converted transaction date/time into datetime format.
- Converted transaction amount into numeric format.
- Removed records with missing or invalid transaction amounts.
- Filled missing categorical values with `Unknown`.
- Created transaction date, hour, day, month, and night-transaction columns.

### Python Cleaning Example

```python
df = df.drop_duplicates(subset="transaction_id")

df["transaction_datetime"] = pd.to_datetime(
    df["transaction_datetime"],
    errors="coerce"
)

df["transaction_amount"] = pd.to_numeric(
    df["transaction_amount"],
    errors="coerce"
)

df = df.dropna(
    subset=[
        "transaction_datetime",
        "transaction_amount"
    ]
)

df = df[df["transaction_amount"] > 0]
```

---

## Rule-Based Risk Analysis

This project uses an explainable, business-rule-based risk score instead of a complex machine-learning model.

### Risk Rules

| Risk Indicator | Condition | Points |
|---|---|---:|
| High transaction amount | Transaction amount is ₹10,000 or above | 30 |
| Night transaction | Transaction occurred between 12 AM and 5 AM | 15 |
| New device | `is_new_device = 1` | 20 |
| New beneficiary | `is_new_beneficiary = 1` | 15 |
| Repeated failed attempts | `failed_attempts_24h >= 3` | 20 |

### Risk Bands

| Risk Score | Risk Band | Interpretation |
|---:|---|---|
| 0–29 | Low | Few suspicious indicators |
| 30–59 | Medium | Requires monitoring or additional verification |
| 60–100 | High | Prioritize for investigation |

### Risk-Score Logic

```python
df["risk_score"] = (
    (df["transaction_amount"] >= 10000).astype(int) * 30
    + (df["is_night_transaction"] == 1).astype(int) * 15
    + (df["is_new_device"] == 1).astype(int) * 20
    + (df["is_new_beneficiary"] == 1).astype(int) * 15
    + (df["failed_attempts_24h"] >= 3).astype(int) * 20
)

df["risk_band"] = pd.cut(
    df["risk_score"],
    bins=[-1, 29, 59, 100],
    labels=["Low", "Medium", "High"]
)

df["predicted_fraud_flag"] = (
    df["risk_score"] >= 60
).astype(int)
```

> A High risk classification does not prove that a transaction is fraudulent. It indicates that the transaction contains multiple suspicious indicators and should be prioritized for investigation.

---

## Actual Fraud vs Rule-Based Alerts

The project compares the actual fraud label with the rule-based transaction alert.

| Comparison Group | Meaning |
|---|---|
| Actual Fraud and Flagged | Fraud-labelled transaction captured by the rules |
| Legitimate but Flagged | Legitimate transaction flagged for review |
| Fraud but Not Flagged | Fraud-labelled transaction missed by the rules |
| Legitimate and Not Flagged | Legitimate transaction not flagged by the rules |

### Flag Comparison Logic

```python
df["flag_comparison"] = np.select(
    [
        (df["fraud_flag"] == 1)
        & (df["predicted_fraud_flag"] == 1),

        (df["fraud_flag"] == 0)
        & (df["predicted_fraud_flag"] == 1),

        (df["fraud_flag"] == 1)
        & (df["predicted_fraud_flag"] == 0)
    ],
    [
        "Actual Fraud and Flagged",
        "Legitimate but Flagged",
        "Fraud but Not Flagged"
    ],
    default="Legitimate and Not Flagged"
)
```

---

## SQL Analysis

The MySQL analysis includes:

- Overall transaction, fraud, and alert KPIs.
- Fraud rate by transaction type.
- Fraud rate and fraud amount by city.
- Fraud rate by transaction hour.
- Fraud rate by device type and payment method.
- New-device versus known-device comparison.
- New-beneficiary versus known-beneficiary comparison.
- Failed-attempt risk analysis.
- Fraud analysis by risk band.
- Actual fraud versus rule-based alert comparison.
- High-risk transaction investigation.
- Top risky senders.

### Example: Overall Fraud KPI Query

```sql
SELECT
    COUNT(*) AS total_transactions,

    ROUND(
        SUM(transaction_amount),
        2
    ) AS total_transaction_value,

    SUM(fraud_flag) AS actual_fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS actual_fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN fraud_flag = 1 THEN transaction_amount
                ELSE 0
            END
        ),
        2
    ) AS actual_fraud_amount,

    SUM(predicted_fraud_flag) AS rule_based_flagged_transactions

FROM upi_transactions;
```

### Example: Fraud Rate by City

```sql
SELECT
    city,
    COUNT(*) AS total_transactions,
    SUM(fraud_flag) AS actual_fraud_transactions,

    ROUND(
        SUM(fraud_flag) * 100.0 / COUNT(*),
        2
    ) AS actual_fraud_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN fraud_flag = 1 THEN transaction_amount
                ELSE 0
            END
        ),
        2
    ) AS actual_fraud_amount

FROM upi_transactions
GROUP BY city
HAVING COUNT(*) >= 20
ORDER BY actual_fraud_rate_pct DESC;
```

---

## Exploratory Data Analysis

Python EDA was used to analyze:

- Legitimate versus fraud-labelled transaction distribution.
- Transaction amount distribution by fraud status.
- Actual fraud rate by transaction hour.
- Actual fraud rate by risk band.
- Actual fraud rate for new versus known devices.
- Actual fraud versus rule-based alert comparison.

### Sample EDA Chart Code

```python
hourly_fraud = (
    df.groupby("transaction_hour")["fraud_flag"]
    .mean()
    .reset_index()
)

hourly_fraud["fraud_rate_pct"] = (
    hourly_fraud["fraud_flag"] * 100
)

sns.barplot(
    data=hourly_fraud,
    x="transaction_hour",
    y="fraud_rate_pct",
    color="#C0392B"
)
```

---

## Power BI Dashboard

The dashboard contains three pages.

### Page 1: Executive Overview

Key KPI cards:

- Total Transactions
- Total Transaction Value
- Actual Fraud Transactions
- Actual Fraud Rate %
- Actual Fraud Amount
- Average Fraud Amount
- Rule-Based Flagged Transactions
- High Risk Transactions

Main visuals:

- Total and actual fraud transactions by date.
- Fraud versus legitimate transaction distribution.
- Fraud rate by transaction type.
- Top 10 cities by fraud amount.
- Fraud rate by transaction hour.
- Interactive slicers for date, city, transaction type, device, payment method, and risk band.

### Page 2: Fraud Pattern Analysis

Main visuals:

- Fraud-rate heatmap by transaction day and hour.
- Fraud rate by device type.
- Fraud rate by merchant category.
- Transaction amount versus actual fraud label.
- City-level fraud performance matrix.
- Decomposition tree for fraud amount.
- Fraud rate by risk band.

### Page 3: Risk Investigation

Main visuals:

- High-risk transaction investigation table.
- Top risky senders.
- New-device versus known-device fraud comparison.
- New-beneficiary versus known-beneficiary fraud comparison.
- Failed-attempt group versus fraud rate.
- Risk-band distribution.
- Actual fraud versus rule-based alert comparison.

---

## Important DAX Measures

### Total Transactions

```DAX
Total Transactions =
COUNTROWS('UPI Transactions')
```

### Actual Fraud Transactions

```DAX
Actual Fraud Transactions =
CALCULATE(
    COUNTROWS('UPI Transactions'),
    'UPI Transactions'[fraud_flag] = 1
)
```

### Actual Fraud Rate

```DAX
Actual Fraud Rate % =
DIVIDE(
    [Actual Fraud Transactions],
    [Total Transactions],
    0
)
```

### Actual Fraud Amount

```DAX
Actual Fraud Amount =
CALCULATE(
    SUM('UPI Transactions'[transaction_amount]),
    'UPI Transactions'[fraud_flag] = 1
)
```

### Rule-Based Flagged Transactions

```DAX
Rule-Based Flagged Transactions =
CALCULATE(
    COUNTROWS('UPI Transactions'),
    'UPI Transactions'[predicted_fraud_flag] = 1
)
```

### High-Risk Transactions

```DAX
High Risk Transactions =
CALCULATE(
    COUNTROWS('UPI Transactions'),
    'UPI Transactions'[risk_band] IN {"High", "High Risk"}
)
```

### Rule Capture Rate

```DAX
Correctly Flagged Fraud =
CALCULATE(
    COUNTROWS('UPI Transactions'),
    'UPI Transactions'[fraud_flag] = 1,
    'UPI Transactions'[predicted_fraud_flag] = 1
)
```

```DAX
Rule Capture Rate % =
DIVIDE(
    [Correctly Flagged Fraud],
    [Actual Fraud Transactions],
    0
)
```

---

## Key Findings

Replace the points below with your actual dashboard results after you complete the project.

- The dataset contains **[total transactions]** transactions and **[actual fraud transactions]** actual fraud-labelled records.
- The actual fraud rate is **[fraud rate]%**.
- The total actual fraud amount is **₹[fraud amount]**.
- **[City / transaction type / payment method]** had the highest actual fraud rate at **[percentage]%**.
- New-device transactions had an actual fraud rate of **[percentage]%**, compared with **[percentage]%** for known devices.
- Transactions with **[failed-attempt group]** had the highest fraud rate at **[percentage]%**.
- The rule-based system flagged **[count]** transactions and captured **[count]** actual fraud-labelled records.
- The High risk band had an actual fraud rate of **[percentage]%**, compared with **[percentage]%** for the Low risk band.

---

## Recommendations

- Apply additional verification to high-value transactions categorized as High risk.
- Prioritize transactions that combine a new device, a new beneficiary, high transaction amount, and repeated failed attempts.
- Send rule-flagged transactions to a manual-review queue rather than automatically blocking every flagged transaction.
- Review risk-rule thresholds if many legitimate transactions are flagged.
- Monitor fraud rate and fraud amount by city, transaction type, payment method, device type, and risk band over time.
- Reassess rule weights periodically using confirmed investigation outcomes.

---

## How to Run the Project

### 1. Clone the repository

```bash
git clone [https://github.com/YOUR-GITHUB-USERNAME/upi-fraud-risk-analysis.git](https://github.com/YOUR-GITHUB-USERNAME/upi-fraud-risk-analysis.git)
```

### 2. Install Python dependencies

```bash
pip install pandas numpy matplotlib seaborn
```

### 3. Add the source dataset

Place the CSV file in:

```text
data/raw/upi_transactions_raw.csv
```

### 4. Run the Python analysis script

Update the file paths inside `python/upi_fraud_eda.py` if necessary, then run:

```bash
python python/upi_fraud_eda.py
```

This creates the processed dataset:

```text
data/processed/upi_transactions_final.csv
```

### 5. Run the SQL analysis

1. Open MySQL Workbench.
2. Import the dataset into a table named `upi_transactions`.
3. Open and run:

```text
sql/upi_fraud_risk_analysis.sql
```

### 6. Open the Power BI dashboard

Open:

```text
powerbi/UPI_Fraud_Risk_Analysis.pbix
```

If required, update the data source path to the processed CSV file.

---

## Limitations

- The dataset is synthetic and may not represent real UPI fraud behavior.
- The `fraud_flag` is a dataset label and may not represent confirmed real-world fraud outcomes.
- Rule-based risk scoring can flag legitimate transactions and may miss some fraud-labelled transactions.
- The project is designed for batch analysis and dashboard monitoring, not real-time transaction blocking.
- A production fraud system would require secure data pipelines, privacy controls, access management, confirmed investigation labels, ongoing monitoring, and governance.

---

## Future Improvements

- Add a proper date table in Power BI for time-intelligence analysis.
- Add drill-through pages for city, sender, and transaction-level investigation.
- Add monthly fraud trend comparisons.
- Create a scheduled refresh process.
- Add analyst feedback for confirmed fraud and legitimate alerts.
- Review and optimize rule thresholds using investigation outcomes.
- Evaluate advanced methods only if reliable historical fraud labels and business approval are available.

---

## Author

**Rohit Mirage**

Aspiring Data Analyst | MySQL | Python | Power BI | SQL

- LinkedIn: "https://www.linkedin.com/in/rohitmirge/"
- portfolio: "https://personal-portfolio-dun-five-47.vercel.app/"

---

## License

This project is created for educational and portfolio purposes.
