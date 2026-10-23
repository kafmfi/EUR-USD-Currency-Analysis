
-- ==================================================
-- EUR/USD Forex Historical Data Analysis
-- SQL Portfolio Project
-- Database: SQLite
-- Period: 2005 - 2020
-- ==================================================

-- ==================================================
-- SECTION 1: DATABASE PREPARATION
-- Source CSV File: cleaned_eurusd.csv
-- CSV Imported into SQLite Table: eurusd_data
-- New Table Created with Correct Data Types: cleaned_eurusd_data

-- Note: The table already exists in eurusd_analysis.db.
-- This section documents the database preparation process.
-- Do not rerun it on the existing database.
-- ==================================================

CREATE TABLE cleaned_eurusd_data (
    Date TEXT,
    BO REAL,
    BH REAL,
    BL REAL,
    BC REAL,
    BCh REAL,
    AO REAL,
    AH REAL,
    AL REAL,
    AC REAL,
    ACh REAL,
    Price_Change REAL,
    "Price_Change_%" REAL,
    Year INTEGER,
    Month TEXT,
    Season TEXT,
    B_volatility REAL,
    A_volatility REAL,
    Price_range TEXT
);

INSERT INTO cleaned_eurusd_data
SELECT Date,BO,BH,BL,BC,BCh,AO,AH,AL,AC,ACh,
Price_Change,"Price_Change_%",Year,Month,Season,
B_volatility,A_volatility,Price_range 
FROM eurusd_data;

-- ==========================================
-- Section 2: Data Quality & Validation
-- ==========================================
-- Check the total number of records in the dataset
SELECT COUNT(*) FROM cleaned_eurusd_data;
-- The Total Period of EUR/USD Trading
SELECT MIN(Date) AS First_date,
MAX(Date) AS Last_date
FROM cleaned_eurusd_data;
-- Finding Duplicate Date
SELECT Date, COUNT(*) AS duplicate_count
FROM cleaned_eurusd_data
GROUP BY Date
HAVING COUNT(*)>1;
-- Result: No duplicate dates found.
-- Checking Missing Values
SELECT
SUM(CASE WHEN Date IS NULL THEN 1 ELSE 0 END) AS date_null,
SUM(CASE WHEN BC IS NULL THEN 1 ELSE 0 END) AS BC_null,
SUM(CASE WHEN AC IS NULL THEN 1 ELSE 0 END) AS AC_null
FROM cleaned_eurusd_data;
-- Result: No missing values found in Date, BC, and AC.

-- ==========================================
-- Section 3: Yearly Market Performance
-- ==========================================

--Has been categorised trading by Year
SELECT
    Year,
    SUM(CASE WHEN BC > BO THEN 1 ELSE 0 END) AS Bullish_days,
    SUM(CASE WHEN BC < BO THEN 1 ELSE 0 END) AS Bearish_days,
    SUM(CASE WHEN BC = BO THEN 1 ELSE 0 END) AS Neutral_days
    
FROM cleaned_eurusd_data
GROUP BY Year
ORDER BY Year;

-- Calculated Bullish Days in Percent by Year
SELECT YEAR,
COUNT(*) AS total_days,
ROUND(100.0*SUM(CASE WHEN BC>BO THEN 1 ELSE 0 END)/COUNT(*),2) AS Bullis_percentange
FROM cleaned_eurusd_data
GROUP BY YEAR
ORDER BY Bullis_percentange DESC;


-- Calculate the annual EUR/USD exchange Rate Price Change in Percentage
WITH yearly_price AS (SELECT Year,
(SELECT BO
FROM cleaned_eurusd_data AS d
WHERE d.Year=y.Year
ORDER BY Date ASC
LIMIT 1) AS First_day,
(SELECT BC
FROM cleaned_eurusd_data AS t
WHERE t.Year=y.Year
ORDER BY Date DESC
LIMIT 1)AS Last_day
FROM cleaned_eurusd_data AS y
GROUP BY  Year
ORDER BY Year)

SELECT Year,First_day,Last_day,
ROUND((Last_day-First_day)*100.00/First_day,2)
AS Annual_price_change_percentange
FROM yearly_price
ORDER BY Annual_price_change_percentange ASC;

-- ==========================================
-- Section 4: Monthly Market Performance
-- ==========================================

--Monthly Price Change in Each Year in Percent
--Including First And Last Trading Days of Each Month
WITH Monthly_price AS (SELECT
d.Year,
d.Month,
MIN(d.Date) AS First_Trading_days,
(SELECT BO 
FROM cleaned_eurusd_data AS o
WHERE o.Year=d.Year AND o.Month=d.Month
ORDER BY o.Date ASC
LIMIT 1)AS Opening_price,
MAX(d.Date) AS Last_Trading_days,
(SELECT BC
FROM cleaned_eurusd_data AS c
WHERE c.Year= d.Year AND c.Month=d.Month
ORDER BY c.Date DESC
LIMIT 1) AS Closing_price
FROM cleaned_eurusd_data AS d
GROUP BY d.Year, d.Month
ORDER BY d.Year, strftime('%m', MIN(d.Date)))

SELECT * ,
ROUND((Closing_price-Opening_price)/Opening_price*100,2)
AS Monthly_price_change_percent
FROM Monthly_price;

