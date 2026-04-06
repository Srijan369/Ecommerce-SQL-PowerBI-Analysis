-- =====================================================
-- BUSINESS ANALYSIS QUERIES
-- SQL Server (SSMS) Version
-- =====================================================
-- ------------------------------------------------
-- KPI 1: Overall Business Performance
-- ------------------------------------------------
SELECT 
    'Total Sales' AS metric,
    CONCAT('$', FORMAT(SUM(sales), 'N2')) AS value
FROM orders
UNION ALL
SELECT 
    'Total Profit',
    CONCAT('$', FORMAT(SUM(profit), 'N2'))
FROM orders
UNION ALL
SELECT 
    'Profit Margin',
    CONCAT(FORMAT(SUM(profit)/SUM(sales)*100, 'N2'), '%')
FROM orders
UNION ALL
SELECT 
    'Total Orders',
    FORMAT(COUNT(DISTINCT order_id), 'N0')
FROM orders
UNION ALL
SELECT 
    'Total Quantity Sold',
    FORMAT(SUM(quantity), 'N0')
FROM orders
UNION ALL
SELECT 
    'Avg Order Value',
    CONCAT('$', FORMAT(AVG(order_total), 'N2'))
FROM (
    SELECT order_id, SUM(sales) AS order_total
    FROM orders
    GROUP BY order_id
) AS order_totals;
GO

-- ------------------------------------------------
-- KPI 2: Sales & Profit by Category
-- ------------------------------------------------
SELECT 
    p.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin_pct,
    ROUND(AVG(o.profit_margin), 2) AS avg_profit_margin
FROM orders o
INNER JOIN products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY total_sales DESC;
GO

-- ------------------------------------------------
-- KPI 3: Top 10 Best Selling Products
-- ------------------------------------------------
SELECT TOP 10
    p.product_name,
    p.category,
    p.subcategory,
    COUNT(DISTINCT o.order_id) AS times_ordered,
    SUM(o.quantity) AS total_quantity,
    ROUND(SUM(o.sales), 2) AS total_revenue,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin
FROM orders o
INNER JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category, p.subcategory
ORDER BY total_revenue DESC;
GO

-- ------------------------------------------------
-- KPI 4: Bottom 10 Loss-Making Products
-- ------------------------------------------------
SELECT TOP 10
    p.product_name,
    p.category,
    p.subcategory,
    COUNT(DISTINCT o.order_id) AS times_ordered,
    ROUND(SUM(o.sales), 2) AS total_revenue,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin
FROM orders o
INNER JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category, p.subcategory
HAVING SUM(o.profit) < 0
ORDER BY total_profit ASC;
GO

-- ------------------------------------------------
-- KPI 5: Sales & Profit by Region
-- ------------------------------------------------
SELECT 
    l.region,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin_pct
FROM orders o
INNER JOIN locations l ON o.location_id = l.location_id
GROUP BY l.region
ORDER BY total_sales DESC;
GO

-- ------------------------------------------------
-- KPI 6: Sales by Customer Segment
-- ------------------------------------------------
SELECT 
    c.segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(AVG(o.sales), 2) AS avg_order_value,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY total_sales DESC;
GO

-- ------------------------------------------------
-- KPI 7: Monthly Sales Trend (Time Series)
-- ------------------------------------------------
SELECT 
    FORMAT(o.order_date, 'yyyy-MM') AS month,
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month_num,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin
FROM orders o
GROUP BY FORMAT(o.order_date, 'yyyy-MM'), YEAR(o.order_date), MONTH(o.order_date)
ORDER BY month;
GO

