# Credit Card Fraud Detection — Advanced SQL Project

**Author:** Duncan Chicho (NC-Dan)  
**Tool:** Microsoft SQL Server (T-SQL)  
**Dataset:** Credit Card Fraud Detection — ULB Machine Learning Group (Kaggle)  
**Scale:** 283,726 clean transactions | 473 confirmed fraud cases  
**Complexity:** Advanced — Views, Stored Procedures, Indexes, Anomaly Detection

---

## Business Problem

Credit card fraud costs the global financial industry billions annually.
This project analyses 283,726 real European credit card transactions to:

1. **Detect** — identify fraud patterns by amount, time and behaviour
2. **Profile** — build a statistical profile of fraudulent transactions
3. **Monitor** — create reusable Views and Stored Procedures for ongoing fraud surveillance

---

## Dataset Context

- **Source:** Real anonymised transactions from European cardholders (2 days)
- **Features:** V1-V28 are PCA-transformed to protect cardholder privacy
- **Challenge:** Only 0.1667% of transactions are fraudulent — finding 473 cases
  among 283,253 legitimate transactions is the core analytical challenge
- **Industry relevance:** This imbalance mirrors real production fraud data

---

## Database Architecture
---

## Data Quality Audit & Cleaning

| Issue | Detail | Action Taken |
|---|---|---|
| NULLs in V2-V27 | 21 per column — import precision loss | Retained — imputation would corrupt anonymised PCA features |
| NULLs in V28 | 237 values | Retained — same reason |
| Duplicate rows | 1,081 identified | Deleted — ROW_NUMBER() partition method |
| Fraud count corrected | 492 → 473 after deduplication | 19 duplicate fraud rows removed |
| Fraud rate corrected | 0.173% → 0.1667% | Recalculated post-cleaning |

**Cleaning method:** `ROW_NUMBER() OVER (PARTITION BY Time, Amount, Class, V1, V2, V3 ORDER BY TransactionID)` — kept lowest TransactionID per duplicate group.

---

## Key Findings

### Finding 1 — The Needle in the Haystack
- 473 fraud cases hidden among 283,253 legitimate transactions
- Fraud rate: **0.1667%** — 1 in every 600 transactions
- A model predicting everything as legitimate would be 99.83% accurate — and completely useless
- This is why statistical anomaly detection is essential

### Finding 2 — Fraudsters Spend More, But Not Too Much
- Fraud avg amount: **$122.21** vs Legitimate avg: **$88.29** — 38% higher
- Fraud MaxAmount: **$2,125.87** vs Legitimate MaxAmount: **$25,691.16**
- Fraudsters deliberately avoid extremely large transactions — they stay below detection thresholds
- This behaviour is known as **structuring** in financial crime analysis

### Finding 3 — The Test Transaction Pattern
- **73.6% of all fraud** (362 cases) involves amounts under $100
- Micro transactions (<$10): second highest fraud rate at 0.2559%
- Small transactions ($10-$100): lowest fraud rate at 0.0869%
- Pattern: criminals use tiny amounts to test stolen cards before escalating

### Finding 4 — Large Transactions Are Highest Risk
- Large transactions (>$1,000): **0.2933% fraud rate** — highest of all bands
- Only 3,069 large transactions exist — but 9 are fraudulent
- Combined with micro test transactions — fraud follows a clear two-stage pattern

### Finding 5 — Fraud Peaks at 2am
- Hour 2am: **1.7174% fraud rate** — nearly 10x the dataset average
- Hour 4am: 1.0436% — second highest
- Top 3 fraud hours are all between midnight and 5am
- Fraudsters operate when human monitoring is at its lowest

### Finding 6 — Midnight Fraud Is Bolder
- Hour 0 (midnight): only 6 fraud cases but avg amount **$303.34** — highest night avg
- Hour 2am: 57 cases but avg only $79.26 — high volume, lower amounts
- Two distinct night fraud profiles: bold midnight operators vs high-volume 2am attackers

### Finding 7 — Fraud Hides in Normal Transactions
- **94.1% of fraud** (463 of 473 cases) occurs in Normal transactions (Z-Score ≤ 2)
- Only 29 fraud cases appear in Anomalous (high Z-Score) transactions
- Z-Score detection alone would miss 94% of fraud
- Multi-factor detection combining amount, time and behavioural signals is required

