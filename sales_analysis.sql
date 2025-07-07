-- sales_analysis.sql

-- ========================================
-- 🗂️ CLEAN DATA
-- ========================================

-- Remove duplicates by keeping the first record
DELETE FROM sales_table
WHERE id NOT IN (
    SELECT MIN(id)
    FROM sales_table
    GROUP BY order_id
);

-- Remove NULLs in critical columns
DELETE FROM sales_table
WHERE order_id IS NULL
   OR customer_id IS NULL
   OR product_id IS NULL
   OR sales_amount IS NULL;

-- Fix negative sales amounts
UPDATE sales_table
SET sales_amount = ABS(sales_amount)
WHERE sales_amount < 0;

-- Trim spaces in text fields
UPDATE customers
SET customer_name = TRIM(customer_name);

-- ========================================
-- 📊 SALES KPIs
-- ========================================

-- Total Sales
SELECT SUM(sales_amount) AS total_sales FROM sales_table;

-- Monthly Sales
SELECT DATE_TRUNC('month', order_date) AS month,
       SUM(sales_amount) AS total_sales
FROM sales_table
GROUP BY month
ORDER BY month;

-- Top 10 Products
SELECT product_id, SUM(sales_amount) AS total_sales
FROM sales_table
GROUP BY product_id
ORDER BY total_sales DESC
LIMIT 10;

-- Sales by Region
SELECT region, SUM(sales_amount) AS total_sales
FROM sales_table
GROUP BY region
ORDER BY total_sales DESC;

-- New vs Returning Customers
WITH first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM sales_table
    GROUP BY customer_id
)
SELECT CASE 
           WHEN f.first_order_date >= DATE_TRUNC('year', CURRENT_DATE) THEN 'New'
           ELSE 'Returning'
       END AS customer_type,
       COUNT(DISTINCT s.customer_id) AS customer_count,
       SUM(s.sales_amount) AS total_sales
FROM sales_table s
JOIN first_orders f ON s.customer_id = f.customer_id
GROUP BY customer_type;

-- Profit Analysis
SELECT SUM(sales_amount) AS total_sales,
       SUM(cost_amount) AS total_cost,
       SUM(sales_amount - cost_amount) AS profit
FROM sales_table;

-- Create Cleaned View
CREATE VIEW clean_sales AS
SELECT order_id, customer_id, product_id, sales_amount, cost_amount, order_date, region
FROM sales_table
WHERE sales_amount >= 0 AND customer_id IS NOT NULL;
