/*===============================================================
Exploration Data Analysis
Purpose:
    This script explores the Gold layer across 6 different
	basic dimensions of data analysis covering dimension content, 
	time range, and key business metrics of the customers,
	products and sales areas.

Usage Notes:
    Results are intended to guide analytical and report 
	design decisions, not for direct business consumption.
=================================================================*/


/*
	01 Database Exploration
*/

-- Explore ALL objects in the database
SELECT *
FROM INFORMATION_SCHEMA.TABLES;

-- Explore columns in the database
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS;

SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold';

/*
	02 Dimensions Exploration
*/
-- All countries that customers come from
SELECT DISTINCT country
FROM gold.dim_customers;

-- Major hierarchy of products
SELECT DISTINCT category
FROM gold.dim_products;

-- All categories of products
SELECT DISTINCT category, subcategory, product_name
FROM gold.dim_products
ORDER BY 1,2,3;

/*
	03 Date Range Exploration
*/
-- Oldest and youngest customers in the database
SELECT first_name,
	   last_name,
	   birthdate,
	   DATEDIFF(year, birthdate, GETDATE()) AS age
FROM gold.dim_customers
WHERE birthdate = (SELECT MIN(birthdate) FROM gold.dim_customers)
UNION ALL
SELECT first_name,
	   last_name,
	   birthdate,
	   DATEDIFF(year, birthdate, GETDATE()) AS age
FROM gold.dim_customers
WHERE birthdate = (SELECT MAX(birthdate) FROM gold.dim_customers);

-- Date range created customer
SELECT MIN(create_date) AS first_create_date, 
	   MAX(create_date) AS last_create_date,
	   DATEDIFF(month, MIN(create_date), MAX(create_date)) AS range_months_create_date
FROM gold.dim_customers;

-- Date range orders
SELECT MIN(order_date) AS first_order, 
	   MAX(order_date) AS last_order,
	   DATEDIFF(year, MIN(order_date), MAX(order_date)) AS range_years_order
FROM gold.fact_sales;

/*
	04 Measure Exploration (Big Numbers)
*/
-- Report of main metrics
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Units Sold' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Product Price' AS measure_name, AVG(cost) AS measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total # Orders' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Unique Products Sold' AS measure_name, COUNT(DISTINCT product_key) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total # Customers' AS measure_name, COUNT(customer_key) AS measure_value FROM gold.dim_customers
UNION ALL
SELECT 'Total Purchasing Customers' AS measure_name, COUNT(DISTINCT customer_key) AS measure_value FROM gold.fact_sales;
	
/*
	05 Magnitude (Group Metrics)
*/
-- Total customers by country
SELECT country, COUNT(*) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Total customers by gender
SELECT gender, COUNT(*) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Total products by category
SELECT category, COUNT(product_key) AS total_customers
FROM gold.dim_products
GROUP BY category
ORDER BY total_customers DESC;

-- Average cost of product category
SELECT category, AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- Total sales by product category
SELECT p.category, SUM(s.sales_amount) AS total_sales
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_products AS p
ON s.product_key = p.product_key
GROUP BY p.category
ORDER BY total_sales DESC;

-- Total sales by customer
SELECT s.customer_key, 
	   c.first_name, 
	   c.last_name,
	   SUM(sales_amount) AS total_sales
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
GROUP BY s.customer_key, c.first_name, c.last_name
ORDER BY total_sales DESC;

-- Total units sold by country
SELECT c.country,
	   SUM(s.quantity) AS total_units_sold
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_units_sold DESC;

/*
	06 Ranking
*/
-- Best top 5 total sales by product
-- Simple Query
SELECT TOP 5
	p.product_name,
	SUM(s.sales_amount) AS total_sales
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_products AS p
ON s.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_sales DESC;

-- Complex, but flexible query
SELECT *
FROM(
	SELECT
		p.product_name,
		SUM(s.sales_amount) AS total_sales,
		RANK() OVER(ORDER BY SUM(s.sales_amount) DESC) AS ranking_products
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	GROUP BY p.product_name
) ranked_products
WHERE ranking_products <= 5;

-- Last top 5 total sales by product
SELECT TOP 5
	p.product_name,
	SUM(s.sales_amount) AS total_sales
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_products AS p
ON s.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_sales ASC;

-- Best top 10 total sales by customer
SELECT TOP 10
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(s.sales_amount) AS total_sales
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_sales DESC;

-- Last top 3 total orders by customer
SELECT TOP 3
	c.customer_key,
	c.first_name,
	c.last_name,
	COUNT(DISTINCT s.order_number) AS total_orders
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_orders ASC;