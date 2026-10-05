-- ============================================================
-- SUPERSTORE SALES ANALYSIS
-- ============================================================
-- Database : superstore_db (PostgreSQL)
-- Table    : public.superstore_sales
-- Data     : cleaned Superstore dataset (9,977 rows, 13 columns)
--
-- Purpose:
-- Analyze sales, profit, discounts, categories, regions,
-- customer segments, states, and cities.
--
-- Contents:
--   Section 0  : Table setup and data import
--   Section 1  : Data validation                (Queries 1-2)
--   Section 2  : Overall business performance   (Query 3)
--   Section 3  : Category analysis              (Queries 4-5)
--   Section 4  : Sub-category analysis          (Query 6)
--   Section 5  : Regional analysis              (Query 7)
--   Section 6  : Discount and profitability     (Queries 8, 16, 17)
--   Section 7  : State analysis                 (Queries 9-10)
--   Section 8  : Customer segment analysis      (Query 11)
--   Section 9  : City analysis                  (Queries 12, 18)
--   Section 10 : Advanced SQL analysis          (Queries 13-15)
-- ============================================================


-- ============================================================
-- SECTION 0: TABLE SETUP AND DATA IMPORT
-- ============================================================

-- Step 1: Create the table.
-- NUMERIC(12,4) keeps the full precision of Sales and Profit
-- (the source data has 4 decimal places), so SQL totals match
-- the Python and Power BI results exactly.

DROP TABLE IF EXISTS superstore_sales;

CREATE TABLE superstore_sales (
    ship_mode    VARCHAR(50),
    segment      VARCHAR(50),
    country      VARCHAR(50),
    city         VARCHAR(100),
    state        VARCHAR(50),
    postal_code  INT,
    region       VARCHAR(20),
    category     VARCHAR(50),
    sub_category VARCHAR(50),
    sales        NUMERIC(12,4),
    quantity     INT,
    discount     NUMERIC(4,2),
    profit       NUMERIC(12,4)
);

-- Step 2: Import the cleaned data.
-- PostgreSQL cannot read .xlsx files directly, so save the cleaned
-- dataset as CSV first (for example from the cleaning notebook:
-- cleaned_df.to_csv("../data/Cleaned/Superstore_Cleaned.csv", index=False)).
--
-- Then import it with psql (adjust the file path):
--
--   \copy superstore_sales FROM 'data/Cleaned/Superstore_Cleaned.csv' WITH (FORMAT csv, HEADER true);
--
-- or use pgAdmin: right-click the table > Import/Export Data.
-- The CSV column order must match the table definition above.


-- ============================================================
-- SECTION 1: DATA VALIDATION
-- ============================================================

-- Query 1: Verify total number of records (expected: 9,977)
SELECT
    COUNT(*) AS total_records
FROM superstore_sales;


-- Query 2: Preview sample records
SELECT *
FROM superstore_sales
LIMIT 5;


-- ============================================================
-- SECTION 2: OVERALL BUSINESS PERFORMANCE
-- ============================================================

-- Query 3: Overall business KPIs
SELECT
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity,
    ROUND(AVG(discount) * 100, 2) AS average_discount_pct,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM superstore_sales;


-- ============================================================
-- SECTION 3: CATEGORY ANALYSIS
-- ============================================================

-- Query 4: Sales, profit, and quantity by category
SELECT
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity
FROM superstore_sales
GROUP BY category
ORDER BY total_sales DESC;


-- Query 5: Profit margin by category
SELECT
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM superstore_sales
GROUP BY category
ORDER BY profit_margin_pct DESC;


-- ============================================================
-- SECTION 4: SUB-CATEGORY ANALYSIS
-- ============================================================

-- Query 6: Sales, profit, and margin by sub-category
SELECT
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM superstore_sales
GROUP BY sub_category
ORDER BY total_profit DESC;


-- ============================================================
-- SECTION 5: REGIONAL ANALYSIS
-- ============================================================

-- Query 7: Sales, profit, and margin by region
SELECT
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM superstore_sales
GROUP BY region
ORDER BY total_sales DESC;


-- ============================================================
-- SECTION 6: DISCOUNT AND PROFITABILITY ANALYSIS
-- ============================================================

