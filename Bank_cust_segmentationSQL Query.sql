SELECT * FROM cust_transactions;

--How many unique customers are there?

SELECT COUNT(DISTINCT CustomerID) AS Unique_customers
FROM cust_transactions;

--What is the distribution of customers by gender?

SELECT CustGender, COUNT(DISTINCT CustomerID) AS total_customers
FROM cust_transactions
GROUP BY CustGender
ORDER BY total_customers DESC;

--What is the distribution of customers by location? Top 10 Customers by Location

SELECT TOP 10 CustLocation, COUNT(DISTINCT CustomerID) AS total_customers
FROM cust_transactions
GROUP BY CustLocation
ORDER BY total_customers DESC;

--What is the total number of transactions?

SELECT COUNT(TransactionID) AS total_transactions
FROM cust_transactions;

--What is the total transaction amount?

SELECT SUM(TransactionAmount) AS total_transaction_amount
FROM cust_transactions;

--What is the average transaction amount per customer?

SELECT CustomerID, AVG(TransactionAmount) AS average_trans_amount
FROM cust_transactions
GROUP BY CustomerID
ORDER BY average_trans_amount DESC;

--What is the average account balance?

SELECT ROUND(AVG(CustAccountBalance), 2) AS avg_account_amount
FROM cust_transactions;

--What is the total account balance for all customers?

SELECT CustomerID, SUM(CustAccountBalance) AS total_account_amount
FROM cust_transactions
GROUP BY CustomerID
ORDER BY total_account_amount DESC;

--What is the average age of customers?

SELECT AVG(Age) AS avg_age
FROM cust_transactions;


--How many customers fall into different age groups (e.g., 18-30, 31-50, 50+)?

WITH CTE AS
	(SELECT *,
		CASE 
			WHEN Age >= 18 AND Age <= 30 THEN 'Young Age'
			WHEN Age > 30 AND Age <= 50 THEN 'Middle Age'
			WHEN Age > 50 THEN 'Old Age'
			END AS Age_Group
	FROM cust_transactions)
SELECT Age_Group, COUNT(DISTINCT CustomerID) AS total_customers
FROM CTE
GROUP BY Age_Group;

--What are the peak hours for transactions?

WITH CTE AS
	(SELECT *, DATEPART(HOUR, TransactionTime) AS transaction_hours
	FROM cust_transactions)
SELECT transaction_hours, COUNT(TransactionID) AS total_transaction_count
FROM CTE
GROUP BY transaction_hours
ORDER BY total_transaction_count DESC;

--What is the distribution of transactions by day of the week?

WITH CTE AS
	(SELECT *, DATENAME(WEEKDAY, TransactionDate) AS transaction_day
	FROM cust_transactions)
SELECT transaction_day, COUNT(TransactionID) AS total_transaction_count
FROM CTE
GROUP BY transaction_day
ORDER BY total_transaction_count DESC;

--Top 10 high-transaction customer?

SELECT TOP 10 CustomerID, COUNT(*) AS total_transactions
FROM cust_transactions
GROUP BY CustomerID
ORDER BY total_transactions DESC;

--Low-transaction customer?

WITH CTE AS
	(SELECT CustomerID, COUNT(*) AS total_transactions
	FROM cust_transactions
	GROUP BY CustomerID)
SELECT CustomerID, total_transactions
FROM CTE 
WHERE total_transactions < 4
ORDER BY total_transactions DESC;

--Identify the top 10 customers by transaction amount.

SELECT TOP 10 CustomerID, SUM(TransactionAmount) AS total_transaction_amount
FROM cust_transactions
GROUP BY CustomerID
ORDER BY total_transaction_amount DESC;

--Determine the average transaction amount for different customer segments (by gender, location, age group).
--Average Transaction amount by gender

SELECT CustGender, ROUND(AVG(TransactionAmount), 2) AS avg_trans_amt
FROM cust_transactions
GROUP BY CustGender
ORDER BY avg_trans_amt DESC;

--Average Transaction amount by location

SELECT CustLocation, ROUND(AVG(TransactionAmount), 2) AS avg_trans_amt
FROM cust_transactions
GROUP BY CustLocation
ORDER BY avg_trans_amt DESC;

--Average Transaction amount by Age-Group

WITH CTE AS
	(SELECT *,
		CASE 
			WHEN Age >= 18 AND Age <= 30 THEN 'Young Age'
			WHEN Age > 30 AND Age <= 50 THEN 'Middle Age'
			WHEN Age > 50 THEN 'Old Age'
			END AS Age_Group
	FROM cust_transactions)
SELECT Age_Group, ROUND(AVG(TransactionAmount), 2) AS avg_trans_amt
FROM CTE
GROUP BY Age_Group
ORDER BY avg_trans_amt DESC;

--Peak hour for maximum amount of transaction?

WITH CTE AS
	(SELECT *, DATEPART(HOUR, TransactionTime) AS transaction_hours
	FROM cust_transactions)
SELECT transaction_hours, ROUND(SUM(TransactionAmount), 2) AS total_trans_amt
FROM CTE
GROUP BY transaction_hours
ORDER BY total_trans_amt DESC;


--Analyze the trend in total transaction over months.

WITH CTE AS
	(SELECT *, FORMAT(TransactionDate, 'MMMM') AS month_name, MONTH(TransactionDate) AS month_number
	FROM cust_transactions)
SELECT month_name, month_number, COUNT(DISTINCT TransactionID) AS total_transactions
FROM CTE
GROUP BY month_name, month_number
ORDER BY month_number;

--Identify customers whose account balance has decreased between first transaction and last transaction

WITH CTE AS
	(SELECT CustomerID, TransactionDate, CustAccountBalance,
	ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY TransactionDate ASC) AS row_asc,
	ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY TransactionDate DESC) AS row_desc
	FROM cust_transactions
	--ORDER BY CustomerID
	),
CTE2 AS
	(SELECT c1.CustomerID, c1.CustAccountBalance AS start_balance, c2.CustAccountBalance AS last_balance
	FROM CTE AS c1
	JOIN CTE AS c2
	ON c1.CustomerID = c2.CustomerID
	AND c1.row_asc = 1
	AND c2.row_desc = 1)
SELECT CustomerID, start_balance, last_balance, (start_balance - last_balance) AS balance_decrease
FROM CTE2
WHERE (start_balance - last_balance) > 0
ORDER BY balance_decrease DESC;


--Identify customers who might be at risk of churning 

WITH CTE AS
	(SELECT CustomerID, MONTH(TransactionDate) AS trans_month, COUNT(TransactionID) AS trans_count
	FROM cust_transactions
	GROUP BY CustomerID, MONTH(TransactionDate)
	--ORDER BY CustomerID
	), 
CTE2 AS
	(SELECT *,
	ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY trans_month ASC) AS row_asc,
	ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY trans_month DESC) AS row_desc
	FROM CTE),
CTE3 AS
	(SELECT c1.CustomerID, c1.trans_count AS start_trans_count, c2.trans_count AS last_trans_count
	FROM CTE2 AS c1
	JOIN CTE2 AS c2
	ON c1.CustomerID = c2.CustomerID
	AND c1.row_asc = 1
	AND c2.row_desc = 1)
SELECT CustomerID, start_trans_count, last_trans_count, (last_trans_count - start_trans_count) AS trans_count_diff
FROM CTE3
WHERE (last_trans_count - start_trans_count) > 0
ORDER BY trans_count_diff ASC;