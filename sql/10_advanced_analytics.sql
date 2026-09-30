-- ============================================================
-- 10.1 PRODUCT REVENUE RANKING
-- Purpose: Rank products by total sales revenue
-- Technique: CTE + RANK() window function
-- ============================================================

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(so.shipped_qty) AS total_shipped_qty,
        SUM(so.shipped_qty * p.selling_price) AS sales_value
    FROM scm.products p
    JOIN scm.sales_orders so
        ON p.product_id = so.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)

SELECT
    product_id,
    product_name,
    category,
    total_shipped_qty,
    ROUND(sales_value, 2) AS sales_value,

    RANK() OVER (
        ORDER BY sales_value DESC
    ) AS revenue_rank

FROM product_revenue

ORDER BY revenue_rank;

-- ============================================================
-- 10.2 CUMULATIVE REVENUE CONTRIBUTION
-- Purpose: Identify how quickly product revenue accumulates
-- Technique: CTE + SUM() OVER()
-- ============================================================

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(so.shipped_qty) AS total_shipped_qty,
        SUM(so.shipped_qty * p.selling_price) AS sales_value
    FROM scm.products p
    JOIN scm.sales_orders so
        ON p.product_id = so.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ranked_products AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY sales_value DESC
        ) AS revenue_rank
    FROM product_revenue
)

SELECT
    product_id,
    product_name,
    category,
    total_shipped_qty,
    ROUND(sales_value, 2) AS sales_value,
    revenue_rank,

    ROUND(
        100.0 * sales_value
        / SUM(sales_value) OVER (),
        2
    ) AS revenue_contribution_pct,

    ROUND(
        100.0 *
        SUM(sales_value) OVER (
            ORDER BY revenue_rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(sales_value) OVER (),
        2
    ) AS cumulative_revenue_pct

FROM ranked_products

ORDER BY revenue_rank;

-- ============================================================
-- 10.3 MONTHLY SALES GROWTH
-- Purpose: Compare monthly sales with the previous month
-- Technique: CTE + LAG() window function
-- ============================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', so.order_date)::DATE AS order_month,
        SUM(so.shipped_qty) AS total_shipped_qty,
        SUM(so.shipped_qty * p.selling_price) AS monthly_sales_value
    FROM scm.sales_orders so
    JOIN scm.products p
        ON so.product_id = p.product_id
    GROUP BY
        DATE_TRUNC('month', so.order_date)
)

SELECT
    order_month,
    total_shipped_qty,
    ROUND(monthly_sales_value, 2) AS monthly_sales_value,

    ROUND(
        LAG(monthly_sales_value) OVER (
            ORDER BY order_month
        ),
        2
    ) AS previous_month_sales,

    ROUND(
        100.0 *
        (
            monthly_sales_value
            - LAG(monthly_sales_value) OVER (
                ORDER BY order_month
            )
        )
        / NULLIF(
            LAG(monthly_sales_value) OVER (
                ORDER BY order_month
            ),
            0
        ),
        2
    ) AS month_growth_pct

FROM monthly_sales

ORDER BY order_month;

-- ============================================================
-- 10.4 SUPPLIER SPEND CONCENTRATION
-- Purpose: Identify how procurement spend is distributed
--          across suppliers
-- Technique: CTE + RANK() + SUM() OVER()
-- ============================================================

WITH supplier_spend AS (
    SELECT
        s.supplier_id,
        s.supplier_name,
        s.supplier_category,
        SUM(po.received_qty * po.unit_cost) AS purchase_value
    FROM scm.suppliers s
    JOIN scm.purchase_orders po
        ON s.supplier_id = po.supplier_id
    GROUP BY
        s.supplier_id,
        s.supplier_name,
        s.supplier_category
),

ranked_suppliers AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY purchase_value DESC
        ) AS spend_rank
    FROM supplier_spend
)

