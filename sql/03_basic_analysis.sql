-- ============================================================
-- 03 - BASIC SUPPLY CHAIN ANALYSIS
-- ============================================================

-- 1. Product demand
-- 1. Product demand

SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(so.order_qty) AS total_ordered_qty,
    SUM(so.shipped_qty) AS total_shipped_qty,
    COUNT(DISTINCT so.order_id) AS order_count
FROM scm.products p
JOIN scm.sales_orders so
    ON p.product_id = so.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY total_ordered_qty DESC;

-- 2. Demand by category

SELECT
    p.category,
    SUM(so.order_qty) AS total_ordered_qty,
    SUM(so.shipped_qty) AS total_shipped_qty,
    COUNT(DISTINCT so.order_id) AS order_count
FROM scm.products p
JOIN scm.sales_orders so
    ON p.product_id = so.product_id
GROUP BY p.category
ORDER BY total_ordered_qty DESC;

-- 3. Fill rate by category

SELECT
    p.category,
    SUM(so.order_qty) AS total_ordered_qty,
    SUM(so.shipped_qty) AS total_shipped_qty,
    SUM(so.order_qty - so.shipped_qty) AS shortage_qty,
    ROUND(
        SUM(so.shipped_qty)::NUMERIC
        / NULLIF(SUM(so.order_qty), 0) * 100,
        2
    ) AS fill_rate_pct
FROM scm.products p
JOIN scm.sales_orders so
    ON p.product_id = so.product_id
GROUP BY p.category
ORDER BY fill_rate_pct DESC;

-- 4. Overall fulfillment KPI

SELECT
    COUNT(*) AS total_orders,
    SUM(so.order_qty) AS total_ordered_qty,
    SUM(so.shipped_qty) AS total_shipped_qty,
    SUM(so.order_qty - so.shipped_qty) AS total_shortage_qty,
    ROUND(
        SUM(so.shipped_qty)::NUMERIC
        / NULLIF(SUM(so.order_qty), 0) * 100,
        2
    ) AS overall_fill_rate_pct
FROM scm.sales_orders so;