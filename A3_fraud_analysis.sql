USE FraudDetection;
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