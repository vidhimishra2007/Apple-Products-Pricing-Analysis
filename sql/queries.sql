-- -- ============================================================================
-- -- queries.sql
-- -- Apple Products Pricing Analysis — Amazon vs Flipkart India (2020-2026)
-- -- All queries tested against the cleaned dataset (SQLite dialect).
-- -- Table: apple_pricing (loaded from apple_products_pricing_cleaned.csv,
-- -- the output of 01_cleaning.ipynb)
-- --
-- -- BigQuery notes: replace julianday(a) - julianday(b) with DATE_DIFF(a, b, DAY),
-- -- and NTILE()/window syntax is identical in BigQuery Standard SQL.
-- -- ============================================================================


-- -- ----------------------------------------------------------------------------
-- -- 0. Sanity check: row count and date range
-- -- ----------------------------------------------------------------------------
-- SELECT
--     COUNT(*)   AS total_rows,
--     MIN(Date)  AS earliest_date,
--     MAX(Date)  AS latest_date,
--     COUNT(DISTINCT Model_Name) AS n_models
-- FROM apple_pricing;


-- -- ----------------------------------------------------------------------------
-- -- Q1a. Markup rate by product category
-- -- ("markup" = Discount_Pct < 0, i.e. priced above launch price)
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Product_Category,
--     ROUND(AVG(CASE WHEN Discount_Pct < 0 THEN 1.0 ELSE 0 END), 4) AS markup_rate,
--     COUNT(*) AS n
-- FROM apple_pricing
-- GROUP BY Product_Category
-- ORDER BY markup_rate DESC;


-- -- ----------------------------------------------------------------------------
-- -- Q1b. Markup rate by platform
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Platform,
--     ROUND(AVG(CASE WHEN Discount_Pct < 0 THEN 1.0 ELSE 0 END), 4) AS markup_rate
-- FROM apple_pricing
-- GROUP BY Platform;


-- -- ----------------------------------------------------------------------------
-- -- Q1c. THE KEY FINDING: markup rate and avg discount by "model age"
-- -- (days since each model's first appearance in the dataset, used as a proxy
-- -- for time since launch — see caveat in 02_eda.ipynb)
-- -- ----------------------------------------------------------------------------
-- WITH first_seen AS (
--     SELECT Model_Name, MIN(Date) AS first_date
--     FROM apple_pricing
--     GROUP BY Model_Name
-- ),
-- aged AS (
--     SELECT
--         p.*,
--         CAST(julianday(p.Date) - julianday(f.first_date) AS INTEGER) AS days_since_first_seen
--     FROM apple_pricing p
--     JOIN first_seen f ON p.Model_Name = f.Model_Name
-- )
-- SELECT
--     CASE
--         WHEN days_since_first_seen <= 30  THEN '0-30d'
--         WHEN days_since_first_seen <= 90  THEN '31-90d'
--         WHEN days_since_first_seen <= 180 THEN '91-180d'
--         WHEN days_since_first_seen <= 365 THEN '181-365d'
--         WHEN days_since_first_seen <= 730 THEN '1-2y'
--         ELSE '2y+'
--     END AS age_bucket,
--     ROUND(AVG(CASE WHEN Discount_Pct < 0 THEN 1.0 ELSE 0 END), 3) AS markup_rate,
--     ROUND(AVG(Discount_Pct), 2) AS avg_discount,
--     COUNT(*) AS n
-- FROM aged
-- GROUP BY age_bucket
-- ORDER BY MIN(days_since_first_seen);
-- -- Result: markup rate ~25-36% in the first year, drops to 0% after 1 year;
-- -- avg discount climbs from ~6-10% (near launch) to ~35% (2y+).


-- -- ----------------------------------------------------------------------------
-- -- Q2a. Average discount by sale event
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Sale_Event,
--     ROUND(AVG(Discount_Pct), 2) AS avg_discount,
--     COUNT(*) AS n
-- FROM apple_pricing
-- GROUP BY Sale_Event
-- ORDER BY avg_discount DESC;


-- -- ----------------------------------------------------------------------------
-- -- Q2b. Average discount by sale event x product category
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Sale_Event,
--     Product_Category,
--     ROUND(AVG(Discount_Pct), 2) AS avg_discount
-- FROM apple_pricing
-- WHERE Sale_Event != 'No Event'
-- GROUP BY Sale_Event, Product_Category
-- ORDER BY Sale_Event, Product_Category;


-- -- ----------------------------------------------------------------------------
-- -- Q2c. Which platform does each sale event actually appear on?
-- -- (Big Billion Days = Flipkart only; Prime Day / Great Indian Festival =
-- -- Amazon only; Black Friday appears on both — check this before comparing
-- -- platforms on a specific event.)
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Sale_Event,
--     Platform,
--     COUNT(*) AS n
-- FROM apple_pricing
-- WHERE Sale_Event != 'No Event'
-- GROUP BY Sale_Event, Platform
-- ORDER BY Sale_Event, Platform;


