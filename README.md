# 🔍 Fraud Detection Analysis — SQL & Data Analytics

> **Portfolio Project** | SQL · Data Analysis · Risk Analytics  
> Analysed 10,000+ transaction records to detect suspicious patterns using rule-based SQL logic.

---

## 📌 Project Overview

Financial fraud causes billions in losses annually. This project simulates a real-world fraud detection pipeline using structured transaction data, SQL-based pattern detection, and a composite risk scoring model.

**Key Results:**
- Analysed **10,000+ transaction records** across 1,200 customers
- Detected **4 distinct fraud patterns** covering ~15% of transactions
- Flagged **5–10% high-risk** transactions using multi-rule SQL logic
- Identified **30%+ abnormal amount spikes** as the leading fraud signal
- Built a **composite risk scoring model** (0–100) to prioritise investigations

---

## 🗂️ Repository Structure

```
fraud-detection/
│
├── data/
│   ├── transactions.csv                    # 10,000 synthetic transaction records
│   └── fraud-detection-analysis.xlsx       # Excel dashboard with summary & flagged data
│
├── sql/
│   ├── 01_schema_and_load.sql    # Table schema & data loading
│   ├── 02_exploratory_analysis.sql   # EDA queries (distributions, trends)
│   ├── 03_fraud_detection_queries.sql # Core detection logic (JOINs, CTEs, Windows)
│   └── 04_risk_scoring_model.sql # Rule-based composite scoring system
│
└── README.md
```

---

## 📊 Dataset Description

| Column | Type | Description |
|---|---|---|
| `transaction_id` | VARCHAR | Unique transaction ID (TXN0000001 format) |
| `customer_id` | VARCHAR | Customer identifier (CUST00001 format) |
| `transaction_date` | DATE | Date of transaction (2023) |
| `transaction_time` | TIME | Time of transaction (HH:MM:SS) |
| `amount` | DECIMAL | Transaction amount in ₹ |
| `merchant_category` | VARCHAR | Retail, Travel, Electronics, etc. |
| `location` | VARCHAR | City or International/Unknown |
| `payment_method` | VARCHAR | Credit Card, UPI, Net Banking, etc. |
| `is_fraud` | VARCHAR | Ground truth label (Yes/No) |
| `fraud_reason` | VARCHAR | Fraud pattern type |

**Dataset Stats:**
- 10,000 total transactions
- ₹50 – ₹20,00,000 amount range
- 8 merchant categories, 10 locations, 5 payment methods

---

## 🔎 Fraud Patterns Detected

### 1. 🔴 Amount Spike (Score: +40 pts)
Transaction amount exceeds **3× the customer's historical average**.  
**Detection:** JOIN with per-customer baseline aggregation.

```sql
SELECT t.transaction_id, t.amount, cb.avg_amount,
       ROUND(t.amount / cb.avg_amount, 2) AS amount_ratio
FROM transactions t
JOIN customer_baselines cb ON t.customer_id = cb.customer_id
WHERE t.amount > cb.avg_amount * 3;
```

### 2. 🟠 High Frequency (Score: +15 pts)
Customer makes **more than 5 transactions in a single day**.  
**Detection:** GROUP BY customer + date with HAVING clause.

```sql
SELECT customer_id, transaction_date, COUNT(*) AS txn_count
FROM transactions
GROUP BY customer_id, transaction_date
HAVING COUNT(*) > 5;
```

### 3. 🟠 Location Anomaly (Score: +25 pts)
Transaction originates from **International or Unknown location**.  
**Detection:** Simple WHERE filter joined with customer history.

```sql
SELECT * FROM transactions
WHERE location IN ('International', 'Unknown');
```

### 4. 🟡 Off-Hours Transaction (Score: +20 pts)
Transaction occurs between **midnight and 4 AM**.  
**Detection:** HOUR() function on transaction_time.

```sql
SELECT * FROM transactions
WHERE HOUR(transaction_time) BETWEEN 0 AND 3;
```

---

## 🧮 Risk Scoring Model

A composite rule-based score (0–100) is assigned to every transaction:

