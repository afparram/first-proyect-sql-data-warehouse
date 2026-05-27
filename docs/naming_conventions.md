# **Naming Conventions**

This document outlines the naming conventions used for schemas, tables, views, columns, and other obejcts in the data warehouse

## **Table of Contents**

1. [General Principles](#general-principles)
2. [Table Naming Conventions](#table-naming-conventions)
   - [Bronze Layer](#bronze-layer)
   - [Silver Layer](#silver-layer)
   - [Gold Layer](#gold-layer)
3. [Column Naming Conventions](#column-naming-conventions)
   - [Surrogate Keys](#surrogate-keys)
   - [Technical Columns](#technical-columns)
4. [Stored Procedure](#stored-procedure-naming-conventions)


## **General Principles**
- **Naming conventions:** Use the snake_case, i.e., with undercase letters and underscore as separator (`_`).
- **Languages:** Employ mainly english for all names.
- **Avoided Reserved Words:** Do not use SQL reserved words as naming objects.

## **Table Naming Conventions**
### **Bronze Layer**
- All names must start with the source system name, and tables names must match the original names without renaming.

- Take the general configuration **`<sourcesystem_entity>`** where:
   - `<sourcesystem>`: Name of the source system (e.g. crm, erp).
   - `<entity>`: Exact table name from the source system
   - Example: `crm_customer_info` → customer information from the crm system.

### **Silver Layer**
- All names must start with the source system name, and tables names must match the original names without renaming.

- Take the general configuration **`<sourcesystem>_<entity>`** where:
   - `<sourcesystem>`: Name of the source system (e.g. crm, erp).
   - `<entity>`: Exact table name from the source system
   - Example: `crm_customer_info` → customer information from the crm system.

### **Gold Layer**
- All names must use meaningful, business-aligned names for tables, starting with the category prefix.

- Take the general configuration **`<category>_<entity>`** where:
   - `<category>`: Describes the role of the table (e.g. dimension, fact table).
   - `<entity>`: Descriptive name of the table, aligned with the business domain  (e.g., customers, products, sales).
   - Examples:
      - `dim_customers` → dimension table for customer data.
      - `fact_table` → fact table containing sales transactions.

#### Glossary of Category Expressions

 Pattern | Meaning | Example(s)
----------|--------|--------------
dim_ | Dimension table | `dim_customer`, `dim_product`
fact | Fact Table | `fact_sales`
agg_ | Aggregation Table | `agg_customers`, `agg_sales_monthly`

## Column Naming Conventions

### Surrogate Keys
- All primary keys in dimension tables must use the suffix `key`

- Take the general configuration **`<table_name>_key`** where:
   - `<table_name>`: Refers to the name of the table or entity where the key belongs to.
   - `_key`: A suffix indicating that this column is a surrogate key.
   - Example: `customers_key` → surrogate key in the `dim_customers` table.

### Technical Columns
- All technical columns must start with the prefix `dwh_` followed by a descriptive name indicating the column's purpose.

- Take the general configuration **`dwh_<column_name>`** where:
   - `dwm`: Prefix exclusively for system generated metadata.
   - `<column_name>`: Descriptive name indicating the column's purpose.
   - Example: `dwh_load_date` → System generated column used to store the date when the record was loaded.

## Stored Procedure
- All stored procedures used for loading the data must follow the naming pattern: `load_<layer>`, where possible cases of layer are `bronze`, `silver` or `gold`.