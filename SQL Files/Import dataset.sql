-- =====================================================
-- DATA IMPORT FOR SQL SERVER
-- =====================================================

-- Step 1: Import CSV using BULK INSERT
-- Method 1:Using OPENROWSET (if enabled)
BULK INSERT staging_superstore
FROM 'D:\BCA\Carear\Data Analytics\Projects\E-commerce Project\Superstore Sales Analysis Project\superstore_dataset.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2);
GO

-- Check data imported
SELECT COUNT(*) AS staging_row_count FROM staging_superstore;
SELECT TOP 10 * FROM staging_superstore;
GO

-- Step 2: Populate Customers Dimension
INSERT INTO customers (customer_name, segment)
SELECT DISTINCT 
    LTRIM(RTRIM(customer)),
    LTRIM(RTRIM(segment))
FROM staging_superstore
WHERE customer IS NOT NULL AND customer != ''
EXCEPT
SELECT customer_name, segment FROM customers;
GO

-- Step 3: Populate Products Dimension
INSERT INTO products (product_name, manufactory, category, subcategory)
SELECT DISTINCT 
    LTRIM(RTRIM(product_name)),
    LTRIM(RTRIM(manufactory)),
    LTRIM(RTRIM(category)),
    LTRIM(RTRIM(subcategory))
FROM staging_superstore
WHERE product_name IS NOT NULL AND product_name != ''
EXCEPT
SELECT product_name, manufactory, category, subcategory FROM products;
GO

-- Step 4: Populate Locations Dimension
INSERT INTO locations (country, region, state, city, zip)
SELECT DISTINCT 
    ISNULL(LTRIM(RTRIM(country)), 'United States'),
    LTRIM(RTRIM(region)),
    LTRIM(RTRIM(state)),
    LTRIM(RTRIM(city)),
    LTRIM(RTRIM(zip))
FROM staging_superstore
WHERE region IS NOT NULL
EXCEPT
SELECT country, region, state, city, zip FROM locations;
GO

-- Step 5: Populate Orders Fact Table
-- Modified INSERT query with duplicate handling
INSERT INTO orders (
    order_id, order_date, ship_date, customer_id, product_id, 
    location_id, sales, quantity, discount, profit, profit_margin
)
SELECT 
    s.order_id,
    s.order_date,
    s.ship_date,
    c.customer_id,
    p.product_id,
    l.location_id,
    s.sales,
    s.quantity,
    s.discount,
    s.profit,
    s.profit_margin
FROM (
    -- Deduplicate staging_superstore
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id 
            ORDER BY order_date DESC
        ) AS rn
    FROM staging_superstore
) s
INNER JOIN customers c ON c.customer_name = s.customer AND c.segment = s.segment
INNER JOIN products p ON p.product_name = s.product_name 
    AND p.category = s.category 
    AND p.subcategory = s.subcategory
INNER JOIN locations l ON l.region = s.region 
    AND l.state = s.state 
    AND l.city = s.city
    AND (l.zip = s.zip OR (l.zip IS NULL AND s.zip IS NULL))
WHERE s.rn = 1;  -- Takes only one record per order_id
GO

-- Step 6: Verify Data Import
SELECT 'Customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Locations', COUNT(*) FROM locations
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders;
GO

-- Step 7: Data Validation
SELECT 
    (SELECT COUNT(*) FROM orders) AS orders_count,
    (SELECT COUNT(DISTINCT order_id) FROM staging_superstore) AS staging_orders_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM orders) = (SELECT COUNT(DISTINCT order_id) FROM staging_superstore) 
        THEN 'MATCH' 
        ELSE 'MISMATCH' 
    END AS validation_status;
GO