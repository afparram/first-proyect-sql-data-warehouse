/*===============================================================
	Advance Analytics
Purpose:
    This script performs multiple advance analytic process
	in the Gold layer to get deep insights in the sales, 
	customers and products areas.
	

Usage Notes:
    Results are intended to guide analytical and report 
	design decisions, not for direct business consumption.
=================================================================*/

/*
	Change-Over-Time Trends
*/
-- Simple query
SELECT 
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;

-- Robust query
SELECT 
	DATETRUNC(month, order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY order_date;

-- This approach is not good because transforms the 
-- date in string, changing the chronological order
SELECT 
	FORMAT(order_date, 'yyyy-MMM') AS order_date,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY order_date;

/*
	Cumulative analysis
*/
-- Total sales per month and running total of sales over time
SELECT
	*,
	SUM(total_sales) OVER(ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER(ORDER BY order_date) AS moving_avg_price
FROM(
	SELECT 
		DATETRUNC(month, order_date) AS order_date,
		SUM(sales_amount) AS total_sales,
		AVG(price) AS avg_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
) sales_month

/*
	Performance Analysis
*/
-- Yearly perfomance of products by comparing each product's sales
-- to both its average total sales and the previous year's sales
WITH CTE_year_product_sales AS(
	SELECT
		YEAR(s.order_date) AS order_year,
		p.product_name,
		SUM(s.sales_amount) AS current_total_sales
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(s.order_date), p.product_name
),
CTE_avg_total_sales AS(
	SELECT *,
		AVG(current_total_sales) OVER(PARTITION BY product_name) AS avg_total_sales,
		LAG(current_total_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS lag_total_sales
	FROM CTE_year_product_sales
)

SELECT
	order_year,
	product_name,
	current_total_sales,
	avg_total_sales,
	current_total_sales - avg_total_sales AS diff_avg,
	CASE WHEN current_total_sales - avg_total_sales > 0 THEN 'Above Average'
		 WHEN current_total_sales - avg_total_sales < 0 THEN 'Below Average'
		 ELSE 'Same'
		 END AS change_avg,
	lag_total_sales,
	current_total_sales - lag_total_sales AS diff_lag,
	CASE WHEN current_total_sales - lag_total_sales > 0 THEN 'Increase'
		WHEN current_total_sales - lag_total_sales < 0 THEN 'Decrease'
		ELSE 'No change'
		END AS change_lag
FROM CTE_avg_total_sales;

/*
	Part-to-Whole 
*/
-- Proportion of categories that contribute the overall sales
WITH CTE_category_sales AS(
	SELECT 
		p.category,
		SUM(s.sales_amount) AS total_sales
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	GROUP BY p.category
)

SELECT
	category,
	total_sales,
	FORMAT(CAST(total_sales AS FLOAT) / SUM(total_sales) OVER(), 'P') AS perc_proportion
FROM CTE_category_sales
ORDER BY total_sales DESC;

-- Proportion of countries that contribute the overall sales
WITH CTE_country_sales AS(
	SELECT 
		c.country,
		SUM(s.sales_amount) AS total_sales,
		SUM(s.quantity) AS total_units_sold
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_customers AS c
	ON s.customer_key = c.customer_key
	GROUP BY c.country
)

SELECT
	country,
	total_sales,
	FORMAT(CAST(total_sales AS FLOAT) / SUM(total_sales) OVER(), 'P') AS perc_proportion_sales,
	total_units_sold,
	FORMAT(CAST(total_units_sold AS FLOAT) / SUM(total_units_sold) OVER(), 'P') AS perc_proportion_units
FROM CTE_country_sales
ORDER BY total_sales DESC;


/*
	Data Segmentation
*/
-- Segment products into cost ranges and count how many products fall into each segment
WITH CTE_segment_cost AS(
	SELECT
		product_key,
		product_name,
		cost,
		CASE WHEN cost < 100 THEN 'Below 100'
			 WHEN cost < 500 THEN '100-500'
			 WHEN cost < 1000 THEN '500-1000'
			 ELSE 'Above 1000'
		END AS cost_range
	FROM gold.dim_products
	WHERE cost != 0
)
SELECT
	cost_range,
	COUNT(product_key) AS total_products
FROM CTE_segment_cost
GROUP BY cost_range
ORDER BY total_products DESC;


/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
NOTE: use the last order date reported as end date
*/
WITH CTE_segment_spending AS (
	SELECT
		customer_key,
		DATEDIFF(month, MIN(order_date), MAX(order_date)) AS month_lifespan,
		SUM(sales_amount) AS total_spent,
		CASE WHEN COALESCE(DATEDIFF(month, MIN(order_date), MAX(order_date)), 0) < 12 THEN 'New' -- handling nulls
				WHEN SUM(sales_amount) <= 5000 THEN 'Regular'
				ELSE 'VIP'
		END AS segment_spending
	FROM gold.fact_sales
	GROUP BY customer_key
)

SELECT
	segment_spending,
	COUNT(*) AS total_customers
FROM CTE_segment_spending
GROUP BY segment_spending
ORDER BY total_customers DESC;