USE FraudDetection;
GO

-- STORED PROCEDURE 1: Get fraud summary by amount threshold
DROP PROCEDURE sp_FraudByAmountThreshold;
GO

CREATE PROCEDURE sp_FraudByAmountThreshold
    @MinAmount DECIMAL(10,2),
    @MaxAmount DECIMAL(10,2)
AS
BEGIN
    SELECT 
        COUNT(*)                        AS FraudTransactions,
        CAST(MIN(Amount) AS DECIMAL(10,2)) AS MinAmount,
        CAST(MAX(Amount) AS DECIMAL(10,2)) AS MaxAmount,
        CAST(AVG(Amount) AS DECIMAL(10,2)) AS AvgAmount,
        CAST(SUM(Amount) AS DECIMAL(12,2)) AS TotalFraudValue
    FROM Transactions
    WHERE Class = 1
    AND Amount BETWEEN @MinAmount AND @MaxAmount;
END;
GO

-- STORED PROCEDURE 2: Get fraud transactions by hour range
DROP PROCEDURE sp_FraudByHourRange;
GO

CREATE PROCEDURE sp_FraudByHourRange
    @StartHour INT,
    @EndHour INT
AS
BEGIN
    WITH HourlyData AS (
        SELECT 
            TransactionID,
            Amount,
            CAST(CAST(Time AS INT) / 3600 % 24 AS INT) AS HourOfDay
        FROM Transactions
        WHERE Class = 1
    )
    SELECT 
        HourOfDay,
        COUNT(*)                            AS FraudCount,
        CAST(AVG(Amount) AS DECIMAL(10,2))  AS AvgFraudAmount,
        CAST(SUM(Amount) AS DECIMAL(12,2))  AS TotalFraudValue
    FROM HourlyData
    WHERE HourOfDay BETWEEN @StartHour AND @EndHour
    GROUP BY HourOfDay
    ORDER BY FraudCount DESC;
END;
GO

-- Execute the procedures
EXEC sp_FraudByAmountThreshold @MinAmount = 0, @MaxAmount = 100;
GO
EXEC sp_FraudByAmountThreshold @MinAmount = 100, @MaxAmount = 1000;
GO
EXEC sp_FraudByHourRange @StartHour = 0, @EndHour = 6;
GO

-- ANALYSIS 4: Statistical anomaly detection
-- Flag transactions more than 2 standard deviations above mean
WITH TransactionStats AS (
    SELECT 
        AVG(Amount)     AS MeanAmount,
        STDEV(Amount)   AS StdDevAmount
    FROM Transactions
),
AnomalyFlags AS (
    SELECT 
        t.TransactionID,
        t.Amount,
        t.Class,
        s.MeanAmount,
        s.StdDevAmount,
        (t.Amount - s.MeanAmount) / s.StdDevAmount  AS ZScore,
        CASE 
            WHEN (t.Amount - s.MeanAmount) / s.StdDevAmount > 2 
                THEN 'Anomalous'
            ELSE 'Normal'
        END AS AnomalyFlag
    FROM Transactions t
    CROSS JOIN TransactionStats s
)
SELECT 
    AnomalyFlag,
    Class,
    CASE WHEN Class = 1 THEN 'Fraud' ELSE 'Legitimate' END AS TransactionType,
    COUNT(*)                            AS TotalTransactions,
    CAST(AVG(Amount) AS DECIMAL(10,2))  AS AvgAmount,
    CAST(MIN(Amount) AS DECIMAL(10,2))  AS MinAmount,
    CAST(MAX(Amount) AS DECIMAL(10,2))  AS MaxAmount
FROM AnomalyFlags
GROUP BY AnomalyFlag, Class
ORDER BY AnomalyFlag, Class;
GO