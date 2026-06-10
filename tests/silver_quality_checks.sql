/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs 6 types of data qualities enumerated below:
    - Completeness: Calculated the total available data in each column
    - Conformity / Validity: Checked the data type, format and measure units in each column
    - Precision / Accuracy: The data reflects the reality in each column
    - Consistency: Ensures information remains uniform, coherent, and free from contradiction across between columns
    - Uniqueness / Duplication: Verify duplicated registers
    - Integrity: The keys to join tables have same format and correct information.

Usage Notes:
    - Run these checks before/after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks 
      when replacing 'bronze' with 'silver' keywords in this script.
===============================================================================
*/



/*
=====================
    CRM TABLES
=====================
*/

/*
---------------------
    crm_cust_info
---------------------
*/

    SELECT TOP 100 *
    FROM bronze.crm_cust_info
    ORDER BY cst_key DESC;

SELECT COUNT(*) AS total_rows_cust_info
FROM bronze.crm_cust_info;

/* 
    Completeness
    - 'cst_id' has 0.02% null values.
    - 'cst_firstname' has 0.04% null values.
    - 'cst_lastname' has 0.04% null values.
    - 'cst_gndr' has 24.75% null values.
    - 'cst_create_date' has 0.02% null values.
    The rest columns are complete
*/
SELECT 
    FORMAT(COUNT([cst_id]) * 1.0 / COUNT(*), 'P')                AS [cst_id],
    FORMAT(COUNT([cst_key]) * 1.0 / COUNT(*), 'P')               AS [cst_key],
    FORMAT(COUNT([cst_firstname]) * 1.0 / COUNT(*), 'P')         AS [cst_firstname],
    FORMAT(COUNT([cst_lastname]) * 1.0 / COUNT(*), 'P')          AS [cst_lastname],
    FORMAT(COUNT([cst_marital_status]) * 1.0 / COUNT(*), 'P')    AS [cst_marital_status],
    FORMAT(COUNT([cst_gndr]) * 1.0 / COUNT(*), 'P')              AS [cst_gndr],
    FORMAT(COUNT([cst_create_date]) * 1.0 / COUNT(*), 'P')       AS [cst_create_date]
FROM bronze.crm_cust_info;

/* 
    Conformity / Validity
    - Duplication issues in 'cst_id' and 'cst_key'.
    - 'cst_id' and 'cst_key' left reporting last records, rather than holes between sequence.
    - There are not integer values in customers' name, but it has blank spaces.
    - 'marital_status', 'cust_gndr' and 'cst_create_date' have valid values and follows the same format.
*/ 

-- cst_id duplicates
SELECT
    cst_id,
    COUNT(cst_id) AS duplicated_cst_id
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(cst_id) > 1;

-- cst_key duplicates
SELECT
    cst_key,
    COUNT(cst_key) AS duplicated_cst_key
FROM bronze.crm_cust_info
GROUP BY cst_key
HAVING COUNT(cst_key) > 1;

-- Check sequence data in 'cst_id' and 'cst_key'
SELECT
    MIN(cst_id) OVER() + ROW_NUMBER() OVER(ORDER BY cst_id) - 1 cst_id_expected
INTO #cte_cst_id_seq
FROM bronze.crm_cust_info;

SELECT
    CONCAT('AW000', cst_id_expected) AS cst_key_expected
INTO #cte_cst_key_sequence
FROM #cte_cst_id_seq;

SELECT
    cseq.cst_id_expected AS cst_id_missing
FROM bronze.crm_cust_info AS c
RIGHT JOIN #cte_cst_id_seq AS cseq
ON c.cst_id = cseq.cst_id_expected
WHERE c.cst_id IS NULL
ORDER BY cseq.cst_id_expected DESC;

SELECT
    cseq.cst_key_expected AS cst_key_missing
FROM bronze.crm_cust_info AS c
RIGHT JOIN #cte_cst_key_sequence AS cseq
ON c.cst_key = cseq.cst_key_expected
WHERE c.cst_key IS NULL
ORDER BY cseq.cst_key_expected DESC;

-- Check if there are integer values in customer name
SELECT
    cst_firstname,
    cst_lastname
FROM bronze.crm_cust_info
WHERE cst_firstname LIKE '%[0-9]%' OR
      cst_lastname LIKE '%[0-9]%';

-- Check if there are blank spaces in customer name
SELECT
    cst_id,
    cst_firstname,
    cst_lastname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) OR
      cst_lastname != TRIM(cst_lastname);

-- Check if there are only 2 values in marital_status
SELECT *
FROM bronze.crm_cust_info
WHERE cst_marital_status NOT IN ('S', 'M');