-- ------------------------------------------------
-- KPI 8: Year-over-Year Growth
-- ------------------------------------------------
WITH yearly_sales AS (
    SELECT 
        YEAR(order_date) AS year,
        ROUND(SUM(sales), 2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    GROUP BY YEAR(order_date)
)
SELECT 
    year,
    total_sales,
    total_profit,
    total_orders,
    LAG(total_sales) OVER (ORDER BY year) AS prev_year_sales,
    ROUND((total_sales - LAG(total_sales) OVER (ORDER BY year)) / 
          NULLIF(LAG(total_sales) OVER (ORDER BY year), 0) * 100, 2) AS sales_growth_pct,
    LAG(total_profit) OVER (ORDER BY year) AS prev_year_profit,
    ROUND((total_profit - LAG(total_profit) OVER (ORDER BY year)) / 
          NULLIF(LAG(total_profit) OVER (ORDER BY year), 0) * 100, 2) AS profit_growth_pct
FROM yearly_sales
ORDER BY year;
GO

-- ------------------------------------------------
-- KPI 9: Discount Impact Analysis
-- ------------------------------------------------
SELECT 
    CASE 
        WHEN discount = 0 THEN '0%'
        WHEN discount <= 0.1 THEN '1-10%'
        WHEN discount <= 0.2 THEN '11-20%'
        WHEN discount <= 0.3 THEN '21-30%'
        WHEN discount <= 0.4 THEN '31-40%'
        ELSE '40%+'
    END AS discount_range,
    COUNT(*) AS transaction_count,
    ROUND(AVG(sales), 2) AS avg_sales,
    ROUND(AVG(profit), 2) AS avg_profit,
    ROUND(AVG(profit)/NULLIF(AVG(sales), 0)*100, 2) AS avg_profit_margin,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(sales), 2) AS total_sales
FROM orders
GROUP BY 
    CASE 
        WHEN discount = 0 THEN '0%'
        WHEN discount <= 0.1 THEN '1-10%'
        WHEN discount <= 0.2 THEN '11-20%'
        WHEN discount <= 0.3 THEN '21-30%'
        WHEN discount <= 0.4 THEN '31-40%'
        ELSE '40%+'
    END
ORDER BY MIN(discount);
GO

-- ------------------------------------------------
-- KPI 10: Top 10 Customers by Lifetime Value
-- ------------------------------------------------
SELECT TOP 10
    c.customer_name,
    c.segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS lifetime_value,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(AVG(o.sales), 2) AS avg_order_value,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY lifetime_value DESC;
GO

-- ------------------------------------------------
-- KPI 11: State-wise Performance (Top 10)
-- ------------------------------------------------
SELECT TOP 10
    l.state,
    l.region,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM orders o
INNER JOIN locations l ON o.location_id = l.location_id
INNER JOIN customers c ON o.customer_id = c.customer_id
GROUP BY l.state, l.region
ORDER BY total_sales DESC;
GO

-- ------------------------------------------------
-- KPI 12: Sub-Category Performance
-- ------------------------------------------------
SELECT TOP 15
    p.category,
    p.subcategory,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin,
    ROUND(AVG(o.discount) * 100, 2) AS avg_discount_pct,
    SUM(o.quantity) AS total_quantity
FROM orders o
INNER JOIN products p ON o.product_id = p.product_id
GROUP BY p.category, p.subcategory
ORDER BY total_sales DESC;
GO

-- ------------------------------------------------
-- KPI 13: Seasonal Analysis (Monthly Patterns)
-- ------------------------------------------------
SELECT 
    DATENAME(MONTH, order_date) AS month_name,
    MONTH(order_date) AS month_num,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(AVG(sales), 2) AS avg_order_value,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit)/NULLIF(SUM(sales), 0)*100, 2) AS profit_margin
FROM orders
GROUP BY DATENAME(MONTH, order_date), MONTH(order_date)
ORDER BY month_num;
GO

-- ------------------------------------------------
-- KPI 14: Customer Retention Analysis
-- ------------------------------------------------
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) AS order_count,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        DATEDIFF(DAY, MIN(order_date), MAX(order_date)) AS customer_lifetime_days
    FROM orders
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time Buyer'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 Times'
        WHEN order_count BETWEEN 4 AND 6 THEN '4-6 Times'
        WHEN order_count BETWEEN 7 AND 10 THEN '7-10 Times'
        ELSE '10+ Times'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(AVG(order_count), 1) AS avg_orders_per_customer,
    ROUND(AVG(customer_lifetime_days), 0) AS avg_lifetime_days
FROM customer_orders
GROUP BY 
    CASE 
        WHEN order_count = 1 THEN 'One-Time Buyer'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 Times'
        WHEN order_count BETWEEN 4 AND 6 THEN '4-6 Times'
        WHEN order_count BETWEEN 7 AND 10 THEN '7-10 Times'
        ELSE '10+ Times'
    END
