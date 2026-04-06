-- =====================================================
-- SUPERSTORE SALES ANALYSIS DATABASE
-- SQL Server (SSMS) Version
-- =====================================================

-- Create Database
CREATE DATABASE superstore_db;

USE superstore_db;

-- =====================================================
-- CREATE STAGING TABLE (for raw data import)
-- =====================================================

CREATE TABLE staging_superstore (
    order_id NVARCHAR(50),
    order_date DATE,
    ship_date DATE,
    customer NVARCHAR(100),
    manufactory NVARCHAR(100),
    product_name NVARCHAR(255),
    segment NVARCHAR(50),
    category NVARCHAR(50),
    subcategory NVARCHAR(50),
    region NVARCHAR(50),
    zip NVARCHAR(20),
    city NVARCHAR(100),
    state NVARCHAR(100),
    country NVARCHAR(50),
    discount DECIMAL(5,4),
    profit DECIMAL(10,2),
    quantity INT,
    sales DECIMAL(10,2),
    profit_margin DECIMAL(10,4)
);

-- =====================================================
-- CREATE NORMALIZED DIMENSION TABLES
-- =====================================================

-- 1. Customers Dimension Table
CREATE TABLE customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_name NVARCHAR(100) NOT NULL,
    segment NVARCHAR(50) NOT NULL,
    CONSTRAINT UQ_customer UNIQUE (customer_name, segment)
);

-- 2. Products Dimension Table
CREATE TABLE products (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    product_name NVARCHAR(255) NOT NULL,
    manufactory NVARCHAR(100),
    category NVARCHAR(50) NOT NULL,
    subcategory NVARCHAR(50) NOT NULL,
    CONSTRAINT UQ_product UNIQUE (product_name, manufactory)
);

-- 3. Locations Dimension Table
CREATE TABLE locations (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    country NVARCHAR(50) DEFAULT 'United States',
    region NVARCHAR(50) NOT NULL,
    state NVARCHAR(100) NOT NULL,
    city NVARCHAR(100) NOT NULL,
    zip NVARCHAR(20),
    CONSTRAINT UQ_location UNIQUE (region, state, city, zip)
);

-- 4. Orders Fact Table
CREATE TABLE orders (
    order_id NVARCHAR(50) PRIMARY KEY,
    order_date DATE NOT NULL,
    ship_date DATE NOT NULL,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    location_id INT NOT NULL,
    sales DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    discount DECIMAL(5,4) NOT NULL,
    profit DECIMAL(10,2) NOT NULL,
    profit_margin DECIMAL(10,4),
    CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT FK_orders_products FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT FK_orders_locations FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

-- Create indexes for better query performance
CREATE INDEX idx_order_date ON orders(order_date);
CREATE INDEX idx_customer ON orders(customer_id);
CREATE INDEX idx_product ON orders(product_id);
CREATE INDEX idx_location ON orders(location_id);
CREATE INDEX idx_sales ON orders(sales);
CREATE INDEX idx_profit ON orders(profit);

-- Verify tables created
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG = 'superstore_db';