-- Check if there are only 2 values in gender
SELECT *
FROM bronze.crm_cust_info
WHERE cst_gndr NOT IN ('M', 'F');

/* 
    Precision / Accuracy
    - Outlier date: there is a 1900 register
    - It's difficult to check wether social dimension is true without real source data,
      so we're going to assume that are thrusted.
*/
-- outlier dates
SELECT cst_id, cst_create_date
FROM bronze.crm_cust_info
ORDER BY cst_create_date DESC;

SELECT cst_id, cst_create_date
FROM bronze.crm_cust_info
ORDER BY cst_create_date ASC;

/* 
    Consistency
    - It seems that cst_key has the structure 'AW000' + a sequence. However, 4 rows don't follow this rule.
      These 4 rows has empty values in the rest of the columns.
*/

-- Strange registers
SELECT *
FROM bronze.crm_cust_info
WHERE cst_id IS NULL;

/* 
    Uniqueness / Duplication
    - There are not duplicated rows, but as showed above there are duplicated clients in cst_id
*/
SELECT DISTINCT COUNT(*) AS total_unique_rows
FROM bronze.crm_cust_info;

/*
    Integrity
    As shown in the data integration model, this table is one the main integrations.
    There are not other modifications to do in this dimension
*/
SELECT cst_id, cst_key
FROM bronze.crm_cust_info;

/*
---------------------
    crm_prd_info
---------------------
*/

SELECT *, COUNT(*) OVER() AS Total_rows_prd_info
FROM bronze.crm_prd_info;

/* 
    Completeness
    - 'prd_cost' has 0.5% null values.
    - 'prd_line' has 4.28% null values.
    - 'prd_end_dt' has 49.62% null values.
    The rest columns are complete
*/
SELECT 
    FORMAT(COUNT([prd_id]) * 1.0 / COUNT(*), 'P')                AS [prd_id],
    FORMAT(COUNT([prd_key]) * 1.0 / COUNT(*), 'P')               AS [prd_key],
    FORMAT(COUNT([prd_nm]) * 1.0 / COUNT(*), 'P')                AS [prd_nm],
    FORMAT(COUNT([prd_cost]) * 1.0 / COUNT(*), 'P')              AS [prd_cost],
    FORMAT(COUNT([prd_line]) * 1.0 / COUNT(*), 'P')              AS [prd_line],
    FORMAT(COUNT([prd_start_dt]) * 1.0 / COUNT(*), 'P')          AS [prd_start_dt],
    FORMAT(COUNT([prd_end_dt]) * 1.0 / COUNT(*), 'P')            AS [prd_end_dt]
FROM bronze.[crm_prd_info];

/*
    Conformity / Validity
    - 'prd_id' has unique values.
    - 'prd_key' looks like the foreign key.
    - 'prd_line' seems to have correct format.
    - 'prd_cost' is non-negative.
*/

SELECT COUNT(prd_id) AS duplicated_prd_id
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(prd_id) > 1;

SELECT COUNT(prd_key) AS duplicated_prd_key
FROM bronze.crm_prd_info
GROUP BY prd_key
HAVING COUNT(prd_key) > 1;

SELECT prd_key
FROM bronze.crm_prd_info
WHERE prd_key != TRIM(prd_key);

SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

SELECT prd_line, COUNT(prd_line) AS observations
FROM bronze.crm_prd_info
GROUP BY prd_line;

SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost <= 0;

/*
    Precision / Accuracy
    - The cost variable is positive skewed (heavy tail to the right) and has a big standard deviation.
    - The oldest product start date is an extreme value because there is a 8 years gap with the next date. 
      Discuss wetherer this value is correct.
    - It is important to check to the respect department wetherer a 'prd_end_dt' is null or not. Besides,
      how to handle this null values for presentation.
*/
SELECT TOP 1
    MIN(prd_cost) OVER() AS min_cost,
    AVG(prd_cost) OVER() AS avg_cost,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY prd_cost) OVER() AS median_cost,
    STDEV(prd_cost) OVER() AS std_cost,
    MAX(prd_cost) OVER() AS max_cost
FROM bronze.crm_prd_info;

SELECT prd_start_dt
FROM bronze.crm_prd_info
ORDER BY prd_start_dt;

SELECT prd_end_dt
FROM bronze.crm_prd_info
ORDER BY prd_end_dt DESC;

