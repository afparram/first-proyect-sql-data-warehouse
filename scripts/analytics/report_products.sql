/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - average sale per unity
       - lifespan (in months)
    3. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
Usage:
	- Query the gold.report_products, ready for presentations
===============================================================================
*/

IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS
    WITH CTE_base_query AS(
    /*---------------------------------------------
    1) Build base query: retrieves all core columns
    ---------------------------------------------*/
        SELECT
            s.order_number,
            s.customer_key,
            s.order_date,
            s.sales_amount,
            s.quantity,
            p.product_key,
            p.product_name,
            p.category,
            p.subcategory,
            p.cost
        FROM gold.fact_sales AS s
        LEFT JOIN gold.dim_products AS p
        ON s.product_key = p.product_key
        WHERE p.cost > 0 AND order_date IS NOT NULL
    ),
    CTE_aggregations AS (
    /*-------------------------------------------------------------
    2) Product aggregations: Summarizes product's characteristics
    -------------------------------------------------------------*/
        SELECT
            product_key,
            product_name,
            category,
            subcategory,
            cost,
            COUNT(DISTINCT order_number) AS total_orders,
            SUM(sales_amount) AS total_sales,
            SUM(quantity) AS total_quantity,
            ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity,0)), 1) avg_sale_per_unit,
            COUNT(DISTINCT customer_key) AS total_customers,
            MAX(order_date) AS last_order_date,
            DATEDIFF(month, MIN(order_date), MAX(order_date)) AS month_lifespan
        FROM CTE_base_query
        GROUP BY
            product_key,
            product_name,
            category,
            subcategory,
            cost
    )
    /*-------------------------------------------------------------
	3) Final result: segmentations and final transformations
	-------------------------------------------------------------*/
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        total_orders,
        total_sales,
        total_quantity,
        total_customers,
        month_lifespan,
        last_order_date,
        CASE WHEN total_sales < 20000  THEN 'Low'
             WHEN total_sales < 50000 THEN 'Mid'
             ELSE 'High'
        END AS product_performance,
        DATEDIFF(month, last_order_date, GETDATE()) AS month_recency,
        ROUND(CAST(total_sales AS FLOAT) / total_orders, 1) AS avg_order_revenue,
        avg_sale_per_unit,
        CASE WHEN month_lifespan = 0 THEN total_sales
             ELSE ROUND(CAST(total_sales AS FLOAT) / month_lifespan, 1)
        END AS avg_monthly_revenue
    FROM CTE_aggregations
GO

SELECT * FROM gold.report_products;