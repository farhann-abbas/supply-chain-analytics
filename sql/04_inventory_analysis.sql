-- 1. Current inventory by warehouse
-- Using the latest inventory date as the current snapshot

SELECT
    w.warehouse_id,
    w.warehouse_name,
    w.region,
    SUM(i.closing_stock) AS current_stock_qty,
    ROUND(
        SUM(i.closing_stock * p.unit_cost),
        2
    ) AS current_inventory_value
FROM scm.inventory i
JOIN scm.products p
    ON i.product_id = p.product_id
JOIN scm.warehouses w
    ON i.warehouse_id = w.warehouse_id
WHERE i.inventory_date = (
    SELECT MAX(inventory_date)
    FROM scm.inventory
)
GROUP BY
    w.warehouse_id,
    w.warehouse_name,
    w.region
ORDER BY current_inventory_value DESC;

-- 2. Current inventory by category

SELECT
    p.category,
    SUM(i.closing_stock) AS current_stock_qty,
    ROUND(
        SUM(i.closing_stock * p.unit_cost),
        2
    ) AS current_inventory_value
FROM scm.inventory i
JOIN scm.products p
    ON i.product_id = p.product_id
WHERE i.inventory_date = (
    SELECT MAX(inventory_date)
    FROM scm.inventory
)
GROUP BY p.category
ORDER BY current_inventory_value DESC;

-- 3. Product-level reorder risk

WITH latest_inventory AS (
    SELECT
        product_id,
        SUM(closing_stock) AS current_stock
    FROM scm.inventory
    WHERE inventory_date = (
        SELECT MAX(inventory_date)
        FROM scm.inventory
    )
    GROUP BY product_id
)

SELECT
    p.product_id,
    p.product_name,
    p.category,
    li.current_stock,
    p.reorder_point,
    p.safety_stock,
    CASE
        WHEN li.current_stock = 0 THEN 'Stockout'
        WHEN li.current_stock < p.reorder_point THEN 'Reorder Required'
        WHEN li.current_stock > p.reorder_point * 3 THEN 'Excess Stock'
        ELSE 'Healthy'
    END AS stock_status
FROM scm.products p
LEFT JOIN latest_inventory li
    ON p.product_id = li.product_id
ORDER BY
    CASE
        WHEN li.current_stock = 0 THEN 1
        WHEN li.current_stock < p.reorder_point THEN 2
        WHEN li.current_stock > p.reorder_point * 3 THEN 3
        ELSE 4
    END,
    li.current_stock;

-- 4. Reorder risk summary

WITH latest_inventory AS (
    SELECT
        product_id,
        SUM(closing_stock) AS current_stock
    FROM scm.inventory
    WHERE inventory_date = (
        SELECT MAX(inventory_date)
        FROM scm.inventory
    )
    GROUP BY product_id
),

product_status AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        COALESCE(li.current_stock, 0) AS current_stock,
        p.reorder_point,
        CASE
            WHEN COALESCE(li.current_stock, 0) = 0 THEN 'Stockout'
            WHEN li.current_stock < p.reorder_point THEN 'Reorder Required'
            WHEN li.current_stock > p.reorder_point * 3 THEN 'Excess Stock'
            ELSE 'Healthy'
        END AS stock_status
    FROM scm.products p
    LEFT JOIN latest_inventory li
        ON p.product_id = li.product_id
)

SELECT
    stock_status,
    COUNT(*) AS product_count
FROM product_status
GROUP BY stock_status
ORDER BY product_count DESC;

-- 5. Inventory value by stock status

WITH latest_inventory AS (
    SELECT
        product_id,
        SUM(closing_stock) AS current_stock
    FROM scm.inventory
    WHERE inventory_date = (
        SELECT MAX(inventory_date)
        FROM scm.inventory
    )
    GROUP BY product_id
),

product_status AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        COALESCE(li.current_stock, 0) AS current_stock,
        p.reorder_point,
        p.unit_cost,
        CASE
            WHEN COALESCE(li.current_stock, 0) = 0 THEN 'Stockout'
            WHEN li.current_stock < p.reorder_point THEN 'Reorder Required'
            WHEN li.current_stock > p.reorder_point * 3 THEN 'Excess Stock'
            ELSE 'Healthy'
        END AS stock_status
    FROM scm.products p
    LEFT JOIN latest_inventory li
        ON p.product_id = li.product_id
)

SELECT
    stock_status,
    COUNT(*) AS product_count,
    SUM(current_stock) AS current_stock_qty,
    ROUND(
        SUM(current_stock * unit_cost),
        2
    ) AS inventory_value
FROM product_status
GROUP BY stock_status
ORDER BY inventory_value DESC;