/*
    Consistency
    - It is strange that the starting date is greater than the end date.
    - It looks that 'prd_nm' has repetead products because some finished 
      and then started producing it again, probably changing the 'prd_cost'.
    - prd_line atributtes may mean the follow:
      * M : Mountain
      * R : Road
      * S : Sports
      * T : Touring
      However, I don't think 'Bike Wash - Dissolver' is part of sports line,
      it is necesary to check wetherer this or other information are in the correct
      production line.
*/
SELECT prd_start_dt, prd_end_dt
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

SELECT prd_nm, COUNT(prd_nm) as total_prd_name
FROM bronze.crm_prd_info
WHERE prd_line = 'M'
GROUP BY prd_nm
ORDER BY prd_nm;

SELECT prd_nm, COUNT(prd_nm) as total_prd_name
FROM bronze.crm_prd_info
WHERE prd_line = 'R'
GROUP BY prd_nm
ORDER BY prd_nm;

SELECT prd_nm, COUNT(prd_nm) as total_prd_name
FROM bronze.crm_prd_info
WHERE prd_line = 'S'
GROUP BY prd_nm
ORDER BY prd_nm;

SELECT prd_nm, COUNT(prd_nm) as total_prd_name
FROM bronze.crm_prd_info
WHERE prd_line = 'T'
GROUP BY prd_nm
ORDER BY prd_nm;

/*
    Uniqueness / Duplication
    - There are not repetied rows as showed above in prd_id and using DISTINCT 
*/
SELECT DISTINCT COUNT(*) AS total_unique_rows
FROM bronze.crm_prd_info

/*
    Integrity
    As shown in the data integration model, this table is one the main integrations.
    It is necesary to split the foreign key into 'prd_cat_id' and 'prd_key'
*/
SELECT prd_key
FROM bronze.crm_prd_info


/*
---------------------
    crm_crm_sales_details
---------------------
*/
SELECT TOP 1000 *, COUNT(sls_ord_num) OVER() AS total_rows_sales_details
FROM bronze.crm_sales_details;

/*
    Completeness
    - 'sls_sales' has 0.01% null values.
    - 'sls_price' has 0.01% null values.
    The rest columns are complete
*/
SELECT 
    FORMAT(COUNT([sls_ord_num]) * 1.0 / COUNT(*), 'P')          AS [sls_ord_num],
    FORMAT(COUNT([sls_cust_id]) * 1.0 / COUNT(*), 'P')          AS [sls_cust_id],
    FORMAT(COUNT([sls_order_dt]) * 1.0 / COUNT(*), 'P')         AS [sls_order_dt],
    FORMAT(COUNT([sls_ship_dt]) * 1.0 / COUNT(*), 'P')          AS [sls_ship_dt],
    FORMAT(COUNT([sls_due_dt]) * 1.0 / COUNT(*), 'P')           AS [sls_due_dt],
    FORMAT(COUNT([sls_sales]) * 1.0 / COUNT(*), 'P')            AS [sls_sales],
    FORMAT(COUNT([sls_quantity]) * 1.0 / COUNT(*), 'P')         AS [sls_quantity],
    FORMAT(COUNT([sls_price]) * 1.0 / COUNT(*), 'P')            AS [sls_price]
FROM bronze.crm_sales_details;


/*
    Conformity / Validity
    - It seems there are multiple purchases in the same sale because of duplicated sales order number.
      See uniqueness dimension if there are problems.
    - The date style of the date variable is 112 (yyyymmdd). 
      However, the 'sls_order_dt' has some format errors
    - Problems of non negative in some sales and price values
*/
-- Checking sls_ord_num format
SELECT
    COUNT(sls_ord_num) AS valid_sls_ord_num,
    COUNT(DISTINCT sls_ord_num) AS unique_sls_ord_num
FROM bronze.crm_sales_details;

SELECT sls_ord_num
FROM bronze.crm_sales_details
WHERE LEFT(sls_ord_num, 2) NOT LIKE 'SO';

-- Checking if the date variables could be transformed to date type
SELECT 
    COUNT(*) AS total_rows,
    COUNT(ISDATE(sls_order_dt)) AS valid_sls_order_dt,
    COUNT(ISDATE(sls_ship_dt)) AS valid_sls_ship_dt, 
    COUNT(ISDATE(sls_due_dt)) AS valid_sls_due_dt
FROM bronze.crm_sales_details;

SELECT *
FROM(
    SELECT
        sls_order_dt AS normal_sls_order_dt,
        TRY_CONVERT(DATE, CAST(sls_order_dt AS NVARCHAR), 112) AS sls_order_dt,
        TRY_CONVERT(DATE, CAST(sls_ship_dt AS NVARCHAR), 112) AS sls_ship_dt,
        TRY_CONVERT(DATE, CAST(sls_due_dt AS NVARCHAR), 112) AS sls_due_dt
    FROM bronze.crm_sales_details
) AS t
WHERE sls_order_dt IS NULL
      OR sls_ship_dt IS NULL
      OR sls_due_dt IS NULL;