SELECT
    supplier_id,
    supplier_name,
    supplier_category,
    ROUND(purchase_value, 2) AS purchase_value,
    spend_rank,

    ROUND(
        100.0 * purchase_value
        / SUM(purchase_value) OVER (),
        2
    ) AS spend_percentage,

    ROUND(
        100.0 *
        SUM(purchase_value) OVER (
            ORDER BY spend_rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(purchase_value) OVER (),
        2
    ) AS cumulative_spend_percentage

FROM ranked_suppliers

ORDER BY spend_rank;

-- ============================================================
-- 10.5 INVENTORY RISK SEGMENTATION
-- Purpose: Combine ABC value classification with
--          current inventory/replenishment risk
-- Technique: Multiple CTEs + Window Functions + CASE
-- ============================================================

WITH product_value AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,
        p.reorder_point,
        p.safety_stock,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty * p.unit_cost)
            AS annual_consumption_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,
        p.reorder_point,
        p.safety_stock
),

abc_classification AS (
    SELECT
        *,

        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        )
        / SUM(annual_consumption_value) OVER ()
        AS cumulative_value_pct

    FROM product_value
),

latest_inventory AS (
    SELECT DISTINCT ON (product_id)
        product_id,
        closing_stock
    FROM scm.inventory

    ORDER BY
        product_id,
        inventory_date DESC
)

SELECT
    a.product_id,
    a.product_name,
    a.category,

    CASE
        WHEN a.cumulative_value_pct <= 0.80
            THEN 'A'
        WHEN a.cumulative_value_pct <= 0.95
            THEN 'B'
        ELSE 'C'
    END AS abc_class,

    a.annual_demand,

    ROUND(
        a.annual_consumption_value,
        2
    ) AS annual_consumption_value,

    li.closing_stock AS current_stock,

    a.safety_stock,
    a.reorder_point,

    GREATEST(
        a.reorder_point - li.closing_stock,
        0
    ) AS replenishment_gap,

    CASE
        WHEN li.closing_stock = 0
            THEN 'Critical'

        WHEN li.closing_stock < a.safety_stock
            THEN 'High'

        WHEN li.closing_stock < a.reorder_point
            THEN 'Medium'

        WHEN li.closing_stock > a.reorder_point * 3
            THEN 'Excess'

        ELSE 'Healthy'
    END AS inventory_risk

FROM abc_classification a

JOIN latest_inventory li
    ON a.product_id = li.product_id

ORDER BY
    CASE
        WHEN li.closing_stock = 0 THEN 1
        WHEN li.closing_stock < a.safety_stock THEN 2
        WHEN li.closing_stock < a.reorder_point THEN 3
        WHEN li.closing_stock > a.reorder_point * 3 THEN 4
        ELSE 5
    END,

    a.annual_consumption_value DESC;

-- ============================================================
-- 10.6 SUPPLIER RISK RANKING
-- Purpose: Identify suppliers associated with replenishment risk
-- Technique: CTEs + Aggregation + RANK() + CASE
-- ============================================================

WITH product_risk AS (
    SELECT
        p.product_id,
        p.supplier_id,

        GREATEST(
            p.reorder_point - MAX(i.closing_stock),
            0
        ) AS replenishment_qty

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    WHERE i.inventory_date = (
        SELECT MAX(inventory_date)
        FROM scm.inventory
    )

    GROUP BY
        p.product_id,
        p.supplier_id,
        p.reorder_point
),

supplier_risk AS (
    SELECT
        supplier_id,

        COUNT(*) FILTER (
            WHERE replenishment_qty > 0
        ) AS risk_products,

        SUM(replenishment_qty) AS total_replenishment_qty

    FROM product_risk

    GROUP BY supplier_id
),

supplier_performance AS (
    SELECT
        supplier_id,

        COUNT(*) AS purchase_orders,

        ROUND(
            100.0 *
            COUNT(*) FILTER (
                WHERE actual_receipt_date <= expected_date
            )
            / NULLIF(COUNT(*), 0),
            2
        ) AS on_time_delivery_pct,

        ROUND(
            AVG(
                actual_receipt_date - po_date
            ),
            2
        ) AS avg_actual_lead_days

    FROM scm.purchase_orders

    GROUP BY supplier_id
)

