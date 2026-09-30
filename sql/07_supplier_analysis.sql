-- ============================================================
-- 07 - SUPPLIER PERFORMANCE
-- ============================================================

-- 1. Supplier procurement summary

SELECT
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.supplier_category,
    COUNT(po.po_id) AS purchase_order_count,
    SUM(po.ordered_qty) AS total_ordered_qty,
    SUM(po.received_qty) AS total_received_qty,
    ROUND(
        SUM(po.received_qty)::NUMERIC
        / NULLIF(SUM(po.ordered_qty), 0) * 100,
        2
    ) AS supplier_fill_rate_pct
FROM scm.suppliers s
JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id
GROUP BY
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.supplier_category
ORDER BY purchase_order_count DESC;

-- 2. Supplier lead time and on-time delivery

SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(po.po_id) AS purchase_order_count,

    ROUND(
        AVG(
            po.actual_receipt_date - po.po_date
        ),
        2
    ) AS avg_actual_lead_time_days,

    COUNT(*) FILTER (
        WHERE po.actual_receipt_date <= po.expected_date
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE po.actual_receipt_date > po.expected_date
    ) AS delayed_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE po.actual_receipt_date <= po.expected_date
        )::NUMERIC
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS on_time_delivery_pct

FROM scm.suppliers s
JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY
    s.supplier_id,
    s.supplier_name

ORDER BY on_time_delivery_pct DESC;

-- 3. Complete supplier performance summary

SELECT
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.supplier_category,

    COUNT(po.po_id) AS purchase_order_count,

    SUM(po.ordered_qty) AS total_ordered_qty,

    SUM(po.received_qty) AS total_received_qty,

    ROUND(
        SUM(po.received_qty)::NUMERIC
        / NULLIF(SUM(po.ordered_qty), 0) * 100,
        2
    ) AS supplier_fill_rate_pct,

    ROUND(
        SUM(po.received_qty * po.unit_cost),
        2
    ) AS purchase_value,

    ROUND(
        AVG(
            po.actual_receipt_date - po.po_date
        ),
        2
    ) AS avg_actual_lead_time_days,

    COUNT(*) FILTER (
        WHERE po.actual_receipt_date <= po.expected_date
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE po.actual_receipt_date > po.expected_date
    ) AS delayed_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE po.actual_receipt_date <= po.expected_date
        )::NUMERIC
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS on_time_delivery_pct

FROM scm.suppliers s
JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.supplier_category

ORDER BY purchase_value DESC;

-- 4. Supplier performance by supplier category

SELECT
    s.supplier_category,

    COUNT(DISTINCT s.supplier_id) AS supplier_count,

    COUNT(po.po_id) AS purchase_order_count,

    SUM(po.ordered_qty) AS total_ordered_qty,

    SUM(po.received_qty) AS total_received_qty,

    ROUND(
        SUM(po.received_qty)::NUMERIC
        / NULLIF(SUM(po.ordered_qty), 0) * 100,
        2
    ) AS supplier_fill_rate_pct,

    ROUND(
        SUM(po.received_qty * po.unit_cost),
        2
    ) AS purchase_value,

    ROUND(
        AVG(po.actual_receipt_date - po.po_date),
        2
    ) AS avg_actual_lead_time_days,

    ROUND(
        COUNT(*) FILTER (
            WHERE po.actual_receipt_date <= po.expected_date
        )::NUMERIC
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS on_time_delivery_pct

FROM scm.suppliers s
JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY s.supplier_category
ORDER BY purchase_value DESC;

-- 5. Supplier performance by country

SELECT
    s.country,

    COUNT(DISTINCT s.supplier_id) AS supplier_count,

    COUNT(po.po_id) AS purchase_order_count,

    SUM(po.ordered_qty) AS total_ordered_qty,

    SUM(po.received_qty) AS total_received_qty,

    ROUND(
        SUM(po.received_qty)::NUMERIC
        / NULLIF(SUM(po.ordered_qty), 0) * 100,
        2
    ) AS supplier_fill_rate_pct,

    ROUND(
        SUM(po.received_qty * po.unit_cost),
        2
    ) AS purchase_value,

    ROUND(
        AVG(po.actual_receipt_date - po.po_date),
        2
    ) AS avg_actual_lead_time_days,

    ROUND(
        COUNT(*) FILTER (
            WHERE po.actual_receipt_date <= po.expected_date
        )::NUMERIC
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS on_time_delivery_pct

FROM scm.suppliers s
JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY s.country
ORDER BY purchase_value DESC;