-- Non-negative sales, quantity and price
SELECT sls_ord_num, sls_sales, sls_quantity, sls_price
FROM bronze.crm_sales_details
WHERE sls_sales <= 0 OR
      sls_price <= 0 OR
      sls_quantity <= 0;

/*
    Precision / Accuracy
    - It is a suprise that only 11 rows that register a quantity greather than 1.
*/

SELECT
    MIN(sls_quantity) AS min_sls_quantity,
    AVG(sls_quantity) AS max_sls_quantity,
    STDEV(sls_quantity) AS std_sls_quantity,
    MAX(sls_quantity) AS max_sls_quantity
FROM bronze.crm_sales_details;

SELECT COUNT(sls_quantity) AS greater_one_quantity
FROM bronze.crm_sales_details
WHERE sls_quantity > 1;

/*
    Consistency
    - It is likely that null 'sls_price' values are related with 'sls_quantity' greather than 1
    - There are not inconsistencies in the date time variables because follows the chronologycal order:
      'sls_order_dt' <= 'sls_ship_dt' <= 'sls_due_dt'.
    - When sales and price are different, either have opposite sign
      or one is greater than the other.
    - Also, it is not clear what is the difference between the column sales and price
*/

-- nulls sls_price & sls_quantity
SELECT *
FROM bronze.crm_sales_details
WHERE sls_price IS NULL;

SELECT *
FROM bronze.crm_sales_details
WHERE sls_quantity > 1
ORDER BY sls_quantity DESC;

-- correct order date variables
SELECT sls_order_dt, sls_ship_dt, sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR
      sls_order_dt > sls_due_dt  OR
      sls_ship_dt > sls_due_dt;

-- check when sls_sales is different from sls_price
SELECT *
FROM bronze.crm_sales_details
WHERE sls_sales != sls_price;

/*
    Uniqueness / Duplication
    - There are not duplicated registers.
*/
SELECT DISTINCT COUNT(*) total_unique_rows
FROM bronze.crm_sales_details;

/*
    Integrity
    There not problems with the foreign keys
*/
SELECT sls_cust_id, sls_prd_key
FROM bronze.crm_sales_details


/*
==================
    ERP TABLES
==================
*/

/*
---------------------
    erp_cust_az12
---------------------
*/
SELECT TOP 1000 *, COUNT(*) OVER() AS total_rows_cust_az12
FROM bronze.erp_cust_az12;

/*
    completeness
    - 'gen' has 7.96% null values.
    The rest columns are complete
*/
SELECT 
    FORMAT(COUNT(cid) * 1.0 / COUNT(*), 'P')          AS cid,
    FORMAT(COUNT(bdate) * 1.0 / COUNT(*), 'P')          AS bdate,
    FORMAT(COUNT(gen) * 1.0 / COUNT(*), 'P')         AS gen
FROM bronze.erp_cust_az12;

/*
    Conformity / Validity
    - It looks that there is two standard identifiers in 'cid': 
      the prefixes 'NASAW000' and 'AW000' followed by a
      unique sequence number.
    - It was found ambiguous format (n=9) and empty values (n=4) in 'gen' variable.
    - 'Bdate' wasn't check because was declared as DATE and there are not NULLs.
*/
SELECT cid
FROM bronze.erp_cust_az12
WHERE cid NOT LIKE 'NASA%'
      AND cid NOT LIKE 'AW%';

SELECT COUNT(cid) AS valid_cid, COUNT(DISTINCT cid) AS unique_cid
FROM bronze.erp_cust_az12;

SELECT DISTINCT gen
FROM bronze.erp_cust_az12;

SELECT COUNT(gen) AS total_empty_gen
FROM bronze.erp_cust_az12
WHERE gen = '';

SELECT COUNT(gen) AS total_ambiguous_gen
FROM bronze.erp_cust_az12
WHERE gen = 'F' OR gen = 'M';

/*
    Precision / Accuracy
      - It seems that some customers are really old, 
      probably the company had worked many years.
      However, there is a gap of 50+ years between
      the majority of the customers and a small portion.
      Assuming that we are in 2026, these years lie in the future
      and therefore considered as errors
*/

-- Check birthday variable
SELECT TOP 100 bdate
FROM bronze.erp_cust_az12
ORDER BY bdate;

