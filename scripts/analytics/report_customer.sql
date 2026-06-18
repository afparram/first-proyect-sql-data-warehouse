/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
	3. Segments customers into categories (VIP, Regular, New) and age groups.
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value (total sales / total orders)
		- average monthly spend (total sales / lifespan)
Usage:
	- Query the gold.report_customers, ready for presentations
===============================================================================
*/


IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

	WITH CTE_base_query AS(
	/*---------------------------------------------
	1) Build base query: retrieves all core columns
	---------------------------------------------*/
		SELECT
			s.order_number,
			s.order_date,
			s.sales_amount,
			s.quantity,
			c.customer_key,
			CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
			DATEDIFF(year, c.birthdate, GETDATE()) AS age,
			s.product_key
		FROM gold.fact_sales AS s
		LEFT JOIN gold.dim_customers AS c
			ON s.customer_key = c.customer_key
		WHERE s.order_date IS NOT NULL
	),
	CTE_aggregations AS(
	/*-------------------------------------------------------------
	2) Customer aggregations: Summarizes customer's characteristics
	-------------------------------------------------------------*/
		SELECT
			customer_key,
			customer_name,
			age,
			COUNT(DISTINCT order_number) AS total_orders,
			SUM(sales_amount) AS total_sales,
			SUM(quantity) AS total_quantity,
			COUNT(DISTINCT product_key) AS total_products,
			MAX(order_date) AS last_order_date,
			DATEDIFF(month, MIN(order_date), MAX(order_date)) AS month_lifespan
		FROM CTE_base_query
		GROUP BY
			customer_key,
			customer_name,
			age
	)

	/*-------------------------------------------------------------
	3) Final result: segmentations and final transformations
	-------------------------------------------------------------*/
	SELECT
		customer_key,
		customer_name,
		age,
		CASE WHEN age < 20 THEN 'Under 20'
				WHEN age < 30 THEN '20-29'
				WHEN age < 40 THEN '30-39'
				WHEN age < 50 THEN '40-49'
				WHEN age >= 50 THEN '50 or above'
				ELSE 'n/a'
		END AS age_group,
		month_lifespan,
		total_sales,
		CASE WHEN COALESCE(month_lifespan, 0) < 12 THEN 'New' -- handling nulls
				WHEN total_sales <= 5000 THEN 'Regular'
				ELSE 'VIP'
		END AS segment_spending,
		total_orders,
		total_quantity,
		total_products,
		last_order_date,
		DATEDIFF(month, last_order_date, GETDATE()) AS month_recency,
		ROUND(CAST(total_sales AS FLOAT) / total_orders, 1) AS avg_order_value,
		CASE WHEN month_lifespan = 0 THEN total_sales
				ELSE ROUND(CAST(total_sales AS FLOAT) / month_lifespan, 1)
		END AS avg_monthly_spend
	FROM CTE_aggregations
GO

-- Usage Example
SELECT * FROM gold.report_customers;