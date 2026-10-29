CREATE DATABASE EcommerceCustomerAnalytics;

USE EcommerceCustomerAnalytics;

SELECT COUNT(*) AS table1
FROM dbo.[Year 2009-2010];

SELECT COUNT(*) AS table2
FROM dbo.[Year 2010-2011];

-- Combine both Years & convert DataTypes safely

SELECT
	Invoice, StockCode, Description, Quantity,
	COALESCE(
		TRY_CONVERT(datetime2, InvoiceDate, 120),
		TRY_CONVERT(datetime2, InvoiceDate, 105)
	) AS InvoiceDate,
	TRY_CONVERT(decimal(10,2), Price) AS Price,
	Customer_ID, Country, '2009-2010' AS SourceSheet
INTO dbo.RetailCombined
FROM dbo.[Year 2009-2010]

UNION ALL

SELECT
	Invoice, StockCode, Description, Quantity,
	COALESCE(
		TRY_CONVERT(datetime2, InvoiceDate, 120),
		TRY_CONVERT(datetime2, InvoiceDate, 105)
	) AS InvoiceDate,
	TRY_CONVERT(decimal(10,2), Price) AS Price,
	Customer_ID, Country, '2010-2011' AS SourceSheet
FROM dbo.[Year 2010-2011];

-- Confirn the conversion worked cleanly

SELECT COUNT(*) AS Total_Rows
FROM dbo.RetailCombined;

SELECT COUNT(*) AS Failed_Date
FROM dbo.RetailCombined
WHERE InvoiceDate IS NULL;

SELECT COUNT(*) AS Failed_Price
FROM dbo.RetailCombined
WHERE Price IS NULL;

-- Missing Customer ID
SELECT COUNT(*) AS Missing_Customer_ID
FROM dbo.RetailCombined
WHERE Customer_ID IS NULL;

-- Negative or Zero quantity
SELECT COUNT(*) AS Negative_Quantity
FROM dbo.RetailCombined
WHERE Quantity <= 0;

-- Missing Description
SELECT COUNT(*) AS Missing_Description
FROM dbo.RetailCombined
WHERE Description IS NULL;

-- Exact Duplicate Rows
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country,
	COUNT(*) AS ExactDuplicateCount
FROM dbo.RetailCombined
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
HAVING COUNT(*) > 9;

-- DEDUPLICATE AND PRODUCE THE FINAL CLEANED TABLE
WITH Deduped AS (
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
			ORDER BY (SELECT NULL)
		) AS RowNum
	FROM dbo.RetailCombined
)
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country, SourceSheet
INTO dbo.RetailCleaned
FROM Deduped
WHERE RowNum = 1;