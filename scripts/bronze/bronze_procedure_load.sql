/*
============================================================
Bronze Tables Ingestion with Stored Procedure
============================================================
Purpose:
	This script create a Stored Procedure that loads external .csv
	files into all Bronze tables using FULL LOAD strategy.
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
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	DECLARE @BasePath NVARCHAR(500) = 'C:\Users\...';
	DECLARE @SQL NVARCHAR(MAX);

	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT('========================');
		PRINT('Loading Bronze Layer');
		PRINT('========================');

		PRINT('------------------------');
		PRINT('Loading CRM Tables');
		PRINT('------------------------');

		PRINT('>> Truncanting Table: bronze.crm_cust_info');
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT('>> Inserting Data Into Table: bronze.crm_cust_info');
		SET @SQL = N'BULK INSERT bronze.crm_cust_info FROM '''
        + @BasePath + '\first-proyect-sql-data-warehouse\datasets\source_crm\cust_info.csv'
        + ''' WITH (FIRSTROW=2, FIELDTERMINATOR='','', TABLOCK);';
		EXEC sp_executesql @SQL;
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('>> Truncanting Table: bronze.crm_prd_info');
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_prd_info

		PRINT('>> Inserting Data Into Table: bronze.crm_prd_info');
		SET @SQL = N'BULK INSERT bronze.crm_prd_info FROM '''
        + @BasePath + '\first-proyect-sql-data-warehouse\datasets\source_crm\prd_info.csv'
        + ''' WITH (FIRSTROW=2, FIELDTERMINATOR='','', TABLOCK);';
		EXEC sp_executesql @SQL;
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('>> Truncanting Table: bronze.crm_sales_details');
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT('>> Inserting Data Into Table: bronze.crm_sales_details');
		SET @SQL = N'BULK INSERT bronze.crm_sales_details FROM '''
        + @BasePath + '\first-proyect-sql-data-warehouse\datasets\source_crm\sales_details.csv'
        + ''' WITH (FIRSTROW=2, FIELDTERMINATOR='','', TABLOCK);';
		EXEC sp_executesql @SQL;
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('------------------------');
		PRINT('Loading ERM Tables');
		PRINT('------------------------');

		PRINT('>> Truncanting Table: bronze.erp_cust_az12');
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT('>> Inserting Data Into Table: bronze.erp_cust_az12');
		SET @SQL = N'BULK INSERT bronze.erp_cust_az12 FROM '''
        + @BasePath + '\first-proyect-sql-data-warehouse\datasets\source_erp\cust_az12.csv'
        + ''' WITH (FIRSTROW=2, FIELDTERMINATOR='','', TABLOCK);';
		EXEC sp_executesql @SQL;
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('>> Truncanting Table: bronze.erp_loc_a101');
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_loc_a101

		PRINT('>> Inserting Data Into Table: bronze.erp_loc_a101');
		SET @SQL = N'BULK INSERT bronze.erp_loc_a101 FROM '''
        + @BasePath + '\first-proyect-sql-data-warehouse\datasets\source_erp\loc_a101.csv'
        + ''' WITH (FIRSTROW=2, FIELDTERMINATOR='','', TABLOCK);';
		EXEC sp_executesql @SQL;
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')


		PRINT('>> Truncanting Table: bronze.erp_px_cat_g1v2');
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_px_cat_g1v2

		PRINT('>> Inserting Data Into Table: bronze.erp_px_cat_g1v2');
		SET @SQL = N'BULK INSERT bronze.erp_px_cat_g1v2 FROM '''
        + @BasePath + '\first-proyect-sql-data-warehouse\datasets\source_erp\px_cat_g1v2.csv'
        + ''' WITH (FIRSTROW=2, FIELDTERMINATOR='','', TABLOCK);';
		EXEC sp_executesql @SQL;
		SET @end_time = GETDATE();
		PRINT(N'⏱ Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('')

		SET @batch_end_time = GETDATE()
		PRINT('===========================')
		PRINT('Load Bronze Layer Completed')
		PRINT(N'⏱ Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds')
		PRINT('===========================')
	END TRY

	BEGIN CATCH
		PRINT('==========================================');
		PRINT('ERROR OCURRED DURING LOADING BRONZE LOAD');
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
EXEC bronze.load_bronze;