SELECT
    s.supplier_id,
    s.supplier_name,
    s.country,

    COALESCE(sr.risk_products, 0)
        AS risk_products,

    COALESCE(sr.total_replenishment_qty, 0)
        AS total_replenishment_qty,

    sp.purchase_orders,

    sp.on_time_delivery_pct,

    sp.avg_actual_lead_days,

    CASE
        WHEN COALESCE(sr.risk_products, 0) >= 3
             AND sp.on_time_delivery_pct < 75
            THEN 'High Risk'

        WHEN COALESCE(sr.risk_products, 0) >= 2
             AND sp.on_time_delivery_pct < 80
            THEN 'Medium Risk'

        WHEN COALESCE(sr.risk_products, 0) >= 1
             AND sp.on_time_delivery_pct < 85
            THEN 'Watch'

        ELSE 'Standard'
    END AS supplier_risk,

    RANK() OVER (
        ORDER BY
            COALESCE(sr.risk_products, 0) DESC,
            COALESCE(sr.total_replenishment_qty, 0) DESC
    ) AS supplier_risk_rank

FROM scm.suppliers s

LEFT JOIN supplier_risk sr
    ON s.supplier_id = sr.supplier_id

JOIN supplier_performance sp
    ON s.supplier_id = sp.supplier_id

ORDER BY
    supplier_risk_rank;

-- ============================================================
-- 10.7 EXECUTIVE KPI SUMMARY
-- Purpose: Create a single management-level KPI view
-- Technique: Multiple CTEs + Cross Join
-- ============================================================

WITH inventory_kpi AS (
    SELECT
        COUNT(DISTINCT p.product_id) AS total_products,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty * p.unit_cost) AS annual_cogs

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id
),

latest_inventory AS (
    SELECT
        i.product_id,
        i.closing_stock
    FROM scm.inventory i
    WHERE i.inventory_date = (
        SELECT MAX(inventory_date)
        FROM scm.inventory
    )
),

inventory_position AS (
    SELECT
        SUM(
            li.closing_stock * p.unit_cost
        ) AS current_inventory_value,

        COUNT(*) FILTER (
            WHERE li.closing_stock < p.reorder_point
        ) AS products_below_reorder,

        COUNT(*) FILTER (
            WHERE li.closing_stock < p.safety_stock
        ) AS products_below_safety

    FROM latest_inventory li

    JOIN scm.products p
        ON li.product_id = p.product_id
),

order_kpi AS (
    SELECT
        COUNT(*) AS total_orders,

        SUM(order_qty) AS total_ordered_qty,

        SUM(shipped_qty) AS total_shipped_qty,

        ROUND(
            100.0 * SUM(shipped_qty)
            / NULLIF(SUM(order_qty), 0),
            2
        ) AS overall_fill_rate

    FROM scm.sales_orders
),

procurement_kpi AS (
    SELECT
        COUNT(*) AS purchase_orders,

        SUM(received_qty * unit_cost)
            AS total_purchase_spend,

        ROUND(
            100.0 * SUM(received_qty)
            / NULLIF(SUM(ordered_qty), 0),
            2
        ) AS supplier_fill_rate

    FROM scm.purchase_orders
),

turnover_by_product AS (
    SELECT
        p.product_id,

        SUM(i.sales_qty * p.unit_cost)
            AS annual_cogs,

        AVG(i.closing_stock) * p.unit_cost
            AS average_inventory_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.unit_cost
),

turnover_kpi AS (
    SELECT
        SUM(annual_cogs)
        / NULLIF(
            SUM(average_inventory_value),
            0
        ) AS inventory_turnover

    FROM turnover_by_product
)

SELECT
    ik.total_products,
    ik.annual_demand,

    ROUND(ik.annual_cogs, 2)
        AS annual_cogs,

    ROUND(ip.current_inventory_value, 2)
        AS current_inventory_value,

    ip.products_below_reorder,
    ip.products_below_safety,

    ok.total_orders,
    ok.total_ordered_qty,
    ok.total_shipped_qty,
    ok.overall_fill_rate,

    pk.purchase_orders,

    ROUND(pk.total_purchase_spend, 2)
        AS total_purchase_spend,

    pk.supplier_fill_rate,

    ROUND(tk.inventory_turnover, 2)
        AS inventory_turnover,

    ROUND(
        365.0 / NULLIF(tk.inventory_turnover, 0),
        2
    ) AS days_inventory

FROM inventory_kpi ik

CROSS JOIN inventory_position ip
CROSS JOIN order_kpi ok
CROSS JOIN procurement_kpi pk
CROSS JOIN turnover_kpi tk;