-- -- ----------------------------------------------------------------------------
-- -- Q3a. New vs. Renewed/Refurbished — launch price, current price, discount
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Condition,
--     ROUND(AVG(Launch_Price_USD), 2)  AS avg_launch_price,
--     ROUND(AVG(Current_Price_USD), 2) AS avg_current_price,
--     ROUND(AVG(Discount_Pct), 2)      AS avg_discount
-- FROM apple_pricing
-- GROUP BY Condition;


-- -- ----------------------------------------------------------------------------
-- -- Q3b. Does the New vs. Refurbished price gap change year over year?
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Year,
--     ROUND(AVG(CASE WHEN Condition = 'New' THEN Current_Price_USD END), 2) AS avg_new_price,
--     ROUND(AVG(CASE WHEN Condition = 'Renewed/Refurbished' THEN Current_Price_USD END), 2) AS avg_refurb_price
-- FROM apple_pricing
-- GROUP BY Year
-- ORDER BY Year;
-- -- Result: gap holds steady at ~21-26% every year — not widening or narrowing.


-- -- ----------------------------------------------------------------------------
-- -- Q4. Platform comparison: average discount by platform x category
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Platform,
--     Product_Category,
--     ROUND(AVG(Discount_Pct), 2) AS avg_discount
-- FROM apple_pricing
-- GROUP BY Platform, Product_Category
-- ORDER BY Product_Category, Platform;
-- -- Result: Amazon and Flipkart are within ~0.3 points of each other on every
-- -- category — a genuine null result, not a platform pricing war.


-- -- ----------------------------------------------------------------------------
-- -- Q5. Price history for a single model (for charting a depreciation curve)
-- -- Swap the Model_Name value to inspect other products.
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Date,
--     Platform,
--     Current_Price_USD,
--     Discount_Pct
-- FROM apple_pricing
-- WHERE Model_Name = 'iPhone 13 128GB'
--   AND Condition = 'New'
-- ORDER BY Date;


-- -- ----------------------------------------------------------------------------
-- -- Q6. Stock status vs. discount and markup rate
-- -- ----------------------------------------------------------------------------
-- SELECT
--     Stock_Status,
--     ROUND(AVG(Discount_Pct), 2) AS avg_discount,
--     ROUND(AVG(CASE WHEN Discount_Pct < 0 THEN 1.0 ELSE 0 END), 3) AS markup_rate,
--     COUNT(*) AS n
-- FROM apple_pricing
-- GROUP BY Stock_Status
-- ORDER BY avg_discount DESC;
-- -- Result: Low Stock / Out of Stock carry deeper average discounts and LOWER
-- -- markup rates than In Stock — the opposite of a naive scarcity-pricing story.
-- -- Reads as "discounts drive sell-through," not "scarcity drives price up."


-- -- ----------------------------------------------------------------------------
-- -- Q7. Reviews and rating by discount quartile
-- -- (NTILE window function needs a CTE — most engines reject referencing a
-- -- window-function alias directly in the same query's GROUP BY.)
-- -- ----------------------------------------------------------------------------
-- WITH quartiled AS (
--     SELECT
--         Discount_Pct,
--         Reviews_Count,
--         Rating,
--         NTILE(4) OVER (ORDER BY Discount_Pct) AS discount_quartile
--     FROM apple_pricing
-- )
-- SELECT
--     discount_quartile,
--     ROUND(AVG(Discount_Pct), 2) AS avg_discount_in_quartile,
--     ROUND(AVG(Reviews_Count), 0) AS avg_reviews,
--     ROUND(AVG(Rating), 2) AS avg_rating
-- FROM quartiled
-- GROUP BY discount_quartile
-- ORDER BY discount_quartile;
-- -- Result: avg_reviews rises sharply with discount depth (824 -> 4330 from
-- -- quartile 1 to 4); avg_rating drifts slightly down (4.55 -> 4.39).

































-- =========================================================
-- Apple Products Pricing Analysis (2020-2026)
-- SQL Analysis Queries
-- Table: apple_pricing (loaded from cleaned dataset)
-- =========================================================

-- 1. Overall average discount % by product category, ordered highest to lowest
SELECT
    Product_Category,
    ROUND(AVG(Discount_Pct), 2) AS avg_discount_pct,
    COUNT(*) AS num_records
FROM apple_pricing
GROUP BY Product_Category
ORDER BY avg_discount_pct DESC;

-- 2. Platform comparison: avg discount, avg price, avg rating
SELECT
    Platform,
    ROUND(AVG(Discount_Pct), 2) AS avg_discount_pct,
    ROUND(AVG(Current_Price_USD), 2) AS avg_price_usd,
    ROUND(AVG(Rating), 2) AS avg_rating
FROM apple_pricing
GROUP BY Platform;

-- 3. Sale event impact: discount % during each named sale event vs normal days
SELECT
    Sale_Event,
    ROUND(AVG(Discount_Pct), 2) AS avg_discount_pct,
    COUNT(*) AS num_records
FROM apple_pricing
GROUP BY Sale_Event
ORDER BY avg_discount_pct DESC;

-- 4. Yearly price trend for iPhones (avg current price by year)
SELECT
    Year,
    ROUND(AVG(Current_Price_USD), 2) AS avg_price_usd
FROM apple_pricing
WHERE Product_Category = 'iPhone'
GROUP BY Year
ORDER BY Year;

-- 5. Top 5 most-reviewed models overall
SELECT
    Model_Name,
    Product_Category,
    SUM(Reviews_Count) AS total_reviews,
    ROUND(AVG(Rating), 2) AS avg_rating
FROM apple_pricing
GROUP BY Model_Name
ORDER BY total_reviews DESC
LIMIT 5;

-- 6. Stock status distribution by platform (as % using window function)
SELECT
    Platform,
    Stock_Status,
    COUNT(*) AS cnt,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY Platform), 2) AS pct_of_platform
