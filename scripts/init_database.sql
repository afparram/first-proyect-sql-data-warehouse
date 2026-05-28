/*
============================================================
Create Database & Schemas
============================================================
Purpose:
    This script creates the 'FirstDataWarehouse' database using
    a medallion architecture with Bronze, Silver, and Gold schemas
    after checking if it already exists.

WARNING:
    Running this script, the entire 'FirstDataWarehouse' it will be
    permanently dropped along with all its data before being
    recreated. Use with caution in production environments and ensure
    you have backups.
============================================================
*/

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'FirstDataWarehouse')
BEGIN
    PRINT 'Database FirstDataWarehouse already exists. Dropping...';
    ALTER DATABASE FirstDataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FirstDataWarehouse;
    PRINT 'Database dropped successfully.';
END
GO

PRINT 'Creating FirstDataWarehouse database...';
CREATE DATABASE FirstDataWarehouse;
GO

USE FirstDataWarehouse;
GO

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO

PRINT 'Database and schemas created successfully.';
GO