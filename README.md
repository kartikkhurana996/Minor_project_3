# 🚩 RedFlag — The Fraud Files

A MySQL-based fraud detection project that identifies suspicious transaction patterns using SQL.

## 📌 Project Overview

**RedFlag — The Fraud Files** is a SQL fraud detection project developed using **MySQL**.

The project analyzes transaction data and detects potentially suspicious users and transaction patterns using SQL techniques such as:

- `GROUP BY`
- `HAVING`
- `CASE WHEN`
- Conditional Aggregation
- Common Table Expressions (CTEs)
- Window Functions
- `LAG()`
- Date and Time Functions
- Aggregate Functions

The complete project contains **12 fraud detection patterns**.

---

## 🎯 Objectives

- Analyze transaction data using SQL.
- Identify potentially fraudulent transaction patterns.
- Detect suspicious user behaviour.
- Apply advanced SQL concepts to a real-world use case.
- Generate suspect lists for different fraud scenarios.

---

## 🗄️ Dataset

The project uses a `transactions` table from the `redflag` database.

### Table: `transactions`

| Column | Description |
|---|---|
| `txn_id` | Unique transaction ID |
| `user_id` | ID of the user |
| `merchant_id` | ID of the merchant |
| `amount` | Transaction amount |
| `txn_time` | Date and time of transaction |
| `status` | Transaction status |
| `payment_mode` | Payment method |
| `city` | Transaction city |
| `txn_type` | Type of transaction |

---

## 🚩 Fraud Detection Patterns

The project detects the following 12 suspicious patterns:

### P1 — Velocity Abuse
Identifies users making an unusually high number of transactions within a short period.

### P2 — Round Amount Pattern
Detects users with a high frequency of transactions using common round-number amounts.

### P3 — Card Testing
Identifies suspicious patterns that may indicate card testing behaviour.

### P4 — Failed-Then-Succeeded Transactions
Detects users with repeated failed transactions followed by successful transactions.

### P5 — Odd-Hour Activity
Identifies users whose transactions are heavily concentrated between **2 AM and 5 AM**.

### P6 — Mule Account Behaviour
Detects suspicious account activity that may indicate the use of an account as a money mule.

### P7 — Refund Abuse
Identifies suspicious refund-related transaction patterns.

### P8 — Merchant Collusion
Detects suspicious relationships between users and merchants.

### P9 — ₹9,999 Structuring
Identifies repeated transactions involving the **₹9,999** amount.

### P10 — Dormant-Then-Active
Detects accounts that become active again after a long period of inactivity.

### P11 — Velocity Spike
Identifies sudden increases in transaction activity.

### P12 — Geographic Impossibility
Detects users making transactions from different cities within an unrealistically short time period.

---

## 🛠️ Technologies Used

- **MySQL**
- **MySQL Workbench**
- SQL

### SQL Concepts Used

```text
SELECT
WHERE
GROUP BY
HAVING
ORDER BY
COUNT()
SUM()
AVG()
CASE WHEN
WITH
LAG()
DATEDIFF()
TIMESTAMPDIFF()
HOUR()
