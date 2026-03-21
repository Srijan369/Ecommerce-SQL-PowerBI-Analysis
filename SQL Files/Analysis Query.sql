#Basic INNER JOIN

# Customers + Orders
SELECT 
    c.customer_unique_id,
    o.order_id,
    o.order_purchase_timestamp
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id;

# Orders + Order Items
SELECT 
    o.order_id,
    oi.product_id,
    oi.price
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id;

#Add Products (FULL DATA)
SELECT 
    o.order_id,
    p.product_category_name,
    oi.price
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id;

# FULL BUSINESS DATA
SELECT 
    c.customer_unique_id,
    o.order_id,
    p.product_category_name,
    oi.price,
    pay.payment_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN payments pay ON o.order_id = pay.order_id;

# Analysis Query 

# Total Revenue
SELECT SUM(payment_value) AS total_revenue FROM payments;

# Top 5 Customers
SELECT 
    c.customer_unique_id,
    SUM(pay.payment_value) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments pay ON o.order_id = pay.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 5;

# Revenue by Category
SELECT 
    p.product_category_name,
    SUM(pay.payment_value) AS revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN payments pay ON o.order_id = pay.order_id
GROUP BY p.product_category_name
ORDER BY revenue DESC;

# Monthly Revenue Trend
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    SUM(pay.payment_value) AS revenue
FROM orders o
JOIN payments pay ON o.order_id = pay.order_id
GROUP BY month
ORDER BY month;

# Top Selling Products
SELECT 
    product_id,
    COUNT(*) AS total_orders
FROM order_items
GROUP BY product_id
ORDER BY total_orders DESC
LIMIT 5;

