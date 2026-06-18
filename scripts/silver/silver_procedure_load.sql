/*
============================================================
Silver Tables Ingestion with Stored Procedure
============================================================
Purpose:
	This script create a Stored Procedure that loads external .csv
	files into all silver tables using FULL LOAD strategy.
	For each table, it truncates existing data and then
	refilled with `BULK INSERT`.

	Execution time is measured and printed per
	table and for the overall procedure.

Parametrs:
	None.
Returns:
	None.
============================================================
*/

-- Following the naming convention for stored procedures
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME

	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT('========================');
		PRINT('Loading silver Layer');
		PRINT('========================');

		PRINT('------------------------');
		PRINT('Loading CRM Tables');
		PRINT('------------------------');

		PRINT('>> Truncanting Table: silver.crm_cust_info');
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_cust_info;

		PRINT('>> Inserting Data Into Table: silver.crm_cust_info');
		-- Remove unwanted spaces, data normalization, flag duplicates and drop null id
		WITH CTE_crm_cust_info_clean AS(
			SELECT
				cst_id,
				cst_key,
				TRIM(cst_firstname) AS cst_firstname,
				TRIM(cst_lastname) AS cst_lastname,
				UPPER(TRIM(cst_marital_status)) AS cst_marital_status,
				UPPER(TRIM(cst_gndr)) AS cst_gndr,
				cst_create_date,
				ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last_cst_id
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		)
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		/*
			Business rules
			* Select only updated id records
			* Capitilize customer name
			* Data normalization marital status and gender
		*/
		SELECT
			cst_id,
			cst_key,
			CASE
				WHEN cst_firstname = '' OR cst_firstname IS NULL THEN 'n/a'
				ELSE CONCAT(UPPER(LEFT(cst_firstname, 1)), LOWER(SUBSTRING(cst_firstname, 2)))
			END AS cst_firstname,
			CASE
				WHEN cst_lastname = '' OR cst_lastname IS NULL THEN 'n/a'
				ELSE CONCAT(UPPER(LEFT(cst_lastname, 1)), LOWER(SUBSTRING(cst_lastname, 2)))
			END AS cst_lastname,
			CASE cst_marital_status
				WHEN 'S' THEN 'Single'
				WHEN 'M' THEN 'Married'
				ELSE 'n/a'
			END AS cst_marital_status,
			CASE cst_gndr
				WHEN 'F' THEN 'Female'
				WHEN 'M' THEN 'Male'
				ELSE 'n/a'
			END AS cst_gndr,
			CASE 
				WHEN cst_create_date IS NULL THEN 'n/a'
				ELSE cst_create_date
			END AS cst_lastname
		FROM CTE_crm_cust_info_clean
		WHERE flag_last_cst_id = 1;

		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('>> Truncanting Table: silver.crm_prd_info');
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_prd_info

		PRINT('>> Inserting Data Into Table: silver.crm_prd_info');
		/* 
			* Derived columns category product and product key
			* Handling null product cost with 0
			* Data normalization product line
			* Data enrichment production end date using the next production start date
		*/
		INSERT INTO silver.crm_prd_info(
			prd_id,      
			prd_cat_id,  
			prd_key,     
			prd_nm,      
			prd_cost,    
			prd_line,    
			prd_start_dt,
			prd_end_dt
		)
		SELECT
			prd_id,
			LEFT(prd_key, 5) AS prd_cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
			prd_nm,
			ISNULL(prd_cost,0)
			prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'M' THEN 'Mountain'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line,
			prd_start_dt,
			DATEADD(DAY, -1, LEAD(prd_start_dt, 1) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt	
		FROM bronze.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('>> Truncanting Table: silver.crm_sales_details');
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_sales_details;

		PRINT('>> Inserting Data Into Table: silver.crm_sales_details');
		/*
			Data casting and handling invalid dates
			Business logic Sales = Quantity * Price
		*/
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,      
			sls_ship_dt,    
			sls_due_dt,    
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE WHEN LEN(sls_order_dt) = 8 THEN CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
				 ELSE NULL
			END AS sls_order_dt,
			CASE WHEN LEN(sls_ship_dt) = 8 THEN CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
				 ELSE NULL
			END AS sls_ship_dt,
			CASE WHEN LEN(sls_due_dt) = 8 THEN CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
				 ELSE NULL
			END AS sls_due_dt,
			CASE WHEN (sls_price IS NOT NULL) AND (sls_sales != sls_quantity * ABS(sls_price) OR sls_sales IS NULL) THEN sls_quantity * ABS(sls_price)
			ELSE ABS(sls_sales)
			END AS sls_sales,
			sls_quantity,
			CASE WHEN sls_price IS NULL THEN sls_sales / NULLIF(sls_quantity, 0)
			ELSE ABS(sls_price)
			END AS sls_price
		FROM bronze.crm_sales_details
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('------------------------');
		PRINT('Loading ERM Tables');
		PRINT('------------------------');

		PRINT('>> Truncanting Table: silver.erp_cust_az12');
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.erp_cust_az12;

		PRINT('>> Inserting Data Into Table: silver.erp_cust_az12');
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		/*
			Use one single cid format
			Assign null in invalid birth dates
			Normalization and handling invalid values in gender
		*/
		SELECT
			RIGHT(cid, 10) cid,
			CASE WHEN bdate > GETDATE() THEN NULL
			ELSE bdate
			END AS bdate,
			CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				 ELSE 'n/a'
			END AS gen
		FROM bronze.erp_cust_az12
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('>> Truncanting Table: silver.erp_loc_a101');
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.erp_loc_a101

		PRINT('>> Inserting Data Into Table: silver.erp_loc_a101');
		/*
			Change format cid
			Normalization and handling invalid values in country
		*/
		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)
		SELECT 
			REPLACE(cid, '-', '') AS cid, 
			CASE 
				WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
				WHEN UPPER(TRIM(cntry)) IN ('USA', 'US') THEN 'United States'
				WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
				ELSE TRIM(cntry)
			END AS cntry
		FROM bronze.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('>> Truncanting Table: silver.erp_px_cat_g1v2');
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.erp_px_cat_g1v2

		PRINT('>> Inserting Data Into Table: silver.erp_px_cat_g1v2');
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			REPLACE(id, '_', '-') AS id,
			TRIM(cat),
			TRIM(subcat),
			TRIM(maintenance)
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')

		SET @batch_end_time = GETDATE()
		PRINT('===========================')
		PRINT('Load silver Layer Completed')
		PRINT(N'⏱ Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds')
		PRINT('===========================')
	END TRY

	BEGIN CATCH
		PRINT('==========================================');
		PRINT('ERROR OCURRED DURING LOADING silver LOAD');
		PRINT('------------------------------------------');
		PRINT('Error message: ' + ERROR_MESSAGE());
		PRINT('Error number: ' + CAST(ERROR_NUMBER() AS NVARCHAR));
		PRINT('Error line: ' + CAST(ERROR_LINE() AS NVARCHAR));
		PRINT('Error procedure: ' + ERROR_PROCEDURE());
		PRINT('==========================================');
	END CATCH
END
GO

-- Usage Example:
EXEC silver.load_silver;