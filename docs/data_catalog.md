# Data Catalog
This data catalog describes the gold layer structure ready to support reporting and business intelligence activities. The model follows a star schema design composed of descriptive customer and product dimensions connected to a central sales fact table for specific business metrics.

## gold.dim_customers
Contains customer identification data and demographic attributes.

 Column Name | Data Type | Description
-----------------|--------------|--------------
customer_key     | INT          | Surrogate key uniquely identifying a customer record
customer_id      | INT          | Customer identifier from the source system
customer_number  | NVARCHAR(50) | Alphanumeric code to track and referecing the customer
first_name       | NVARCHAR(50) | Customer's first name
last_name        | NVARCHAR(50) | Customer's last name or family name
country          | NVARCHAR(50) | Residence location of the customer (e.g., Germany)
marital_status   | NVARCHAR(50) | Marital status classification (Married, Single)
gender           | NVARCHAR(50) | Gender classification (Female, Male, n/a)
birthdate        | DATE         | Date of birth of the customer
create_date      | DATE         | Date the customer record was initially created

## gold.dim_products
Stores descriptive product attributes organized into hierarchical classifications

 Column Name | Data Type | Description
---------------|-----------------|---------
product_key     | INT          | Surrogate key uniquely identifying a product record
product_id      | INT          | Product identifier from the source system
product_number  | NVARCHAR(50) | Alphanumeric code of the product, usually used as part of categorization or inventory
category_id     | NVARCHAR(50) | Identifier associated with the product's first level hierarchy
category        | NVARCHAR(50) | General classification name of the product to group related items.
subcategory     | NVARCHAR(50) | Product's second level hierarchy, more detailed specification
maintenance     | NVARCHAR(50) | Indicates wetherer the product needs maintenance (Yes, No)
cost            | INT          | Standart product cost value, measured in monetary units
product_line    | NVARCHAR(50) | Production department where the product belongs
start_date      | DATE         | Date the product became active or available for use or sale.

## gold.fact_sales
Provides transactional sales history for analytical purposes
 Column Name | Data Type | Description
---------------|-----------------|---------
order_number        | NVARCHAR(50) | Unique alphanumeric sales order identifier
product_key         | INT          | Surrogate key associated to the table dimension product
customer_key        | INT          | Surrogate key associated to the table dimension customer
order_date          | DATE         | Date the order was placed.
shipping_date       | DATE         | Date the order was shipped.
due_date            | DATE         | Date when the order payment was due
sales_amount        | INT          | Total income amount calculated in monetary units
quantity            | INT          | Number of product units included in the transaction
price               | INT          | Unit selling price recorded in monetary units