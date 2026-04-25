USE FraudDetection;
GO

-- VIEW 1: Fraud transactions only

CREATE VIEW vw_FraudTransactions AS
SELECT 
    TransactionID,
    Time,
    Amount,
    V1, V2, V3, V4, V14, V17
FROM Transactions
WHERE Class = 1;
GO

-- VIEW 2: Legitimate transactions only
CREATE VIEW vw_LegitTransactions AS
SELECT 
    TransactionID,
    Time,
    Amount,
    V1, V2, V3, V4, V14, V17
FROM Transactions
WHERE Class = 0;
GO

-- VIEW 3: Full transaction summary view
CREATE VIEW vw_TransactionSummary AS
SELECT
    TransactionID,
    Time,
    CAST(Time / 3600.0 AS DECIMAL(8,2))    AS TimeHours,
    Amount,
    Class,
    CASE WHEN Class = 1 THEN 'Fraud' 
         ELSE 'Legitimate' END              AS TransactionType,
    CASE 
        WHEN Amount < 10    THEN 'Micro'
        WHEN Amount < 100   THEN 'Small'
        WHEN Amount < 1000  THEN 'Medium'
        ELSE 'Large'
    END                                     AS AmountBand
FROM Transactions;
GO

-- Test the views
SELECT COUNT(*) AS FraudCount FROM vw_FraudTransactions;
GO
SELECT COUNT(*) AS LegitCount FROM vw_LegitTransactions;
GO
SELECT TOP 5 * FROM vw_TransactionSummary;
GO

-- ANALYSIS 1: Fraud vs Legitimate Amount Comparison
SELECT 
    TransactionType,
    COUNT(*)                            AS TotalTransactions,
    CAST(MIN(Amount) AS DECIMAL(10,2))  AS MinAmount,
    CAST(MAX(Amount) AS DECIMAL(10,2))  AS MaxAmount,
    CAST(AVG(Amount) AS DECIMAL(10,2))  AS AvgAmount,
    CAST(SUM(Amount) AS DECIMAL(15,2))  AS TotalAmount
FROM vw_TransactionSummary
GROUP BY TransactionType
ORDER BY TransactionType;
GO

-- ANALYSIS 2: Fraud by Amount Band
SELECT 
    AmountBand,
    COUNT(*)                                        AS TotalTransactions,
    SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END)     AS FraudCount,
    CAST(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / 
        COUNT(*) AS DECIMAL(7,4))                   AS FraudRate
FROM vw_TransactionSummary
GROUP BY AmountBand
ORDER BY FraudRate DESC;
GO

-- ANALYSIS 3: Fraud by Time Period (Hour of Day)
SELECT 
    CAST(TimeHours % 24 AS INT)         AS HourOfDay,
    COUNT(*)                            AS TotalTransactions,
    SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS FraudCount,
    CAST(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / 
        COUNT(*) AS DECIMAL(7,4))       AS FraudRate
FROM vw_TransactionSummary
GROUP BY CAST(TimeHours % 24 AS INT)
ORDER BY FraudRate DESC;
GO