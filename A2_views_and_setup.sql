USE FraudDetection;
GO

-- VIEW 1: Fraud transactions only
DROP VIEW vw_FraudTransactions;
GO

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
DROP VIEW vw_LegitTransactions;
GO

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
DROP VIEW vw_TransactionSummary;
GO
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

