/*
===============================================================================
Quality Checks
===============================================================================
Purpose:
    This script validates the integrity of the Gold layer before
    it is used for analytics and reporting. Checks run at two levels: against
    the underlying Silver layer joins to detect issues before they reach the
    views, and directly against the Gold views.

Usage Notes:
    Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

/*
-----------------------
    dim_customers
-----------------------
*/
-- Check for duplicates when joining customer, birthdate, and country tables
SELECT cst_id, COUNT(*) AS totalcustomer
FROM (
	SELECT
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gndr,
		ci.cst_create_date,
		cbd.bdate,
		cbd.gen,
		cloc.cntry
	FROM silver.crm_cust_info AS ci
	LEFT JOIN silver.erp_cust_az12 AS cbd
	ON ci.cst_key = cbd.cid
	LEFT JOIN silver.erp_loc_a101 AS cloc
	ON ci.cst_key = cloc.cid
) AS t
GROUP BY cst_id
HAVING COUNT(cst_id) > 1;


-- Validate gender consolidation logic across CRM and ERP sources
-- NULL values in the result indicate records with no join match
SELECT DISTINCT
	ci.cst_gndr,
	cbd.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		 ELSE COALESCE(cbd.gen, 'n/a')
	END AS new_gndr
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS cbd
	ON ci.cst_key = cbd.cid
ORDER BY 1,2;

SELECT * FROM gold.dim_customers;

SELECT customer_key, COUNT(*) AS total_observations
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

/*
-----------------------
    dim_products
-----------------------
*/
-- Check for duplicates when joining product and category tables
SELECT prd_key, COUNT(*) AS totalproducts 
FROM (
	SELECT
		pn.prd_id,
		pn.prd_cat_id,
		pn.prd_key,
		pn.prd_nm,
		pn.prd_cost,
		pn.prd_line,
		pn.prd_start_dt,
		pc.cat,
		pc.subcat,
		pc.maintenance
	FROM silver.crm_prd_info AS pn
	LEFT JOIN silver.erp_px_cat_g1v2 AS pc
	ON pn.prd_cat_id = pc.id
	WHERE prd_end_dt IS NULL
) AS t
GROUP BY prd_key
HAVING COUNT(*) > 1;

SELECT * FROM gold.dim_products;

SELECT product_key, COUNT(*) AS total_observations
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

/*
-----------------------
    fact_sales
-----------------------
*/
 
-- Check referential integrity: full matching records
SELECT * FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
	ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products AS p
	ON f.product_key = p.product_key
WHERE c.customer_id IS NULL 
	OR p.product_key IS NULL;