### Finding 8 — Mid-Range Fraud Carries the Most Value
- $100-$1,000 fraud: 121 transactions | **$39,871.38 total value** — 66% of all fraud value
- $0-$100 fraud: 362 transactions | $7,019.26 total value — high volume, low value
- Total fraud value across all 473 cases: **$60,127.97**

### Finding 9 — The Complete Fraud Profile
A typical fraud transaction is:
- Amount between $0-$100 (73.6% probability)
- Occurring between midnight and 5am (highest risk window)
- Appearing statistically normal (94.1% of cases)
- Part of a sequence — micro test followed by mid-range escalation

### Finding 10 — Imbalanced Data Requires Specialist Techniques
- Standard accuracy metrics are misleading on 0.1667% fraud rate data
- Precision, Recall and F1-Score are required for proper fraud model evaluation
- SQL anomaly detection (Z-Score) is a first-pass filter — not a complete solution
- Recommended next step: Python scikit-learn with SMOTE oversampling for full model

---

## Recommendations

**1. Implement real-time night monitoring (midnight–5am)**
Fraud rate at 2am is 10x the daytime average. Automated alerts for transactions
in this window — especially amounts between $50-$500 — would flag the highest
risk period with minimal false positives.

**2. Flag micro-transaction sequences**
A card making multiple transactions under $10 within a short window is exhibiting
test transaction behaviour. Rule-based flagging of 3+ micro-transactions within
1 hour from the same origin would catch this pattern early.

**3. Build a multi-factor fraud score**
Z-Score alone catches only 6% of fraud. A composite score combining:
- Transaction amount relative to card history
- Time of day risk weight
- Micro-transaction sequence detection
- V1, V2, V14 feature values (strongest PCA signals in literature)
would dramatically improve detection rate.

**4. Prioritise mid-range fraud recovery**
$100-$1,000 fraud represents 66% of total fraud value at lower transaction
volumes. Chargeback and recovery efforts should prioritise this band for
maximum financial impact.

---

## Advanced SQL Skills Demonstrated

- **Views** — 3 production-ready Views for fraud monitoring
- **Stored Procedures** — 2 parameterised procedures for analyst self-service
- **Indexes** — Clustered PK + 2 Nonclustered indexes for query performance
- **Anomaly Detection** — Z-Score calculation using CTEs and CROSS JOIN
- **Data Cleaning** — ROW_NUMBER() deduplication, NULL audit and documentation
- **Window Functions** — PERCENTILE_CONT, ROW_NUMBER, SUM OVER
- **Multi-level CTEs** — chained CTEs for statistical calculations
- **IDENTITY columns** — auto-incrementing Primary Key
- **DROP PROCEDURE IF EXISTS** — safe procedure management

---

## Project Files

| File | Description |
|---|---|
| 01_setup_and_data_quality.sql | Import verification, NULL audit, deduplication, PK, Indexes |
| 02_views_and_setup.sql | 3 Views: vw_FraudTransactions, vw_LegitTransactions, vw_TransactionSummary |
| 03_fraud_analysis.sql | Amount comparison, fraud by band, fraud by hour using Views |
| 04_stored_procedures.sql | sp_FraudByAmountThreshold, sp_FraudByHourRange, Z-Score anomaly detection |

---

## Dataset Source

[Credit Card Fraud Detection](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud)  
ULB Machine Learning Group — real anonymised European cardholder transactions

---

## | Other SQL Projects |

- 🔗 [Olist E-Commerce SQL Analysis — Intermediate](https://github.com/NC-Dan/olist-ecommerce-sql-analysis)
- 🔗 [IBM HR Attrition Analysis — SQL](https://github.com/NC-Dan/ibm-hr-attrition-sql-analysis)

## | Excel Projects |

- 🔗 [Global Superstore Sales Dashboard](https://github.com/NC-Dan/global-superstore-sales-dashboard)
- 🔗 [Kenya Banking Risk Dashboard](https://github.com/NC-Dan/kenya-banking-risk-dashboard)
- 🔗 [Healthcare Analytics Dashboard](https://github.com/NC-Dan/healthcare-analytics-dashboard)

---

Connect on LinkedIn 🔗 [linkedin.com/in/duncanalyst](https://www.linkedin.com/in/duncanalyst)
