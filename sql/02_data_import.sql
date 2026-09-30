-- ============================================================
-- SUPPLY CHAIN ANALYTICS
-- 02 - DATA IMPORT
-- ============================================================

COPY scm.sales_orders (
    order_id,
    order_date,
    customer_id,
    product_id,
    warehouse_id,
    ordered_qty,
    shipped_qty,
    delivery_date,
    promised_date,
    order_status
)
FROM 'C:/Users/hp/Downloads/sales_orders.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ',',
    QUOTE '"',
    ENCODING 'UTF8'
);