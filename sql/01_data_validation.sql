-- ============================================================
-- SUPPLY CHAIN ANALYTICS
-- 01 - DATA VALIDATION
-- ============================================================

-- 1. Check database connection
SELECT
    current_database() AS database_name,
    current_user AS connected_user;


-- 2. Check tables in the SCM schema
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'scm'
ORDER BY table_name;


-- 3. Row counts for all tables
SELECT 'products' AS table_name, COUNT(*) AS row_count
FROM scm.products

UNION ALL

SELECT 'suppliers', COUNT(*)
FROM scm.suppliers

UNION ALL

SELECT 'warehouses', COUNT(*)
FROM scm.warehouses

UNION ALL

SELECT 'customers', COUNT(*)
FROM scm.customers

UNION ALL

SELECT 'inventory', COUNT(*)
FROM scm.inventory

UNION ALL

SELECT 'sales_orders', COUNT(*)
FROM scm.sales_orders

UNION ALL

SELECT 'purchase_orders', COUNT(*)
FROM scm.purchase_orders

ORDER BY table_name;

-- 4. Validate transaction table row counts

SELECT
    'sales_orders' AS table_name,
    COUNT(*) AS row_count
FROM scm.sales_orders

UNION ALL

SELECT
    'purchase_orders',
    COUNT(*)
FROM scm.purchase_orders;

SELECT *
FROM scm.sales_orders
LIMIT 10;

SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(DISTINCT product_id) AS products,
    COUNT(DISTINCT warehouse_id) AS warehouses
FROM scm.sales_orders;

SELECT *
FROM scm.purchase_orders
LIMIT 10;

SELECT
    MIN(po_date) AS first_po_date,
    MAX(po_date) AS last_po_date,
    COUNT(DISTINCT supplier_id) AS suppliers,
    COUNT(DISTINCT product_id) AS products,
    COUNT(DISTINCT warehouse_id) AS warehouses
FROM scm.purchase_orders;