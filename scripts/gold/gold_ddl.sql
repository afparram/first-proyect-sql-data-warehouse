/*
============================================================
Creating gold views using DDL Statements
============================================================
Purpose:
    This script builds the Gold Layer in the data warehouse 
	by combining data from Silver Layer into three views (Star schema).

	Each existing view is dropped, then dimension views of customer 
	and product information are collected and joined with the fact view
	of the transactional sales history. Only currently produtcs in 
	production are included.

Usage:
    - These views can be queried directly for analytics and reporting.
============================================================
*/


PRINT('========================');
PRINT('Loading Gold Layer');
PRINT('========================');

PRINT('>> Droping View: gold.dim_customers');
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;

PRINT('>> Creating View: gold.dim_customers');
GO
CREATE VIEW gold.dim_customers AS(
	SELECT
		ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key, -- Surrogate key
		ci.cst_id AS customer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
		cloc.cntry AS country,
		ci.cst_marital_status AS marital_status,
		CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is first priority for gender
			ELSE COALESCE(cbd.gen, 'n/a')				-- Use ERP otherwise
		END AS gender,
		cbd.bdate AS birthdate,
		ci.cst_create_date AS create_date
	FROM silver.crm_cust_info AS ci
	LEFT JOIN silver.erp_cust_az12 AS cbd
	ON ci.cst_key = cbd.cid
	LEFT JOIN silver.erp_loc_a101 AS cloc
	ON ci.cst_key = cloc.cid
);
GO


PRINT('>> Droping View: gold.dim_products');
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;

PRINT('>> Creating View: gold.dim_customers');
GO

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_id) AS product_key, -- Surrogate key
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.prd_cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
ON pn.prd_cat_id = pc.id
WHERE prd_end_dt IS NULL;			-- Only products currently in production
GO

PRINT('>> Droping View: gold.fact_sales');
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;

PRINT('>> Creating View: gold.dim_customers');
GO

CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num AS order_number,
	p.product_key,
	c.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_customers AS c
ON sd.sls_cust_id = c.customer_id
LEFT JOIN gold.dim_products AS p
ON sd.sls_prd_key = p.product_number;
GO