ORDER BY MIN(order_count);
GO

-- ------------------------------------------------
-- KPI 15: Manufacturer Performance
-- ------------------------------------------------
SELECT TOP 10
    p.manufactory,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin
FROM orders o
INNER JOIN products p ON o.product_id = p.product_id
WHERE p.manufactory IS NOT NULL AND p.manufactory != ''
GROUP BY p.manufactory
ORDER BY total_sales DESC;
GO

-- ------------------------------------------------
-- KPI 16: City-wise Performance (Top 10)
-- ------------------------------------------------
SELECT TOP 10
    l.city,
    l.state,
    l.region,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin
FROM orders o
INNER JOIN locations l ON o.location_id = l.location_id
GROUP BY l.city, l.state, l.region
ORDER BY total_sales DESC;
GO

-- ------------------------------------------------
-- KPI 17: Profit Margin Distribution
-- ------------------------------------------------
SELECT 
    CASE 
        WHEN profit_margin < -20 THEN 'Loss (>20% loss)'
        WHEN profit_margin < 0 THEN 'Loss (0-20%)'
        WHEN profit_margin = 0 THEN 'Break Even'
        WHEN profit_margin <= 10 THEN 'Low Profit (0-10%)'
        WHEN profit_margin <= 20 THEN 'Medium Profit (10-20%)'
        WHEN profit_margin <= 40 THEN 'High Profit (20-40%)'
        ELSE 'Very High Profit (40%+)'
    END AS margin_category,
    COUNT(*) AS transaction_count,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY 
    CASE 
        WHEN profit_margin < -20 THEN 'Loss (>20% loss)'
        WHEN profit_margin < 0 THEN 'Loss (0-20%)'
        WHEN profit_margin = 0 THEN 'Break Even'
        WHEN profit_margin <= 10 THEN 'Low Profit (0-10%)'
        WHEN profit_margin <= 20 THEN 'Medium Profit (10-20%)'
        WHEN profit_margin <= 40 THEN 'High Profit (20-40%)'
        ELSE 'Very High Profit (40%+)'
    END
ORDER BY MIN(profit_margin);
GO

-- ------------------------------------------------
-- KPI 18: Weekly Sales Pattern
-- ------------------------------------------------
SELECT 
    DATEPART(WEEKDAY, order_date) AS day_num,
    DATENAME(WEEKDAY, order_date) AS day_name,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(AVG(sales), 2) AS avg_order_value,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY DATEPART(WEEKDAY, order_date), DATENAME(WEEKDAY, order_date)
ORDER BY day_num;
GO

-- ------------------------------------------------
-- KPI 19: Product Category Cross Analysis
-- ------------------------------------------------
SELECT 
    c.segment,
    p.category,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(SUM(o.profit), 2) AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales), 0)*100, 2) AS profit_margin
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN products p ON o.product_id = p.product_id
GROUP BY c.segment, p.category
ORDER BY c.segment, total_sales DESC;
GO

-- ------------------------------------------------
-- KPI 20: Executive Summary (Single Row)
-- ------------------------------------------------
SELECT 
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit)/NULLIF(SUM(sales), 0)*100, 2) AS overall_profit_margin,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS unique_products,
    ROUND(AVG(sales), 2) AS avg_order_value,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM orders;
GO

-- ------------------------------------------------
-- KPI 21: Export Data for Power BI
-- ------------------------------------------------
-- Create a view for Power BI
CREATE VIEW vw_powerbi_sales AS
SELECT 
    o.order_id,
    o.order_date,
    o.ship_date,
    o.sales,
    o.quantity,
    o.discount,
    o.profit,
    o.profit_margin,
    c.customer_name,
    c.segment,
    p.product_name,
    p.manufactory,
    p.category,
    p.subcategory,
    l.region,
    l.state,
    l.city,
    l.zip,
    l.country
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN products p ON o.product_id = p.product_id
INNER JOIN locations l ON o.location_id = l.location_id;
GO

-- Export to CSV for Power BI
-- In SSMS: Right-click database -> Tasks -> Export Data -> Flat File Destination
-- OR use this query to copy results
SELECT * FROM vw_powerbi_sales;
GO