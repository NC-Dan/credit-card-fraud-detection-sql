-- ================================================
-- DATA QUALITY DECISIONS
-- ================================================
-- NULLs in V2-V28: 21-237 per column
-- Decision: Retained as-is — NULLs result from import
-- precision loss on extreme outlier values.
-- Imputation would introduce false data on
-- anonymised PCA features. Excluded from calculations.
--
-- Duplicate rows: 1,081 identified and removed
-- Method: ROW_NUMBER() PARTITION BY Time, Amount,
-- Class, V1, V2, V3 — kept lowest TransactionID
-- Result: 283,726 clean rows | 473 fraud | 283,253 legit
-- Fraud rate corrected: 0.1667% (was 0.173%)
-- ================================================

CREATE DATABASE FraudDetection;
GO

USE FraudDetection;
GO

-- Row count
SELECT COUNT(*) AS TotalTransactions FROM Transactions;
GO

-- Preview first 5 rows
SELECT TOP 50 * FROM Transactions;
GO

-- Check fraud vs legitimate split
SELECT 
    Class,
    COUNT(*) AS Total,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(7,4)) AS Percentage
FROM Transactions
GROUP BY Class;
GO

-- Data Quality Audit

-- CHECK 1: NULL values
SELECT
    SUM(CASE WHEN Time IS NULL THEN 1 ELSE 0 END)   AS Null_Time,
    SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END)  AS Null_Amount,
    SUM(CASE WHEN Class IS NULL THEN 1 ELSE 0 END)   AS Null_Class,
    SUM(CASE WHEN V1 IS NULL THEN 1 ELSE 0 END)      AS Null_V1,
    SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V2,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V3,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V4,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V5,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V6,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V7,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V8,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V9,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V10,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V11,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V12,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V13,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V14,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V15,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V16,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V17,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V18,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V19,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V20,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V21,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V22,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V23,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V24,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V25,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V26,
	SUM(CASE WHEN V2 IS NULL THEN 1 ELSE 0 END)      AS Null_V27,
    SUM(CASE WHEN V28 IS NULL THEN 1 ELSE 0 END)     AS Null_V28
FROM Transactions;
GO

-- CHECK 2a: How many duplicates exist?
WITH DuplicateCTE AS (
    SELECT 
        TransactionID,
        ROW_NUMBER() OVER (
            PARTITION BY Time, Amount, Class, V1, V2, V3
            ORDER BY TransactionID
        ) AS RowNum
    FROM Transactions
)
SELECT COUNT(*) AS DuplicateRowsToDelete
FROM DuplicateCTE
WHERE RowNum > 1;
GO

-- CHECK 2b: DELETE duplicates 
WITH DuplicateCTE AS (
    SELECT 
        TransactionID,
        ROW_NUMBER() OVER (
            PARTITION BY Time, Amount, Class, V1, V2, V3
            ORDER BY TransactionID
        ) AS RowNum
    FROM Transactions
)
DELETE FROM DuplicateCTE
WHERE RowNum > 1;
GO

-- Verify clean row count
SELECT 
    COUNT(*)                                        AS TotalTransactions,
    SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END)     AS FraudTransactions,
    SUM(CASE WHEN Class = 0 THEN 1 ELSE 0 END)     AS LegitTransactions
FROM Transactions;
GO

-- CHECK 3a: Basic Amount stats
SELECT
    MIN(Amount)                         AS MinAmount,
    MAX(Amount)                         AS MaxAmount,
    AVG(Amount)                         AS AvgAmount,
    STDEV(Amount)                       AS StdDevAmount
FROM Transactions;
GO

-- CHECK 3b: Median Amount
SELECT DISTINCT
    PERCENTILE_CONT(0.5) WITHIN GROUP 
        (ORDER BY Amount) OVER() AS MedianAmount
FROM Transactions;
GO

-- CHECK 4: Time range
SELECT
    MIN(Time) AS FirstTransaction,
    MAX(Time) AS LastTransaction,
    MAX(Time) - MIN(Time) AS TimeSpanSeconds,
    (MAX(Time) - MIN(Time)) / 3600 AS TimeSpanHours
FROM Transactions;
GO


-- Add a TransactionID identity column as Primary Key
ALTER TABLE Transactions
ADD TransactionID INT IDENTITY(1,1);
GO

-- Set it as Primary Key
ALTER TABLE Transactions
ADD CONSTRAINT PK_Transactions PRIMARY KEY (TransactionID);
GO


-- Add Index on Class for fast fraud filtering
CREATE INDEX IX_Transactions_Class 
ON Transactions(Class);
GO

-- Add Index on Amount for fast amount-based queries
CREATE INDEX IX_Transactions_Amount
ON Transactions(Amount);
GO

-- Verify
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.name = 'Transactions'
ORDER BY i.index_id;
GO