-- Query 8: Profitability by detailed discount range
SELECT
    CASE
        WHEN discount = 0 THEN '0%'
        WHEN discount <= 0.10 THEN '1-10%'
        WHEN discount <= 0.20 THEN '11-20%'
        WHEN discount <= 0.30 THEN '21-30%'
        WHEN discount <= 0.40 THEN '31-40%'
        ELSE '41%+'
    END AS discount_range,

    COUNT(*) AS number_of_transactions,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,

    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct

FROM superstore_sales
GROUP BY discount_range
ORDER BY MIN(discount);


-- Query 16: Profit by discount level (same bands as the Power BI dashboard)
SELECT
    CASE
        WHEN discount = 0 THEN '0%'
        WHEN discount <= 0.20 THEN '1-20%'
        WHEN discount <= 0.40 THEN '21-40%'
        ELSE '41%+'
    END AS discount_band,

    COUNT(*) AS number_of_transactions,
    ROUND(SUM(profit), 2) AS total_profit

FROM superstore_sales
GROUP BY discount_band
ORDER BY MIN(discount);


-- Query 17: Impact of heavy discounts (above 20%) vs no discount
SELECT
    CASE
        WHEN discount = 0 THEN 'No discount'
        WHEN discount <= 0.20 THEN 'Discount 1-20%'
        ELSE 'Discount above 20%'
    END AS discount_group,

    COUNT(*) AS number_of_transactions,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,

    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct

FROM superstore_sales
GROUP BY discount_group
ORDER BY MIN(discount);


-- ============================================================
-- SECTION 7: STATE ANALYSIS
-- ============================================================

-- Query 9: Top 10 states by profit
SELECT
    state,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore_sales
GROUP BY state
ORDER BY total_profit DESC
LIMIT 10;


-- Query 10: Loss-making states
SELECT
    state,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore_sales
GROUP BY state
HAVING SUM(profit) < 0
ORDER BY total_profit ASC;


-- ============================================================
-- SECTION 8: CUSTOMER SEGMENT ANALYSIS
-- ============================================================

-- Query 11: Sales and profitability by customer segment
SELECT
    segment,
    COUNT(*) AS number_of_transactions,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM superstore_sales
GROUP BY segment
ORDER BY total_sales DESC;


-- ============================================================
-- SECTION 9: CITY ANALYSIS
-- ============================================================

-- Query 12: Top 10 cities by profit
SELECT
    city,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore_sales
GROUP BY city
ORDER BY total_profit DESC
LIMIT 10;


-- Query 18: Top 10 cities by sales, with profit
-- (shows that some of the highest-selling cities lose money)
SELECT
    city,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    CASE
        WHEN SUM(profit) < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS result
FROM superstore_sales
GROUP BY city
ORDER BY SUM(sales) DESC
LIMIT 10;


-- ============================================================
-- SECTION 10: ADVANCED SQL ANALYSIS
-- ============================================================

-- Query 13: Sub-categories with above-average sales
-- but below-average profit

WITH subcategory_performance AS (
    SELECT
        sub_category,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit
    FROM superstore_sales
    GROUP BY sub_category
)

SELECT
    sub_category,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(total_profit, 2) AS total_profit
FROM subcategory_performance
WHERE total_sales > (
    SELECT AVG(total_sales)
    FROM subcategory_performance
)
AND total_profit < (
    SELECT AVG(total_profit)
    FROM subcategory_performance
)
ORDER BY total_sales DESC;


-- Query 14: Category contribution to overall sales
SELECT
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(
        SUM(sales) / SUM(SUM(sales)) OVER () * 100,
        2
    ) AS sales_contribution_pct
FROM superstore_sales
GROUP BY category
ORDER BY total_sales DESC;


-- Query 15: Rank sub-categories by profit within each category
WITH subcategory_profit AS (
    SELECT
        category,
        sub_category,
        SUM(profit) AS total_profit
    FROM superstore_sales
    GROUP BY category, sub_category
)

SELECT
    category,
    sub_category,
    ROUND(total_profit, 2) AS total_profit,
    RANK() OVER (
        PARTITION BY category
        ORDER BY total_profit DESC
    ) AS profit_rank
FROM subcategory_profit
ORDER BY category, profit_rank;


-- ============================================================
-- END OF SQL ANALYSIS
-- ============================================================