FROM apple_pricing
GROUP BY Platform, Stock_Status
ORDER BY Platform, pct_of_platform DESC;

-- 7. New vs Renewed/Refurbished: average price gap by category
SELECT
    Product_Category,
    Condition,
    ROUND(AVG(Current_Price_USD), 2) AS avg_price_usd
FROM apple_pricing
GROUP BY Product_Category, Condition
ORDER BY Product_Category, Condition;

-- 8. Month-over-month average discount trend using a window function (CTE + LAG)
WITH monthly_discount AS (
    SELECT
        Year,
        Month,
        ROUND(AVG(Discount_Pct), 2) AS avg_discount_pct
    FROM apple_pricing
    GROUP BY Year, Month
)
SELECT
    Year,
    Month,
    avg_discount_pct,
    ROUND(avg_discount_pct - LAG(avg_discount_pct) OVER (ORDER BY Year, Month), 2) AS change_vs_prev_month
FROM monthly_discount
ORDER BY Year, Month;

-- 9. Rank each model's average current price within its category (window function)
WITH model_avg AS (
    SELECT
        Product_Category,
        Model_Name,
        ROUND(AVG(Current_Price_USD), 2) AS avg_price_usd
    FROM apple_pricing
    GROUP BY Product_Category, Model_Name
)
SELECT
    Product_Category,
    Model_Name,
    avg_price_usd,
    RANK() OVER (PARTITION BY Product_Category ORDER BY avg_price_usd DESC) AS price_rank_in_category
FROM model_avg
ORDER BY Product_Category, price_rank_in_category;

-- 10. Deepest single-day discounts recorded (top 10 outliers)
SELECT
    Date, Platform, Model_Name, Condition, Discount_Pct, Sale_Event
FROM apple_pricing
ORDER BY Discount_Pct DESC
LIMIT 10;

-- 11. Out-of-stock rate during sale events vs normal days
SELECT
    On_Sale_Event,
    ROUND(100.0 * SUM(CASE WHEN Stock_Status = 'Out of Stock' THEN 1 ELSE 0 END) / COUNT(*), 2) AS out_of_stock_pct
FROM apple_pricing
GROUP BY On_Sale_Event;

-- 12. Correlation proxy: average rating vs average discount bucket
-- (uses the Is_Markup flag for the price-increase case, rather than re-deriving it from Discount_Pct)
SELECT
    CASE
        WHEN Is_Markup = 1 THEN 'Price Increase'
        WHEN Discount_Pct = 0 THEN 'No Discount'
        WHEN Discount_Pct <= 15 THEN 'Low (0-15%)'
        WHEN Discount_Pct <= 30 THEN 'Medium (15-30%)'
        ELSE 'High (30%+)'
    END AS discount_bucket,
    ROUND(AVG(Rating), 2) AS avg_rating,
    COUNT(*) AS num_records
FROM apple_pricing
GROUP BY discount_bucket
ORDER BY avg_rating DESC;

-- 13. Markup frequency by category and platform
SELECT
    Product_Category,
    Platform,
    SUM(Is_Markup) AS markup_days,
    COUNT(*) AS total_days,
    ROUND(100.0 * SUM(Is_Markup) / COUNT(*), 2) AS markup_pct
FROM apple_pricing
GROUP BY Product_Category, Platform
ORDER BY markup_pct DESC;