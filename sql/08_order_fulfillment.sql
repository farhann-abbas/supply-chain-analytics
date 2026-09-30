-- ============================================================
-- 08 - ORDER FULFILLMENT ANALYSIS
-- ============================================================

-- 1. Overall order fulfillment

SELECT
    COUNT(*) AS total_orders,
    SUM(order_qty) AS total_ordered_qty,
    SUM(shipped_qty) AS total_shipped_qty,

    SUM(order_qty - shipped_qty) AS total_shortage_qty,

    COUNT(*) FILTER (
        WHERE shipped_qty = 0
    ) AS unfulfilled_orders,

    COUNT(*) FILTER (
        WHERE shipped_qty > 0
          AND shipped_qty < order_qty
    ) AS partially_fulfilled_orders,

    COUNT(*) FILTER (
        WHERE shipped_qty >= order_qty
    ) AS fully_fulfilled_orders,

    ROUND(
        SUM(shipped_qty)::NUMERIC
        / NULLIF(SUM(order_qty), 0) * 100,
        2
    ) AS overall_fill_rate_pct

FROM scm.sales_orders;

-- 2. Fulfillment performance by warehouse

SELECT
    w.warehouse_id,
    w.warehouse_name,
    w.region,

    COUNT(so.order_id) AS total_orders,

    SUM(so.order_qty) AS total_ordered_qty,

    SUM(so.shipped_qty) AS total_shipped_qty,

    SUM(so.order_qty - so.shipped_qty) AS shortage_qty,

    COUNT(*) FILTER (
        WHERE so.shipped_qty = 0
    ) AS unfulfilled_orders,

    COUNT(*) FILTER (
        WHERE so.shipped_qty > 0
          AND so.shipped_qty < so.order_qty
    ) AS partially_fulfilled_orders,

    COUNT(*) FILTER (
        WHERE so.shipped_qty >= so.order_qty
    ) AS fully_fulfilled_orders,

    ROUND(
        SUM(so.shipped_qty)::NUMERIC
        / NULLIF(SUM(so.order_qty), 0) * 100,
        2
    ) AS fill_rate_pct

FROM scm.sales_orders so
JOIN scm.warehouses w
    ON so.warehouse_id = w.warehouse_id

GROUP BY
    w.warehouse_id,
    w.warehouse_name,
    w.region

ORDER BY fill_rate_pct DESC;

-- 3. Fulfillment performance by product category

SELECT
    p.category,

    COUNT(DISTINCT so.order_id) AS total_orders,

    SUM(so.order_qty) AS total_ordered_qty,

    SUM(so.shipped_qty) AS total_shipped_qty,

    SUM(so.order_qty - so.shipped_qty) AS shortage_qty,

    COUNT(*) FILTER (
        WHERE so.shipped_qty = 0
    ) AS unfulfilled_orders,

    COUNT(*) FILTER (
        WHERE so.shipped_qty > 0
          AND so.shipped_qty < so.order_qty
    ) AS partially_fulfilled_orders,

    COUNT(*) FILTER (
        WHERE so.shipped_qty >= so.order_qty
    ) AS fully_fulfilled_orders,

    ROUND(
        SUM(so.shipped_qty)::NUMERIC
        / NULLIF(SUM(so.order_qty), 0) * 100,
        2
    ) AS fill_rate_pct

FROM scm.sales_orders so
JOIN scm.products p
    ON so.product_id = p.product_id

GROUP BY
    p.category

ORDER BY fill_rate_pct DESC;

-- 4. Products with highest fulfillment shortages

SELECT
    p.product_id,
    p.product_name,
    p.category,

    COUNT(so.order_id) AS total_orders,

    SUM(so.order_qty) AS total_ordered_qty,

    SUM(so.shipped_qty) AS total_shipped_qty,

    SUM(so.order_qty - so.shipped_qty) AS shortage_qty,

    ROUND(
        SUM(so.shipped_qty)::NUMERIC
        / NULLIF(SUM(so.order_qty), 0) * 100,
        2
    ) AS fill_rate_pct,

    COUNT(*) FILTER (
        WHERE so.shipped_qty = 0
    ) AS unfulfilled_orders

FROM scm.sales_orders so
JOIN scm.products p
    ON so.product_id = p.product_id

GROUP BY
    p.product_id,
    p.product_name,
    p.category

ORDER BY shortage_qty DESC
LIMIT 20;

-- 5. Fulfillment performance by customer type

SELECT
    c.customer_type,

    COUNT(DISTINCT so.order_id) AS total_orders,

    SUM(so.order_qty) AS total_ordered_qty,

    SUM(so.shipped_qty) AS total_shipped_qty,

    SUM(so.order_qty - so.shipped_qty) AS shortage_qty,

    COUNT(*) FILTER (
        WHERE so.shipped_qty = 0
    ) AS unfulfilled_orders,

    ROUND(
        SUM(so.shipped_qty)::NUMERIC
        / NULLIF(SUM(so.order_qty), 0) * 100,
        2
    ) AS fill_rate_pct

FROM scm.sales_orders so
JOIN scm.customers c
    ON so.customer_id = c.customer_id

GROUP BY
    c.customer_type

ORDER BY fill_rate_pct DESC;