SELECT TOP 100 bdate
FROM bronze.erp_cust_az12
ORDER BY bdate DESC;

/*
    Consistency
    - Not problems has found in this quality dimension
*/

/*
    Uniqueness
    - There are not duplicated rows as showed above with cid and below DISTINCT
*/
SELECT DISTINCT COUNT(*) total_unique_rows
FROM bronze.erp_cust_az12;

/*
    Integrity
    The current pk stored in the crm_cust_info starts with 'AW' not 'NAS'.
    It is necessary to standarize this foreign key with 'AW'.
*/
SELECT cid
FROM bronze.erp_cust_az12


/*
---------------------
    erp_loc_a101
---------------------
*/
SELECT TOP 1000 *, COUNT(*) OVER() AS total_rows_loc_a101
FROM bronze.erp_loc_a101;

/*
    Completeness
    - 'cntry' has 1.8% null values.
    The rest columns are complete
*/
SELECT 
    FORMAT(COUNT(cid) * 1.0 / COUNT(*), 'P')          AS cid,
    FORMAT(COUNT(cntry) * 1.0 / COUNT(*), 'P')          AS cntry
FROM bronze.erp_loc_a101;

/*
    Conformity / Validity
    - cid is valid to be converting as primary key
    - Ambiguous format in USA-US-United States and DE-Germany.
      Besides, there are 5 empty values.
*/
-- Checking cid variable
SELECT cid, COUNT(cid) AS duplicated_cid
FROM bronze.erp_loc_a101
GROUP BY cid
HAVING COUNT(cid) > 1;

SELECT cid
FROM bronze.erp_loc_a101
WHERE cid NOT LIKE 'AW%';

-- Checking cntry
SELECT cntry, COUNT(cntry) AS observations
FROM bronze.erp_loc_a101
GROUP BY cntry;

/*
    Precision / Accuracy
    - The countries exist in the real life, but we assume each client
      has the correct location. It is important to compare with real data
*/

/*
    Consistency
    - This quality dimension cannot be perfomed with only one information variable.
*/

/*
    Uniqueness / Duplication
    - Above has checked 'cid' is unique, so the rows are unique.
*/

/*
    Integrity
    There is a symbol '-' in the format of the foreign key
    that doesn't appear in the crm_cust_info. Therefore, remove it
*/
SELECT cid
FROM bronze.erp_loc_a101

/*
---------------------
    erp_px_cat_g1v2
---------------------
*/
SELECT TOP 1000 *, COUNT(*) OVER() AS total_rows_px_cat_g1v2
FROM bronze.erp_px_cat_g1v2;

/*
    Completeness
    - All columns are complete
*/
SELECT 
    FORMAT(COUNT(id) * 1.0 / COUNT(*), 'P')          AS id,
    FORMAT(COUNT(cat) * 1.0 / COUNT(*), 'P')          AS cat,
    FORMAT(COUNT(subcat) * 1.0 / COUNT(*), 'P')          AS subcat,
    FORMAT(COUNT(maintenance) * 1.0 / COUNT(*), 'P')          AS maintenance
FROM bronze.erp_px_cat_g1v2;

/*
    Conformity / Validity
    - 'id' is valid to be converting as primary key
    - There are not ambiguity in 'cat' variable. 
    - Each subcat is unique, confirming its definition
    - The values in 'maintenance' are valid.
*/
-- Checking id variable
SELECT id, COUNT(id) AS duplicated_id
FROM bronze.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(id) > 1;

SELECT id
FROM bronze.erp_px_cat_g1v2
GROUP BY id;

-- Checking cat
SELECT cat, COUNT(cat) AS observations
FROM bronze.erp_px_cat_g1v2
GROUP BY cat;

-- Checking subcat
SELECT subcat, COUNT(subcat) AS observations
FROM bronze.erp_px_cat_g1v2
GROUP BY subcat;

-- Checking maintenance
SELECT maintenance, COUNT(maintenance) AS observations
FROM bronze.erp_px_cat_g1v2
GROUP BY maintenance;

/*
    Precision / Accuracy
    - It seems that all categories and subcategories exist in real life,
      but it is important to check with the assigned department wetherer
      which one are errors or don't exist in the company
*/

/*
    Consistency
    - It looks that the subcategories belongs to the respective category,
      without discrepancies in real life.
*/

/*
    Uniqueness / Duplication
    - Above has checked 'id' is unique, so the rows are unique.
*/

/*
    Integrity
    Instead of the symbol '-' there is a underscore '_'
*/
SELECT id
FROM bronze.erp_px_cat_g1v2