| Rule | Condition | Points |
|---|---|---|
| Amount Spike | Amount > 3× customer avg | +40 |
| Location Risk | International / Unknown | +25 |
| Off-Hours | Transaction between 12AM–4AM | +20 |
| High Frequency | >5 transactions in one day | +15 |

**Risk Tiers:**

| Score | Tier | Action |
|---|---|---|
| 60–100 | 🔴 CRITICAL | Block & escalate to fraud team |
| 40–59 | 🟠 HIGH | Flag for manual review |
| 20–39 | 🟡 MEDIUM | Monitor & log |
| 0–19 | 🟢 LOW | Normal processing |

---

## ⚙️ SQL Techniques Used

| Technique | Used For |
|---|---|
| `JOIN` | Connecting transactions to customer baselines |
| `CTE (WITH clause)` | Building multi-step fraud detection pipeline |
| `Window Functions` | Per-customer running aggregations |
| `HAVING` | Post-aggregation filtering for frequency |
| `CASE WHEN` | Rule-based score assignment |
| `STDDEV / AVG` | Statistical baseline per customer |
| `DATE / HOUR functions` | Temporal pattern detection |
| `UNION ALL` | Merging multiple fraud flag tables |
| `VIEW` | Reusable fraud flag and baseline layers |

---

## 🚀 How to Run

### Option A — SQLite (quickest, no install)
```bash
# Install sqlite3 (pre-installed on Mac/Linux)
sqlite3 fraud_detection.db

.mode csv
.import data/transactions.csv transactions
.read sql/01_schema_and_load.sql
.read sql/02_exploratory_analysis.sql
.read sql/03_fraud_detection_queries.sql
.read sql/04_risk_scoring_model.sql
```

### Option B — MySQL
```bash
mysql -u root -p < sql/01_schema_and_load.sql
# Update LOAD DATA path in schema file to match your local path
mysql -u root -p fraud_db < sql/02_exploratory_analysis.sql
```

### Option C — PostgreSQL
```bash
psql -U postgres -d fraud_db -f sql/01_schema_and_load.sql
# Replace HOUR() with EXTRACT(HOUR FROM ...) as noted in comments
psql -U postgres -d fraud_db -f sql/03_fraud_detection_queries.sql
```

### Option D — Online (no setup)
1. Go to [db-fiddle.com](https://www.db-fiddle.com) or [sqliteonline.com](https://sqliteonline.com)
2. Upload `data/transactions.csv`
3. Paste and run the SQL files

---

## 📈 Key Findings

| Insight | Value |
|---|---|
| Overall fraud rate | ~15% of transactions |
| Top fraud pattern | Amount Spike (53% of fraud) |
| Highest risk category | Electronics & Travel |
| Peak fraud hours | 12 AM – 3 AM |
| Riskiest locations | International & Unknown |
| Avg fraudulent amount | ~3.8× higher than normal |

---

## 💡 Recommendations

1. **Real-time amount spike alerts** — Block transactions exceeding 5× customer average pending OTP verification
2. **Geographic velocity checks** — Flag customers transacting in 2+ locations within 2 hours
3. **Off-hours friction** — Add step-up authentication for transactions between 12 AM–4 AM
4. **Frequency throttle** — Soft-block after 8+ transactions/day with SMS confirmation
5. **ML next step** — Train an Isolation Forest or XGBoost classifier on flagged vs normal data

---

## 🛠️ Tech Stack

![SQL](https://img.shields.io/badge/SQL-MySQL%20%7C%20PostgreSQL%20%7C%20SQLite-blue)
![Python](https://img.shields.io/badge/Python-3.10%2B-green)
![Excel](https://img.shields.io/badge/Excel-Dashboard-217346?logo=microsoft-excel)

---

## 👤 Author

Priyanka R More
📧 priyarmore88@gmail.com
🔗 [LinkedIn](https://www.linkedin.com/in/priyanka-more-a476021a6/) | [Portfolio](https://github.com/ThePriEdit)

---

> ⚠️ *This dataset is fully synthetic and generated for portfolio purposes. No real customer data is used.*