--Highest Monthly price change in percent
--Including the Year
WITH Monthly_price AS (SELECT
d.Year,
d.Month,
MIN(d.Date) AS First_Trading_days,
(SELECT BO 
FROM cleaned_eurusd_data AS o
WHERE o.Year=d.Year AND o.Month=d.Month
ORDER BY o.Date ASC
LIMIT 1)AS Opening_price,
MAX(d.Date) AS Last_Trading_days,
(SELECT BC
FROM cleaned_eurusd_data AS c
WHERE c.Year= d.Year AND c.Month=d.Month
ORDER BY c.Date DESC
LIMIT 1) AS Closing_price
FROM cleaned_eurusd_data AS d
GROUP BY d.Year, d.Month
ORDER BY d.Year, strftime('%m', MIN(d.Date))),

Monthly_change AS(SELECT * ,
ROUND((Closing_price-Opening_price)/Opening_price*100,2)
AS Monthly_price_change_percent
FROM Monthly_price)

SELECT Year,Month,Monthly_price_change_percent
AS Highest_Monthly_price_change_percent
FROM Monthly_change
ORDER BY Monthly_price_change_percent DESC
LIMIT 1;

--Lowest Monthly price change in percent
--Including the Year
WITH Monthly_price AS (SELECT
d.Year,
d.Month,
MIN(d.Date) AS First_Trading_days,
(SELECT BO 
FROM cleaned_eurusd_data AS o
WHERE o.Year=d.Year AND o.Month=d.Month
ORDER BY o.Date ASC
LIMIT 1)AS Opening_price,
MAX(d.Date) AS Last_Trading_days,
(SELECT BC
FROM cleaned_eurusd_data AS c
WHERE c.Year= d.Year AND c.Month=d.Month
ORDER BY c.Date DESC
LIMIT 1) AS Closing_price
FROM cleaned_eurusd_data AS d
GROUP BY d.Year, d.Month
ORDER BY d.Year, strftime('%m', MIN(d.Date))),

Monthly_change AS(SELECT * ,
ROUND((Closing_price-Opening_price)/Opening_price*100,2)
AS Monthly_price_change_percent
FROM Monthly_price)

SELECT Year,Month,Monthly_price_change_percent
AS Lowest_monthly_price_change_percent
FROM Monthly_change
ORDER BY Monthly_price_change_percent ASC
LIMIT 1;


-- ==========================================
-- Section 5: Weekday Market Analysis
-- ==========================================

--Categorised Total  week days of Trading
SELECT strftime("%w", Date) 
AS Days_of_week,
COUNT(*)AS Total_trading,
SUM(CASE WHEN BC>BO THEN 1 ELSE 0 END) 
AS Total_Bullish,
SUM(CASE WHEN BC<BO THEN 1 ELSE 0 END)
AS Total_Bearish,
SUM(CASE WHEN BC=BO THEN 1
ELSE 0 END)
AS Total_Neural
FROM cleaned_eurusd_data
GROUP BY strftime("%w", Date);

--Avarage Absulate Price Change of Total Weekdays
--Has been done by desending ordered according to price
SELECT strftime("%w", Date) AS Days_of_week,
ROUND(AVG(ABS(Price_Change)),6) 
AS Avg_absulate_price_change
FROM cleaned_eurusd_data
GROUP BY strftime("%w", Date)
ORDER BY ROUND(AVG(ABS(Price_Change)),6)  DESC;

-- Volatility Among Total Weekdays
WITH Daily_deviation AS(SELECT Date,Price_Change,AVG(Price_Change) 
OVER(PARTITION BY strftime("%w", Date)) 
AS Week_days_avg,Price_Change-AVG(Price_Change)
OVER (PARTITION BY strftime("%w", Date)) AS Deviation
FROM cleaned_eurusd_data
ORDER BY Date),

Daily_squire_deviation AS
(SELECT Date,Deviation, Deviation*Deviation 
AS Squire_Deviation 
FROM Daily_deviation),

Avg_deviation AS(SELECT Date,Deviation,Squire_Deviation,
AVG(Squire_Deviation) 
OVER (PARTITION BY strftime("%w",Date))
AS Avg__squired_deviation 
FROM Daily_squire_deviation)

SELECT strftime("%w",Date) AS Days_of_week,
Avg__squired_deviation, SQRT(Avg__squired_deviation)
AS Standard_deviation
FROM Avg_deviation
GROUP BY  strftime("%w",Date)
ORDER BY SQRT(Avg__squired_deviation) DESC;

-- ==========================================
-- Section 6: Key Findings & Conclusion
-- ==========================================

-- Data Quality: 
-- Records: 4,672;
-- No NULL values found in Date, BC, and AC.
-- No duplicate dates found.

-- Yearly Performance:
-- Highest Annual Price Increase: 2017 (+14.65%)
-- Largest Annual Price Decrease: 2014 (-11.97%)

-- Monthly Performance:
-- Highest Monthly Price Increase: December 2008 (+10.30%)
-- Largest Monthly Price Decrease: October 2008 (-9.93%)

-- Weekday Analysis:
-- Highest Average Absolute Price Change: Thursday (0.005940)
-- Highest Standard Deviation: Thursday (0.008056)

-- After checking the selected data quality indicators, the SQL analysis
-- showed that the highest annual price increase occurred in 2017,
-- while the largest annual price decrease occurred in 2014.
-- Similarly, the highest monthly price increase was recorded in
-- December 2008, and the largest decrease occurred in October 2008.
-- Thursday showed the highest standard deviation and the highest
-- average absolute daily price change in the historical dataset.