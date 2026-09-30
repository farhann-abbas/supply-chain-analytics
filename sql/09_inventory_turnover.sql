-- ============================================================
-- 09 - INVENTORY TURNOVER & WORKING CAPITAL
-- ============================================================

-- 1. Product-level inventory turnover

WITH product_inventory AS (

    SELECT
        i.product_id,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.inventory i

    GROUP BY i.product_id
),

product_demand AS (

    SELECT
        i.product_id,

        SUM(i.sales_qty) AS annual_demand

    FROM scm.inventory i

    GROUP BY i.product_id
)

SELECT
    p.product_id,
    p.product_name,
    p.category,

    d.annual_demand,

    p.unit_cost,

    ROUND(
        d.annual_demand * p.unit_cost,
        2
    ) AS annual_cogs,

    ROUND(
        pi.average_inventory_qty,
        2
    ) AS average_inventory_qty,

    ROUND(
        pi.average_inventory_qty * p.unit_cost,
        2
    ) AS average_inventory_value,

    ROUND(
        (
            d.annual_demand * p.unit_cost
        )
        / NULLIF(
            pi.average_inventory_qty * p.unit_cost,
            0
        ),
        2
    ) AS inventory_turnover,

    ROUND(
        365.0
        / NULLIF(
            (
                d.annual_demand * p.unit_cost
            )
            /
            NULLIF(
                pi.average_inventory_qty * p.unit_cost,
                0
            ),
            0
        ),
        2
    ) AS days_inventory

FROM scm.products p

JOIN product_demand d
    ON p.product_id = d.product_id

JOIN product_inventory pi
    ON p.product_id = pi.product_id

ORDER BY inventory_turnover DESC;

-- 2. Inventory turnover by category

WITH product_metrics AS (

    SELECT
        p.product_id,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.category,
        p.unit_cost
)

SELECT
    category,

    COUNT(*) AS product_count,

    SUM(annual_demand) AS annual_demand,

    ROUND(
        SUM(annual_demand * unit_cost),
        2
    ) AS annual_cogs,

    ROUND(
        SUM(average_inventory_qty * unit_cost),
        2
    ) AS average_inventory_value,

    ROUND(
        SUM(annual_demand * unit_cost)
        /
        NULLIF(
            SUM(average_inventory_qty * unit_cost),
            0
        ),
        2
    ) AS inventory_turnover,

    ROUND(
        365.0
        /
        NULLIF(
            SUM(annual_demand * unit_cost)
            /
            NULLIF(
                SUM(average_inventory_qty * unit_cost),
                0
            ),
            0
        ),
        2
    ) AS days_inventory

FROM product_metrics

GROUP BY category

ORDER BY inventory_turnover DESC;

-- 3. Overall inventory KPIs

WITH product_metrics AS (

    SELECT
        p.product_id,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.unit_cost
)

SELECT

    COUNT(*) AS total_products,

    SUM(annual_demand) AS total_annual_demand,

    ROUND(
        SUM(annual_demand * unit_cost),
        2
    ) AS total_annual_cogs,

    ROUND(
        SUM(average_inventory_qty),
        2
    ) AS total_average_inventory_qty,

    ROUND(
        SUM(average_inventory_qty * unit_cost),
        2
    ) AS total_average_inventory_value,

    ROUND(
        SUM(annual_demand * unit_cost)
        /
        NULLIF(
            SUM(average_inventory_qty * unit_cost),
            0
        ),
        2
    ) AS overall_inventory_turnover,

    ROUND(
        365.0
        /
        NULLIF(
            SUM(annual_demand * unit_cost)
            /
            NULLIF(
                SUM(average_inventory_qty * unit_cost),
                0
            ),
            0
        ),
        2
    ) AS overall_days_inventory

FROM product_metrics;

-- 4. Slow-moving inventory analysis

WITH product_metrics AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        AVG(i.closing_stock) AS average_inventory_qty,

        AVG(i.closing_stock) * p.unit_cost
            AS average_inventory_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

inventory_metrics AS (

    SELECT
        product_id,
        product_name,
        category,
        annual_demand,
        average_inventory_qty,
        average_inventory_value,

        ROUND(
            (annual_demand * unit_cost)
            /
            NULLIF(average_inventory_value, 0),
            2
        ) AS inventory_turnover

    FROM product_metrics
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,
    ROUND(average_inventory_value, 2) AS inventory_value,
    inventory_turnover,

    CASE
        WHEN inventory_turnover >= 10 THEN 'Fast Moving'
        WHEN inventory_turnover >= 5 THEN 'Normal'
        ELSE 'Slow Moving'
    END AS movement_class

FROM inventory_metrics

WHERE inventory_turnover < 5

ORDER BY
    inventory_value DESC;

-- 4A. Inventory turnover distribution

WITH product_metrics AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        AVG(i.closing_stock) AS average_inventory_qty,

        AVG(i.closing_stock) * p.unit_cost
            AS average_inventory_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

inventory_metrics AS (

    SELECT
        product_id,
        product_name,
        category,

        ROUND(
            (annual_demand * unit_cost)
            / NULLIF(average_inventory_value, 0),
            2
        ) AS inventory_turnover

    FROM product_metrics
)

SELECT
    MIN(inventory_turnover) AS minimum_turnover,
    ROUND(AVG(inventory_turnover), 2) AS average_turnover,
    MAX(inventory_turnover) AS maximum_turnover

FROM inventory_metrics;

-- 4B. Low-turnover products

WITH product_metrics AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        AVG(i.closing_stock) AS average_inventory_qty,

        AVG(i.closing_stock) * p.unit_cost
            AS average_inventory_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

inventory_metrics AS (

    SELECT
        product_id,
        product_name,
        category,
        annual_demand,
        average_inventory_qty,
        average_inventory_value,

        ROUND(
            (annual_demand * unit_cost)
            / NULLIF(average_inventory_value, 0),
            2
        ) AS inventory_turnover

    FROM product_metrics
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,
    ROUND(average_inventory_value, 2) AS average_inventory_value,
    inventory_turnover

FROM inventory_metrics

WHERE inventory_turnover < 7

ORDER BY inventory_turnover ASC;

-- 4C. Low-turnover inventory value impact

WITH product_metrics AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        AVG(i.closing_stock) AS average_inventory_qty,

        AVG(i.closing_stock) * p.unit_cost
            AS average_inventory_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

inventory_metrics AS (

    SELECT
        product_id,
        product_name,
        category,
        average_inventory_value,

        ROUND(
            (annual_demand * unit_cost)
            / NULLIF(average_inventory_value, 0),
            2
        ) AS inventory_turnover

    FROM product_metrics
),

low_turnover AS (

    SELECT *
    FROM inventory_metrics
    WHERE inventory_turnover < 7
)

SELECT
    COUNT(*) AS low_turnover_products,

    ROUND(
        SUM(average_inventory_value),
        2
    ) AS low_turnover_inventory_value,

    ROUND(
        100.0 * SUM(average_inventory_value)
        / (SELECT SUM(average_inventory_value)
           FROM inventory_metrics),
        2
    ) AS inventory_value_percentage

FROM low_turnover;

-- ============================================
-- 5. ADVANCED SQL - WINDOW FUNCTIONS
-- ============================================

-- 5.1 Product consumption value ranking

WITH product_value AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty) * p.unit_cost
            AS annual_consumption_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

ranked_products AS (

    SELECT
        product_id,
        product_name,
        category,
        annual_demand,
        ROUND(annual_consumption_value, 2)
            AS annual_consumption_value,

        RANK() OVER (
            ORDER BY annual_consumption_value DESC
        ) AS value_rank,

        ROUND(
            100.0 * annual_consumption_value
            / SUM(annual_consumption_value) OVER (),
            2
        ) AS value_percentage

    FROM product_value
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,
    annual_consumption_value,
    value_rank,
    value_percentage

FROM ranked_products

ORDER BY value_rank;

-- ============================================
-- 5.2 Cumulative consumption value
-- ============================================

WITH product_value AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty) * p.unit_cost
            AS annual_consumption_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

ranked_products AS (

    SELECT
        product_id,
        product_name,
        category,
        annual_demand,

        ROUND(annual_consumption_value, 2)
            AS annual_consumption_value,

        RANK() OVER (
            ORDER BY annual_consumption_value DESC
        ) AS value_rank,

        ROUND(
            100.0 * annual_consumption_value
            / SUM(annual_consumption_value) OVER (),
            2
        ) AS value_percentage,

        ROUND(
            100.0 *
            SUM(annual_consumption_value) OVER (
                ORDER BY annual_consumption_value DESC
                ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
            )
            / SUM(annual_consumption_value) OVER (),
            2
        ) AS cumulative_percentage

    FROM product_value
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,
    annual_consumption_value,
    value_rank,
    value_percentage,
    cumulative_percentage

FROM ranked_products

ORDER BY value_rank;

-- ============================================
-- 5.3 Dynamic ABC classification
-- ============================================

WITH product_value AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty) * p.unit_cost
            AS annual_consumption_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

ranked_products AS (

    SELECT
        product_id,
        product_name,
        category,
        annual_demand,

        annual_consumption_value,

        RANK() OVER (
            ORDER BY annual_consumption_value DESC
        ) AS value_rank,

        100.0 * annual_consumption_value
            / SUM(annual_consumption_value) OVER ()
            AS value_percentage,

        100.0 *
        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        )
        / SUM(annual_consumption_value) OVER ()
            AS cumulative_percentage

    FROM product_value
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,

    ROUND(annual_consumption_value, 2)
        AS annual_consumption_value,

    value_rank,

    ROUND(value_percentage, 2)
        AS value_percentage,

    ROUND(cumulative_percentage, 2)
        AS cumulative_percentage,

    CASE
        WHEN cumulative_percentage <= 80
            THEN 'A'
        WHEN cumulative_percentage <= 95
            THEN 'B'
        ELSE 'C'
    END AS abc_class

FROM ranked_products

ORDER BY value_rank;

-- ============================================
-- 5.4 ABC classification summary
-- ============================================

WITH product_value AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty) * p.unit_cost
            AS annual_consumption_value

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

ranked_products AS (

    SELECT
        *,
        
        100.0 *
        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        )
        / SUM(annual_consumption_value) OVER ()
            AS cumulative_percentage

    FROM product_value
),

classified_products AS (

    SELECT
        *,
        CASE
            WHEN cumulative_percentage <= 80
                THEN 'A'
            WHEN cumulative_percentage <= 95
                THEN 'B'
            ELSE 'C'
        END AS abc_class

    FROM ranked_products
)

SELECT
    abc_class,

    COUNT(*) AS product_count,

    ROUND(
        SUM(annual_consumption_value),
        2
    ) AS consumption_value,

    ROUND(
        100.0 * SUM(annual_consumption_value)
        / SUM(SUM(annual_consumption_value)) OVER (),
        2
    ) AS value_percentage

FROM classified_products

GROUP BY abc_class

ORDER BY abc_class;

-- ============================================
-- 5.5 Supplier spend ranking
-- ============================================

WITH supplier_spend AS (

    SELECT
        s.supplier_id,
        s.supplier_name,
        s.country,
        s.supplier_category,

        COUNT(po.po_id) AS purchase_order_count,

        SUM(po.received_qty) AS total_received_qty,

        SUM(po.received_qty * po.unit_cost)
            AS purchase_value

    FROM scm.suppliers s

    JOIN scm.purchase_orders po
        ON s.supplier_id = po.supplier_id

    GROUP BY
        s.supplier_id,
        s.supplier_name,
        s.country,
        s.supplier_category
),

ranked_suppliers AS (

    SELECT
        supplier_id,
        supplier_name,
        country,
        supplier_category,
        purchase_order_count,
        total_received_qty,

        ROUND(purchase_value, 2)
            AS purchase_value,

        RANK() OVER (
            ORDER BY purchase_value DESC
        ) AS spend_rank,

        ROUND(
            100.0 * purchase_value
            / SUM(purchase_value) OVER (),
            2
        ) AS spend_percentage,

        ROUND(
            100.0 *
            SUM(purchase_value) OVER (
                ORDER BY purchase_value DESC
                ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
            )
            / SUM(purchase_value) OVER (),
            2
        ) AS cumulative_spend_percentage

    FROM supplier_spend
)

SELECT
    supplier_id,
    supplier_name,
    country,
    supplier_category,
    purchase_order_count,
    total_received_qty,
    purchase_value,
    spend_rank,
    spend_percentage,
    cumulative_spend_percentage

FROM ranked_suppliers

ORDER BY spend_rank;

-- ============================================
-- 5.6 Supplier spend concentration
-- ============================================

WITH supplier_spend AS (

    SELECT
        s.supplier_id,
        s.supplier_name,

        SUM(po.received_qty * po.unit_cost)
            AS purchase_value

    FROM scm.suppliers s

    JOIN scm.purchase_orders po
        ON s.supplier_id = po.supplier_id

    GROUP BY
        s.supplier_id,
        s.supplier_name
),

ranked_suppliers AS (

    SELECT
        supplier_id,
        supplier_name,
        purchase_value,

        RANK() OVER (
            ORDER BY purchase_value DESC
        ) AS spend_rank,

        ROUND(
            100.0 * purchase_value
            / SUM(purchase_value) OVER (),
            2
        ) AS spend_percentage,

        ROUND(
            100.0 *
            SUM(purchase_value) OVER (
                ORDER BY purchase_value DESC
                ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
            )
            / SUM(purchase_value) OVER (),
            2
        ) AS cumulative_spend_percentage

    FROM supplier_spend
)

SELECT
    spend_rank,
    supplier_id,
    supplier_name,
    ROUND(purchase_value, 2) AS purchase_value,
    spend_percentage,
    cumulative_spend_percentage,

    CASE
        WHEN cumulative_spend_percentage <= 80
            THEN 'Within 80% Spend'
        ELSE 'Beyond 80% Spend'
    END AS spend_concentration

FROM ranked_suppliers

ORDER BY spend_rank;

-- ============================================
-- 5.7 Supplier Performance Scorecard
-- ============================================

SELECT
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.supplier_category,

    COUNT(po.po_id) AS purchase_orders,

    SUM(po.ordered_qty) AS total_ordered_qty,

    SUM(po.received_qty) AS total_received_qty,

    ROUND(
        100.0 * SUM(po.received_qty)
        / NULLIF(SUM(po.ordered_qty), 0),
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
        100.0 *
        COUNT(*) FILTER (
            WHERE po.actual_receipt_date <= po.expected_date
        )
        / NULLIF(COUNT(*), 0),
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

ORDER BY
    purchase_value DESC;

-- ============================================
-- 5.8 Suppliers with delivery delays
-- ============================================

SELECT
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.supplier_category,

    COUNT(po.po_id) AS purchase_orders,

    COUNT(*) FILTER (
        WHERE po.actual_receipt_date > po.expected_date
    ) AS delayed_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE po.actual_receipt_date > po.expected_date
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS delay_rate_pct,

    ROUND(
        AVG(
            po.actual_receipt_date - po.po_date
        ),
        2
    ) AS avg_actual_lead_time_days,

    ROUND(
        SUM(po.received_qty * po.unit_cost),
        2
    ) AS purchase_value

FROM scm.suppliers s

JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.supplier_category

HAVING
    COUNT(*) FILTER (
        WHERE po.actual_receipt_date > po.expected_date
    ) > 0

ORDER BY
    delay_rate_pct DESC,
    delayed_orders DESC;

-- ============================================
-- 5.9 Supplier performance by country
-- ============================================

SELECT
    s.country,

    COUNT(DISTINCT s.supplier_id) AS supplier_count,

    COUNT(po.po_id) AS purchase_orders,

    SUM(po.ordered_qty) AS total_ordered_qty,

    SUM(po.received_qty) AS total_received_qty,

    ROUND(
        100.0 * SUM(po.received_qty)
        / NULLIF(SUM(po.ordered_qty), 0),
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
        100.0 *
        COUNT(*) FILTER (
            WHERE po.actual_receipt_date <= po.expected_date
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_pct

FROM scm.suppliers s

JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY
    s.country

ORDER BY
    purchase_value DESC;

-- ============================================
-- 5.10 Supplier performance by category
-- ============================================

SELECT
    s.supplier_category,

    COUNT(DISTINCT s.supplier_id) AS supplier_count,

    COUNT(po.po_id) AS purchase_orders,

    SUM(po.ordered_qty) AS total_ordered_qty,

    SUM(po.received_qty) AS total_received_qty,

    ROUND(
        100.0 * SUM(po.received_qty)
        / NULLIF(SUM(po.ordered_qty), 0),
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
        100.0 *
        COUNT(*) FILTER (
            WHERE po.actual_receipt_date <= po.expected_date
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_pct

FROM scm.suppliers s

JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY
    s.supplier_category

ORDER BY
    purchase_value DESC;

-- ============================================
-- 6.1 Overall Order Fulfillment KPI
-- ============================================

SELECT
    COUNT(*) AS total_orders,

    SUM(order_qty) AS total_ordered_qty,

    SUM(shipped_qty) AS total_shipped_qty,

    SUM(
        GREATEST(order_qty - shipped_qty, 0)
    ) AS total_shortage_qty,

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
        100.0 * SUM(shipped_qty)
        / NULLIF(SUM(order_qty), 0),
        2
    ) AS overall_fill_rate_pct

FROM scm.sales_orders;

-- ============================================
-- 6.2 Fulfillment by Warehouse
-- ============================================

SELECT
    w.warehouse_id,
    w.warehouse_name,
    w.region,

    COUNT(so.order_id) AS total_orders,

    SUM(so.order_qty) AS total_ordered_qty,

    SUM(so.shipped_qty) AS total_shipped_qty,

    SUM(
        GREATEST(so.order_qty - so.shipped_qty, 0)
    ) AS shortage_qty,

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
        100.0 * SUM(so.shipped_qty)
        / NULLIF(SUM(so.order_qty), 0),
        2
    ) AS fill_rate_pct

FROM scm.sales_orders so

JOIN scm.warehouses w
    ON so.warehouse_id = w.warehouse_id

GROUP BY
    w.warehouse_id,
    w.warehouse_name,
    w.region

ORDER BY
    fill_rate_pct DESC;

-- ============================================
-- 6.3 Fulfillment by Product Category
-- ============================================

SELECT
    p.category,

    COUNT(so.order_id) AS total_orders,

    SUM(so.order_qty) AS total_ordered_qty,

    SUM(so.shipped_qty) AS total_shipped_qty,

    SUM(
        GREATEST(so.order_qty - so.shipped_qty, 0)
    ) AS shortage_qty,

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
        100.0 * SUM(so.shipped_qty)
        / NULLIF(SUM(so.order_qty), 0),
        2
    ) AS fill_rate_pct

FROM scm.sales_orders so

JOIN scm.products p
    ON so.product_id = p.product_id

GROUP BY
    p.category

ORDER BY
    fill_rate_pct DESC;

-- ============================================
-- 6.4 Fulfillment by Customer Type
-- ============================================

SELECT
    c.customer_type,

    COUNT(so.order_id) AS total_orders,

    SUM(so.order_qty) AS total_ordered_qty,

    SUM(so.shipped_qty) AS total_shipped_qty,

    SUM(
        GREATEST(so.order_qty - so.shipped_qty, 0)
    ) AS shortage_qty,

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
        100.0 * SUM(so.shipped_qty)
        / NULLIF(SUM(so.order_qty), 0),
        2
    ) AS fill_rate_pct

FROM scm.sales_orders so

JOIN scm.customers c
    ON so.customer_id = c.customer_id

GROUP BY
    c.customer_type

ORDER BY
    fill_rate_pct DESC;

-- ============================================
-- 6.5 Product-Level Fulfillment Analysis
-- ============================================

SELECT
    p.product_id,
    p.product_name,
    p.category,

    COUNT(so.order_id) AS total_orders,

    SUM(so.order_qty) AS total_ordered_qty,

    SUM(so.shipped_qty) AS total_shipped_qty,

    SUM(
        GREATEST(so.order_qty - so.shipped_qty, 0)
    ) AS shortage_qty,

    ROUND(
        100.0 * SUM(so.shipped_qty)
        / NULLIF(SUM(so.order_qty), 0),
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

ORDER BY
    shortage_qty DESC

LIMIT 20;

-- ============================================
-- 6.6 Lowest Product Fill Rates
-- ============================================

SELECT
    p.product_id,
    p.product_name,
    p.category,

    COUNT(so.order_id) AS total_orders,

    SUM(so.order_qty) AS total_ordered_qty,

    SUM(so.shipped_qty) AS total_shipped_qty,

    SUM(
        GREATEST(so.order_qty - so.shipped_qty, 0)
    ) AS shortage_qty,

    ROUND(
        100.0 * SUM(so.shipped_qty)
        / NULLIF(SUM(so.order_qty), 0),
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

HAVING
    SUM(so.order_qty) > 0

ORDER BY
    fill_rate_pct ASC

LIMIT 20;

-- ============================================
-- 6.7 Monthly Fulfillment Trend
-- ============================================

SELECT
    DATE_TRUNC('month', order_date)::date AS order_month,

    COUNT(order_id) AS total_orders,

    SUM(order_qty) AS total_ordered_qty,

    SUM(shipped_qty) AS total_shipped_qty,

    SUM(
        GREATEST(order_qty - shipped_qty, 0)
    ) AS shortage_qty,

    ROUND(
        100.0 * SUM(shipped_qty)
        / NULLIF(SUM(order_qty), 0),
        2
    ) AS fill_rate_pct,

    COUNT(*) FILTER (
        WHERE shipped_qty = 0
    ) AS unfulfilled_orders

FROM scm.sales_orders

GROUP BY
    DATE_TRUNC('month', order_date)

ORDER BY
    order_month;

-- ============================================
-- 6.8 Final Fulfillment KPI Validation
-- ============================================

SELECT
    COUNT(*) AS total_orders,

    SUM(order_qty) AS total_ordered_qty,

    SUM(shipped_qty) AS total_shipped_qty,

    SUM(
        GREATEST(order_qty - shipped_qty, 0)
    ) AS total_shortage_qty,

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
        100.0 * SUM(shipped_qty)
        / NULLIF(SUM(order_qty), 0),
        2
    ) AS overall_fill_rate_pct

FROM scm.sales_orders;

-- ============================================
-- 7.1 Product-Level Inventory Turnover
-- ============================================

WITH product_demand AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty) * p.unit_cost AS annual_cogs

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

average_inventory AS (
    SELECT
        product_id,
        AVG(closing_stock) AS average_inventory_qty
    FROM scm.inventory
    GROUP BY product_id
)

SELECT
    d.product_id,
    d.product_name,
    d.category,

    d.annual_demand,

    ROUND(d.unit_cost, 2) AS unit_cost,

    ROUND(d.annual_cogs, 2) AS annual_cogs,

    ROUND(a.average_inventory_qty, 2)
        AS average_inventory_qty,

    ROUND(
        a.average_inventory_qty * d.unit_cost,
        2
    ) AS average_inventory_value,

    ROUND(
        d.annual_cogs
        / NULLIF(
            a.average_inventory_qty * d.unit_cost,
            0
        ),
        2
    ) AS inventory_turnover,

    ROUND(
        365.0
        / NULLIF(
            d.annual_cogs
            / NULLIF(
                a.average_inventory_qty * d.unit_cost,
                0
            ),
            0
        ),
        2
    ) AS days_inventory

FROM product_demand d

JOIN average_inventory a
    ON d.product_id = a.product_id

ORDER BY
    inventory_turnover DESC;

-- ============================================
-- 7.2 Inventory Turnover by Category
-- ============================================

WITH product_turnover AS (
    SELECT
        p.product_id,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty) * p.unit_cost AS annual_cogs,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.category,
        p.unit_cost
)

SELECT
    category,

    COUNT(product_id) AS product_count,

    SUM(annual_demand) AS annual_demand,

    ROUND(
        SUM(annual_cogs),
        2
    ) AS annual_cogs,

    ROUND(
        SUM(
            average_inventory_qty * unit_cost
        ),
        2
    ) AS average_inventory_value,

    ROUND(
        SUM(annual_cogs)
        / NULLIF(
            SUM(
                average_inventory_qty * unit_cost
            ),
            0
        ),
        2
    ) AS inventory_turnover,

    ROUND(
        365.0
        / NULLIF(
            SUM(annual_cogs)
            / NULLIF(
                SUM(
                    average_inventory_qty * unit_cost
                ),
                0
            ),
            0
        ),
        2
    ) AS days_inventory

FROM product_turnover

GROUP BY
    category

ORDER BY
    inventory_turnover DESC;

-- ============================================
-- 7.3 Overall Inventory Turnover KPI
-- ============================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty) * p.unit_cost AS annual_cogs,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.unit_cost
)

SELECT
    COUNT(product_id) AS total_products,

    SUM(annual_demand) AS total_annual_demand,

    ROUND(
        SUM(annual_cogs),
        2
    ) AS total_annual_cogs,

    ROUND(
        SUM(
            average_inventory_qty * unit_cost
        ),
        2
    ) AS total_average_inventory_value,

    ROUND(
        SUM(annual_cogs)
        / NULLIF(
            SUM(
                average_inventory_qty * unit_cost
            ),
            0
        ),
        2
    ) AS overall_inventory_turnover,

    ROUND(
        365.0
        / NULLIF(
            SUM(annual_cogs)
            / NULLIF(
                SUM(
                    average_inventory_qty * unit_cost
                ),
                0
            ),
            0
        ),
        2
    ) AS overall_days_inventory

FROM product_metrics;

-- ============================================
-- 7.4 Slow-Moving Inventory
-- ============================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty) * p.unit_cost AS annual_cogs,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

turnover AS (
    SELECT
        *,
        annual_cogs
        / NULLIF(
            average_inventory_qty * unit_cost,
            0
        ) AS inventory_turnover
    FROM product_metrics
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,

    ROUND(
        average_inventory_qty,
        2
    ) AS average_inventory_qty,

    ROUND(
        average_inventory_qty * unit_cost,
        2
    ) AS inventory_value,

    ROUND(
        inventory_turnover,
        2
    ) AS inventory_turnover,

    ROUND(
        365.0 / NULLIF(inventory_turnover, 0),
        2
    ) AS days_inventory

FROM turnover

WHERE inventory_turnover < 7

ORDER BY
    inventory_turnover ASC;

-- ============================================
-- 7.5 Inventory Turnover Summary
-- ============================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.unit_cost,

        SUM(i.sales_qty) * p.unit_cost AS annual_cogs,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.products p

    JOIN scm.inventory i
        ON p.product_id = i.product_id

    GROUP BY
        p.product_id,
        p.unit_cost
),

turnover AS (
    SELECT
        annual_cogs
        / NULLIF(
            average_inventory_qty * unit_cost,
            0
        ) AS inventory_turnover
    FROM product_metrics
)

SELECT
    ROUND(MIN(inventory_turnover), 2)
        AS minimum_turnover,

    ROUND(AVG(inventory_turnover), 2)
        AS average_turnover,

    ROUND(MAX(inventory_turnover), 2)
        AS maximum_turnover

FROM turnover;

-- ============================================
-- 7.6 Inventory Turnover by Warehouse
-- ============================================

WITH warehouse_metrics AS (
    SELECT
        w.warehouse_id,
        w.warehouse_name,
        w.region,

        SUM(i.sales_qty) AS annual_demand,

        SUM(
            i.sales_qty * p.unit_cost
        ) AS annual_cogs,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.warehouses w

    JOIN scm.inventory i
        ON w.warehouse_id = i.warehouse_id

    JOIN scm.products p
        ON i.product_id = p.product_id

    GROUP BY
        w.warehouse_id,
        w.warehouse_name,
        w.region
)

SELECT
    warehouse_id,
    warehouse_name,
    region,

    annual_demand,

    ROUND(
        annual_cogs,
        2
    ) AS annual_cogs,

    ROUND(
        average_inventory_qty,
        2
    ) AS average_inventory_qty,

    ROUND(
        annual_cogs
        / NULLIF(
            average_inventory_qty
            * (
                annual_cogs
                / NULLIF(annual_demand, 0)
            ),
            0
        ),
        2
    ) AS inventory_turnover

FROM warehouse_metrics

ORDER BY
    inventory_turnover DESC;

-- ============================================
-- 7.7 Inventory Turnover by Category
-- ============================================

WITH category_metrics AS (
    SELECT
        p.category,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty * p.unit_cost) AS annual_cogs,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.inventory i

    JOIN scm.products p
        ON i.product_id = p.product_id

    GROUP BY
        p.category
)

SELECT
    category,

    annual_demand,

    ROUND(annual_cogs, 2) AS annual_cogs,

    ROUND(average_inventory_qty, 2)
        AS average_inventory_qty,

    ROUND(
        annual_cogs
        / NULLIF(
            average_inventory_qty
            * (
                annual_cogs
                / NULLIF(annual_demand, 0)
            ),
            0
        ),
        2
    ) AS inventory_turnover,

    ROUND(
        365.0 /
        NULLIF(
            annual_cogs
            / NULLIF(
                average_inventory_qty
                * (
                    annual_cogs
                    / NULLIF(annual_demand, 0)
                ),
                0
            ),
            0
        ),
        2
    ) AS days_inventory

FROM category_metrics

ORDER BY
    inventory_turnover DESC;

-- ============================================
-- 7.8 Inventory Turnover by Warehouse
-- ============================================

WITH warehouse_metrics AS (
    SELECT
        w.warehouse_id,
        w.warehouse_name,
        w.region,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty * p.unit_cost) AS annual_cogs,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.inventory i

    JOIN scm.products p
        ON i.product_id = p.product_id

    JOIN scm.warehouses w
        ON i.warehouse_id = w.warehouse_id

    GROUP BY
        w.warehouse_id,
        w.warehouse_name,
        w.region
)

SELECT
    warehouse_id,
    warehouse_name,
    region,

    annual_demand,

    ROUND(annual_cogs, 2) AS annual_cogs,

    ROUND(average_inventory_qty, 2)
        AS average_inventory_qty,

    ROUND(
        annual_cogs
        / NULLIF(
            average_inventory_qty
            * (
                annual_cogs
                / NULLIF(annual_demand, 0)
            ),
            0
        ),
        2
    ) AS inventory_turnover,

    ROUND(
        365.0 /
        NULLIF(
            annual_cogs
            / NULLIF(
                average_inventory_qty
                * (
                    annual_cogs
                    / NULLIF(annual_demand, 0)
                ),
                0
            ),
            0
        ),
        2
    ) AS days_inventory

FROM warehouse_metrics

ORDER BY
    inventory_turnover DESC;

-- ============================================
-- 7.9 Inventory Turnover by Category
-- ============================================

WITH category_metrics AS (
    SELECT
        p.category,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty * p.unit_cost) AS annual_cogs,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.inventory i

    JOIN scm.products p
        ON i.product_id = p.product_id

    GROUP BY
        p.category
)

SELECT
    category,
    annual_demand,

    ROUND(annual_cogs, 2) AS annual_cogs,

    ROUND(average_inventory_qty, 2)
        AS average_inventory_qty,

    ROUND(
        annual_cogs
        / NULLIF(
            average_inventory_qty
            * (
                annual_cogs
                / NULLIF(annual_demand, 0)
            ),
            0
        ),
        2
    ) AS inventory_turnover,

    ROUND(
        365.0 /
        NULLIF(
            annual_cogs
            / NULLIF(
                average_inventory_qty
                * (
                    annual_cogs
                    / NULLIF(annual_demand, 0)
                ),
                0
            ),
            0
        ),
        2
    ) AS days_inventory

FROM category_metrics

ORDER BY
    inventory_turnover DESC;

-- ============================================
-- 7.10 Bottom 10 Products by Inventory Turnover
-- ============================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,

        SUM(i.sales_qty) AS annual_demand,

        SUM(i.sales_qty * p.unit_cost) AS annual_cogs,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.inventory i

    JOIN scm.products p
        ON i.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

turnover_metrics AS (
    SELECT
        product_id,
        product_name,
        category,
        unit_cost,
        annual_demand,
        ROUND(annual_cogs, 2) AS annual_cogs,
        ROUND(average_inventory_qty, 2) AS average_inventory_qty,

        ROUND(
            annual_demand::numeric
            / NULLIF(average_inventory_qty, 0),
            2
        ) AS inventory_turnover,

        ROUND(
            365.0 /
            NULLIF(
                annual_demand::numeric
                / NULLIF(average_inventory_qty, 0),
                0
            ),
            2
        ) AS days_inventory,

        ROUND(
            average_inventory_qty * unit_cost,
            2
        ) AS average_inventory_value

    FROM product_metrics
)

SELECT *
FROM turnover_metrics

ORDER BY
    inventory_turnover ASC

LIMIT 10;

-- ============================================
-- 7.11 Inventory Turnover Summary
-- ============================================

WITH product_metrics AS (
    SELECT
        p.product_id,

        SUM(i.sales_qty) AS annual_demand,

        AVG(i.closing_stock) AS average_inventory_qty

    FROM scm.inventory i

    JOIN scm.products p
        ON i.product_id = p.product_id

    GROUP BY
        p.product_id
),

turnover_metrics AS (
    SELECT
        product_id,

        annual_demand::numeric
        / NULLIF(average_inventory_qty, 0)
        AS inventory_turnover

    FROM product_metrics
)

SELECT
    ROUND(MIN(inventory_turnover), 2)
        AS minimum_turnover,

    ROUND(AVG(inventory_turnover), 2)
        AS average_turnover,

    ROUND(MAX(inventory_turnover), 2)
        AS maximum_turnover,

    ROUND(
        365.0 / NULLIF(AVG(inventory_turnover), 0),
        2
    ) AS average_days_inventory

FROM turnover_metrics;

-- ============================================
-- 8.1 Top Products by Revenue Contribution
-- CTE + Window Function
-- ============================================

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(so.shipped_qty) AS total_shipped_qty,

        SUM(
            so.shipped_qty * p.selling_price
        ) AS sales_value

    FROM scm.sales_orders so

    JOIN scm.products p
        ON so.product_id = p.product_id

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
    ) AS revenue_rank,

    ROUND(
        100.0 * sales_value
        / SUM(sales_value) OVER (),
        2
    ) AS revenue_contribution_pct,

    ROUND(
        100.0 *
        SUM(sales_value) OVER (
            ORDER BY sales_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        )
        / SUM(sales_value) OVER (),
        2
    ) AS cumulative_revenue_pct

FROM product_sales

ORDER BY
    sales_value DESC

LIMIT 20;

-- ============================================
-- 8.2 Revenue Contribution by Category
-- CTE + Window Function
-- ============================================

WITH category_sales AS (
    SELECT
        p.category,

        SUM(so.shipped_qty) AS total_shipped_qty,

        SUM(
            so.shipped_qty * p.selling_price
        ) AS sales_value

    FROM scm.sales_orders so

    JOIN scm.products p
        ON so.product_id = p.product_id

    GROUP BY
        p.category
)

SELECT
    category,
    total_shipped_qty,

    ROUND(sales_value, 2) AS sales_value,

    RANK() OVER (
        ORDER BY sales_value DESC
    ) AS revenue_rank,

    ROUND(
        100.0 * sales_value
        / SUM(sales_value) OVER (),
        2
    ) AS revenue_contribution_pct,

    ROUND(
        100.0 *
        SUM(sales_value) OVER (
            ORDER BY sales_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        )
        / SUM(sales_value) OVER (),
        2
    ) AS cumulative_revenue_pct

FROM category_sales

ORDER BY
    sales_value DESC;

-- ============================================
-- 8.3 Monthly Revenue Trend
-- CTE + Date Aggregation + LAG()
-- ============================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', so.order_date)::date AS order_month,

        SUM(so.shipped_qty) AS total_shipped_qty,

        SUM(
            so.shipped_qty * p.selling_price
        ) AS sales_value

    FROM scm.sales_orders so

    JOIN scm.products p
        ON so.product_id = p.product_id

    GROUP BY
        DATE_TRUNC('month', so.order_date)::date
),

monthly_comparison AS (
    SELECT
        order_month,
        total_shipped_qty,
        sales_value,

        LAG(sales_value) OVER (
            ORDER BY order_month
        ) AS previous_month_sales

    FROM monthly_sales
)

SELECT
    order_month,
    total_shipped_qty,

    ROUND(sales_value, 2) AS sales_value,

    ROUND(previous_month_sales, 2)
        AS previous_month_sales,

    ROUND(
        100.0 *
        (sales_value - previous_month_sales)
        / NULLIF(previous_month_sales, 0),
        2
    ) AS mom_growth_pct

FROM monthly_comparison

ORDER BY
    order_month;

-- ============================================
-- 8.4 Running Revenue by Month
-- Window Function: Running Total
-- ============================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', so.order_date)::date AS order_month,

        SUM(so.shipped_qty) AS total_shipped_qty,

        SUM(
            so.shipped_qty * p.selling_price
        ) AS sales_value

    FROM scm.sales_orders so

    JOIN scm.products p
        ON so.product_id = p.product_id

    GROUP BY
        DATE_TRUNC('month', so.order_date)::date
)

SELECT
    order_month,
    total_shipped_qty,

    ROUND(sales_value, 2) AS monthly_sales_value,

    ROUND(
        SUM(sales_value) OVER (
            ORDER BY order_month
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ),
        2
    ) AS cumulative_sales_value

FROM monthly_sales

ORDER BY
    order_month;

-- ============================================
-- 8.5 ABC Classification Using Window Functions
-- ============================================

WITH product_value AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(i.sales_qty) AS annual_demand,

        SUM(
            i.sales_qty * p.unit_cost
        ) AS annual_consumption_value

    FROM scm.inventory i

    JOIN scm.products p
        ON i.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ranked_products AS (
    SELECT
        product_id,
        product_name,
        category,
        annual_demand,
        annual_consumption_value,

        RANK() OVER (
            ORDER BY annual_consumption_value DESC
        ) AS value_rank,

        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_value

    FROM product_value
),

abc_classification AS (
    SELECT
        *,
        
        100.0 * cumulative_value
        / SUM(annual_consumption_value) OVER ()
        AS cumulative_value_pct

    FROM ranked_products
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,

    ROUND(annual_consumption_value, 2)
        AS annual_consumption_value,

    value_rank,

    ROUND(
        100.0 * annual_consumption_value
        / SUM(annual_consumption_value) OVER (),
        2
    ) AS value_percentage,

    ROUND(cumulative_value_pct, 2)
        AS cumulative_value_pct,

    CASE
        WHEN cumulative_value_pct <= 80
            THEN 'A'

        WHEN cumulative_value_pct <= 95
            THEN 'B'

        ELSE 'C'
    END AS abc_class

FROM abc_classification

ORDER BY
    annual_consumption_value DESC;

-- ============================================
-- 8.6 ABC Class Summary
-- ============================================

WITH product_value AS (
    SELECT
        p.product_id,

        SUM(
            i.sales_qty * p.unit_cost
        ) AS annual_consumption_value

    FROM scm.inventory i

    JOIN scm.products p
        ON i.product_id = p.product_id

    GROUP BY
        p.product_id
),

ranked_products AS (
    SELECT
        product_id,
        annual_consumption_value,

        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_value

    FROM product_value
),

classified_products AS (
    SELECT
        product_id,
        annual_consumption_value,

        100.0 * cumulative_value
        / SUM(annual_consumption_value) OVER ()
        AS cumulative_value_pct

    FROM ranked_products
)

SELECT
    CASE
        WHEN cumulative_value_pct <= 80 THEN 'A'
        WHEN cumulative_value_pct <= 95 THEN 'B'
        ELSE 'C'
    END AS abc_class,

    COUNT(*) AS product_count,

    ROUND(
        SUM(annual_consumption_value),
        2
    ) AS consumption_value,

    ROUND(
        100.0 * SUM(annual_consumption_value)
        / SUM(SUM(annual_consumption_value)) OVER (),
        2
    ) AS value_percentage

FROM classified_products

GROUP BY
    CASE
        WHEN cumulative_value_pct <= 80 THEN 'A'
        WHEN cumulative_value_pct <= 95 THEN 'B'
        ELSE 'C'
    END

ORDER BY
    abc_class;

-- ============================================
-- 8.7 Supplier Spend Ranking
-- CTE + Window Functions
-- ============================================

WITH supplier_spend AS (
    SELECT
        s.supplier_id,
        s.supplier_name,
        s.supplier_category,

        SUM(
            po.received_qty * po.unit_cost
        ) AS purchase_value

    FROM scm.purchase_orders po

    JOIN scm.suppliers s
        ON po.supplier_id = s.supplier_id

    GROUP BY
        s.supplier_id,
        s.supplier_name,
        s.supplier_category
)

SELECT
    supplier_id,
    supplier_name,
    supplier_category,

    ROUND(purchase_value, 2)
        AS purchase_value,

    RANK() OVER (
        ORDER BY purchase_value DESC
    ) AS spend_rank,

    ROUND(
        100.0 * purchase_value
        / SUM(purchase_value) OVER (),
        2
    ) AS spend_contribution_pct,

    ROUND(
        100.0 *
        SUM(purchase_value) OVER (
            ORDER BY purchase_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        )
        / SUM(purchase_value) OVER (),
        2
    ) AS cumulative_spend_pct

FROM supplier_spend

ORDER BY
    purchase_value DESC;

-- ============================================
-- 8.8 Supplier Spend Concentration
-- ============================================

WITH supplier_spend AS (
    SELECT
        supplier_id,
        SUM(
            received_qty * unit_cost
        ) AS purchase_value

    FROM scm.purchase_orders

    GROUP BY
        supplier_id
),

ranked_suppliers AS (
    SELECT
        supplier_id,
        purchase_value,

        RANK() OVER (
            ORDER BY purchase_value DESC
        ) AS spend_rank

    FROM supplier_spend
),

total_spend AS (
    SELECT
        SUM(purchase_value) AS total_purchase_value
    FROM supplier_spend
)

SELECT
    COUNT(*) FILTER (
        WHERE spend_rank <= 5
    ) AS top_5_suppliers,

    ROUND(
        100.0 *
        SUM(purchase_value) FILTER (
            WHERE spend_rank <= 5
        )
        / MAX(total_purchase_value),
        2
    ) AS top_5_spend_pct,

    COUNT(*) FILTER (
        WHERE spend_rank <= 10
    ) AS top_10_suppliers,

    ROUND(
        100.0 *
        SUM(purchase_value) FILTER (
            WHERE spend_rank <= 10
        )
        / MAX(total_purchase_value),
        2
    ) AS top_10_spend_pct,

    COUNT(*) FILTER (
        WHERE spend_rank <= 15
    ) AS top_15_suppliers,

    ROUND(
        100.0 *
        SUM(purchase_value) FILTER (
            WHERE spend_rank <= 15
        )
        / MAX(total_purchase_value),
        2
    ) AS top_15_spend_pct

FROM ranked_suppliers
CROSS JOIN total_spend;

-- ============================================
-- 8.9 Supplier Spend by Country
-- ============================================

SELECT
    s.country,

    COUNT(DISTINCT s.supplier_id) AS supplier_count,

    COUNT(po.po_id) AS purchase_orders,

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
    ) AS purchase_value

FROM scm.suppliers s

JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY
    s.country

ORDER BY
    purchase_value DESC;

-- ============================================
-- 8.10 Supplier Performance Summary
-- ============================================

SELECT
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.supplier_category,

    COUNT(po.po_id) AS purchase_orders,

    SUM(po.ordered_qty) AS total_ordered_qty,

    SUM(po.received_qty) AS total_received_qty,

    ROUND(
        SUM(po.received_qty)::NUMERIC
        / NULLIF(SUM(po.ordered_qty), 0) * 100,
        2
    ) AS fill_rate_pct,

    ROUND(
        SUM(po.received_qty * po.unit_cost),
        2
    ) AS purchase_value,

    ROUND(
        AVG(po.actual_receipt_date - po.po_date),
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
        / NULLIF(COUNT(po.po_id), 0) * 100,
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

ORDER BY
    purchase_value DESC;

-- ============================================
-- 8.11 Supplier Spend & Risk Analysis
-- ============================================

WITH supplier_metrics AS (

    SELECT
        s.supplier_id,
        s.supplier_name,
        s.country,
        s.supplier_category,

        COUNT(po.po_id) AS purchase_orders,

        SUM(po.ordered_qty) AS total_ordered_qty,

        SUM(po.received_qty) AS total_received_qty,

        ROUND(
            SUM(po.received_qty)::NUMERIC
            / NULLIF(SUM(po.ordered_qty), 0) * 100,
            2
        ) AS fill_rate_pct,

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
            / NULLIF(COUNT(po.po_id), 0) * 100,
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
)

SELECT
    *,
    
    RANK() OVER (
        ORDER BY purchase_value DESC
    ) AS spend_rank,

    ROUND(
        purchase_value
        / SUM(purchase_value) OVER () * 100,
        2
    ) AS spend_percentage,

    ROUND(
        SUM(purchase_value) OVER (
            ORDER BY purchase_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(purchase_value) OVER () * 100,
        2
    ) AS cumulative_spend_pct,

    CASE
        WHEN on_time_delivery_pct < 75
            THEN 'High Delivery Risk'
        WHEN on_time_delivery_pct < 80
            THEN 'Medium Delivery Risk'
        ELSE 'Lower Delivery Risk'
    END AS delivery_risk

FROM supplier_metrics

ORDER BY spend_rank;

-- ============================================
-- 8.12 Supplier Concentration Analysis
-- ============================================

WITH supplier_spend AS (

    SELECT
        s.supplier_id,
        s.supplier_name,
        SUM(po.received_qty * po.unit_cost) AS purchase_value

    FROM scm.suppliers s

    JOIN scm.purchase_orders po
        ON s.supplier_id = po.supplier_id

    GROUP BY
        s.supplier_id,
        s.supplier_name
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
    COUNT(*) FILTER (
        WHERE spend_rank <= 5
    ) AS top_5_suppliers,

    ROUND(
        SUM(purchase_value) FILTER (
            WHERE spend_rank <= 5
        )
        / SUM(purchase_value) * 100,
        2
    ) AS top_5_spend_pct,

    COUNT(*) FILTER (
        WHERE spend_rank <= 10
    ) AS top_10_suppliers,

    ROUND(
        SUM(purchase_value) FILTER (
            WHERE spend_rank <= 10
        )
        / SUM(purchase_value) * 100,
        2
    ) AS top_10_spend_pct,

    COUNT(*) FILTER (
        WHERE spend_rank <= 15
    ) AS top_15_suppliers,

    ROUND(
        SUM(purchase_value) FILTER (
            WHERE spend_rank <= 15
        )
        / SUM(purchase_value) * 100,
        2
    ) AS top_15_spend_pct,

    COUNT(*) AS total_suppliers,

    ROUND(
        SUM(purchase_value),
        2
    ) AS total_purchase_value

FROM ranked_suppliers;

-- ============================================
-- 8.13 Procurement Risk by Country & Category
-- ============================================

SELECT
    s.country,
    s.supplier_category,

    COUNT(DISTINCT s.supplier_id) AS supplier_count,

    COUNT(po.po_id) AS purchase_orders,

    SUM(po.ordered_qty) AS total_ordered_qty,

    SUM(po.received_qty) AS total_received_qty,

    ROUND(
        SUM(po.received_qty)::NUMERIC
        / NULLIF(SUM(po.ordered_qty), 0) * 100,
        2
    ) AS fill_rate_pct,

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
        / NULLIF(COUNT(po.po_id), 0) * 100,
        2
    ) AS on_time_delivery_pct

FROM scm.suppliers s

JOIN scm.purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY
    s.country,
    s.supplier_category

ORDER BY
    purchase_value DESC;

-- ============================================
-- 9.1 Current Inventory Position & Stock Coverage
-- ============================================

WITH demand AS (

    SELECT
        product_id,
        SUM(sales_qty) AS annual_demand

    FROM scm.inventory

    GROUP BY product_id
),

latest_inventory AS (

    SELECT DISTINCT ON (product_id)

        product_id,
        inventory_date,
        closing_stock

    FROM scm.inventory

    ORDER BY
        product_id,
        inventory_date DESC
)

SELECT
    p.product_id,
    p.product_name,
    p.category,

    d.annual_demand,

    ROUND(
        d.annual_demand / 365.0,
        2
    ) AS avg_daily_demand,

    li.closing_stock AS current_stock,

    p.safety_stock,

    p.reorder_point,

    ROUND(
        li.closing_stock * p.unit_cost,
        2
    ) AS inventory_value,

    ROUND(
        li.closing_stock
        / NULLIF(d.annual_demand / 365.0, 0),
        2
    ) AS stock_coverage_days,

    CASE
        WHEN li.closing_stock = 0
            THEN 'Stockout'

        WHEN li.closing_stock < p.reorder_point
            THEN 'Reorder Required'

        WHEN li.closing_stock > p.reorder_point * 3
            THEN 'Excess Stock'

        ELSE 'Healthy'
    END AS stock_status

FROM scm.products p

JOIN demand d
    ON p.product_id = d.product_id

JOIN latest_inventory li
    ON p.product_id = li.product_id

ORDER BY
    stock_coverage_days ASC;

-- ============================================
-- 9.2 Replenishment Risk Summary
-- ============================================

WITH demand AS (

    SELECT
        product_id,
        SUM(sales_qty) AS annual_demand
    FROM scm.inventory
    GROUP BY product_id
),

latest_inventory AS (

    SELECT DISTINCT ON (product_id)
        product_id,
        inventory_date,
        closing_stock
    FROM scm.inventory
    ORDER BY product_id, inventory_date DESC
),

inventory_position AS (

    SELECT
        p.product_id,
        p.category,
        d.annual_demand,
        li.closing_stock AS current_stock,
        p.reorder_point,
        p.safety_stock,

        li.closing_stock
        / NULLIF(d.annual_demand / 365.0, 0)
        AS stock_coverage_days,

        li.closing_stock * p.unit_cost
        AS inventory_value,

        CASE
            WHEN li.closing_stock = 0
                THEN 'Stockout'

            WHEN li.closing_stock < p.reorder_point
                THEN 'Reorder Required'

            WHEN li.closing_stock > p.reorder_point * 3
                THEN 'Excess Stock'

            ELSE 'Healthy'
        END AS stock_status

    FROM scm.products p

    JOIN demand d
        ON p.product_id = d.product_id

    JOIN latest_inventory li
        ON p.product_id = li.product_id
)

SELECT
    stock_status,

    COUNT(*) AS product_count,

    SUM(current_stock) AS total_current_stock,

    ROUND(
        SUM(inventory_value),
        2
    ) AS inventory_value,

    ROUND(
        AVG(stock_coverage_days),
        2
    ) AS avg_stock_coverage_days

FROM inventory_position

GROUP BY stock_status

ORDER BY
    CASE stock_status
        WHEN 'Stockout' THEN 1
        WHEN 'Reorder Required' THEN 2
        WHEN 'Healthy' THEN 3
        WHEN 'Excess Stock' THEN 4
    END;

-- ============================================
-- 9.3 Priority Replenishment Products
-- ============================================

WITH demand AS (

    SELECT
        product_id,
        SUM(sales_qty) AS annual_demand

    FROM scm.inventory

    GROUP BY product_id
),

latest_inventory AS (

    SELECT DISTINCT ON (product_id)

        product_id,
        inventory_date,
        closing_stock

    FROM scm.inventory

    ORDER BY
        product_id,
        inventory_date DESC
),

replenishment AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,

        d.annual_demand,

        li.closing_stock AS current_stock,

        p.reorder_point,

        p.safety_stock,

        p.unit_cost,

        p.reorder_point - li.closing_stock
            AS replenishment_gap,

        ROUND(
            li.closing_stock
            / NULLIF(d.annual_demand / 365.0, 0),
            2
        ) AS stock_coverage_days,

        ROUND(
            li.closing_stock * p.unit_cost,
            2
        ) AS inventory_value

    FROM scm.products p

    JOIN demand d
        ON p.product_id = d.product_id

    JOIN latest_inventory li
        ON p.product_id = li.product_id

    WHERE li.closing_stock < p.reorder_point
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,
    current_stock,
    reorder_point,
    safety_stock,
    replenishment_gap,
    stock_coverage_days,
    inventory_value,

    RANK() OVER (
        ORDER BY replenishment_gap DESC
    ) AS replenishment_priority

FROM replenishment

ORDER BY
    replenishment_priority;

-- ============================================
-- 9.4 ABC + Replenishment Risk
-- ============================================

WITH demand AS (

    SELECT
        product_id,
        SUM(sales_qty) AS annual_demand
    FROM scm.inventory
    GROUP BY product_id
),

abc_base AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,
        d.annual_demand,

        d.annual_demand * p.unit_cost
            AS annual_consumption_value

    FROM scm.products p

    JOIN demand d
        ON p.product_id = d.product_id
),

abc_ranked AS (

    SELECT
        *,
        
        RANK() OVER (
            ORDER BY annual_consumption_value DESC
        ) AS value_rank,

        SUM(annual_consumption_value) OVER ()
            AS total_consumption_value,

        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_consumption_value

    FROM abc_base
),

abc_classified AS (

    SELECT
        *,

        CASE
            WHEN cumulative_consumption_value
                 / total_consumption_value <= 0.80
                THEN 'A'

            WHEN cumulative_consumption_value
                 / total_consumption_value <= 0.95
                THEN 'B'

            ELSE 'C'
        END AS abc_class

    FROM abc_ranked
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
    a.annual_demand,
    a.annual_consumption_value,
    a.abc_class,

    li.closing_stock AS current_stock,

    p.reorder_point,

    p.safety_stock,

    p.reorder_point - li.closing_stock
        AS replenishment_gap,

    CASE
        WHEN li.closing_stock = 0
            THEN 'Stockout'

        WHEN li.closing_stock < p.reorder_point
            THEN 'Reorder Required'

        WHEN li.closing_stock > p.reorder_point * 3
            THEN 'Excess Stock'

        ELSE 'Healthy'
    END AS stock_status

FROM abc_classified a

JOIN scm.products p
    ON a.product_id = p.product_id

JOIN latest_inventory li
    ON a.product_id = li.product_id

ORDER BY
    CASE a.abc_class
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        ELSE 3
    END,
    replenishment_gap DESC;

-- ============================================
-- 9.5 ABC × Stock Status Summary
-- ============================================

WITH demand AS (

    SELECT
        product_id,
        SUM(sales_qty) AS annual_demand
    FROM scm.inventory
    GROUP BY product_id
),

abc_base AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,
        d.annual_demand,

        d.annual_demand * p.unit_cost
            AS annual_consumption_value

    FROM scm.products p

    JOIN demand d
        ON p.product_id = d.product_id
),

abc_ranked AS (

    SELECT
        *,
        
        SUM(annual_consumption_value) OVER ()
            AS total_consumption_value,

        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_consumption_value

    FROM abc_base
),

abc_classified AS (

    SELECT
        *,
        
        CASE
            WHEN cumulative_consumption_value
                 / total_consumption_value <= 0.80
                THEN 'A'

            WHEN cumulative_consumption_value
                 / total_consumption_value <= 0.95
                THEN 'B'

            ELSE 'C'
        END AS abc_class

    FROM abc_ranked
),

latest_inventory AS (

    SELECT DISTINCT ON (product_id)
        product_id,
        closing_stock
    FROM scm.inventory
    ORDER BY
        product_id,
        inventory_date DESC
),

inventory_status AS (

    SELECT
        a.abc_class,

        CASE
            WHEN li.closing_stock = 0
                THEN 'Stockout'

            WHEN li.closing_stock < p.reorder_point
                THEN 'Reorder Required'

            WHEN li.closing_stock > p.reorder_point * 3
                THEN 'Excess Stock'

            ELSE 'Healthy'
        END AS stock_status,

        a.annual_consumption_value

    FROM abc_classified a

    JOIN scm.products p
        ON a.product_id = p.product_id

    JOIN latest_inventory li
        ON a.product_id = li.product_id
)

SELECT
    abc_class,
    stock_status,

    COUNT(*) AS product_count,

    ROUND(
        SUM(annual_consumption_value),
        2
    ) AS annual_consumption_value

FROM inventory_status

GROUP BY
    abc_class,
    stock_status

ORDER BY
    CASE abc_class
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        WHEN 'C' THEN 3
    END,

    CASE stock_status
        WHEN 'Stockout' THEN 1
        WHEN 'Reorder Required' THEN 2
        WHEN 'Healthy' THEN 3
        WHEN 'Excess Stock' THEN 4
    END;

-- ============================================
-- 9.6 A-Class Replenishment Priority
-- ============================================

WITH demand AS (

    SELECT
        product_id,
        SUM(sales_qty) AS annual_demand
    FROM scm.inventory
    GROUP BY product_id
),

abc_base AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,
        p.reorder_point,
        p.safety_stock,
        d.annual_demand,

        d.annual_demand * p.unit_cost
            AS annual_consumption_value

    FROM scm.products p

    JOIN demand d
        ON p.product_id = d.product_id
),

abc_ranked AS (

    SELECT
        *,
        
        SUM(annual_consumption_value) OVER ()
            AS total_consumption_value,

        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_consumption_value

    FROM abc_base
),

abc_classified AS (

    SELECT
        *,
        
        CASE
            WHEN cumulative_consumption_value
                 / total_consumption_value <= 0.80
                THEN 'A'

            WHEN cumulative_consumption_value
                 / total_consumption_value <= 0.95
                THEN 'B'

            ELSE 'C'
        END AS abc_class

    FROM abc_ranked
),

latest_inventory AS (

    SELECT DISTINCT ON (product_id)
        product_id,
        closing_stock
    FROM scm.inventory
    ORDER BY
        product_id,
        inventory_date DESC
),

priority AS (

    SELECT
        a.product_id,
        a.product_name,
        a.category,
        a.abc_class,
        a.annual_demand,
        a.annual_consumption_value,
        li.closing_stock AS current_stock,
        a.reorder_point,
        a.safety_stock,

        GREATEST(
            a.reorder_point - li.closing_stock,
            0
        ) AS replenishment_qty

    FROM abc_classified a

    JOIN latest_inventory li
        ON a.product_id = li.product_id

    WHERE
        a.abc_class = 'A'
        AND li.closing_stock < a.reorder_point
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,
    ROUND(annual_consumption_value, 2)
        AS annual_consumption_value,
    current_stock,
    reorder_point,
    safety_stock,
    replenishment_qty

FROM priority

ORDER BY
    annual_consumption_value DESC;

WITH replenishment AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        abc.annual_demand,
        abc.annual_consumption_value,
        r.current_stock,
        r.reorder_point,
        r.safety_stock,
        GREATEST(r.reorder_point - r.current_stock, 0) AS replenishment_qty
    FROM scm.products p
    JOIN (
        SELECT
            product_id,
            SUM(sales_qty) AS annual_demand,
            SUM(sales_qty) * MAX(unit_cost) AS annual_consumption_value
        FROM scm.inventory i
        JOIN scm.products p2 USING (product_id)
        GROUP BY product_id
    ) abc
        ON p.product_id = abc.product_id
    JOIN (
        SELECT
            product_id,
            SUM(closing_stock) FILTER (
                WHERE inventory_date = (
                    SELECT MAX(inventory_date)
                    FROM scm.inventory
                )
            ) AS current_stock,
            MAX(reorder_point) AS reorder_point,
            MAX(safety_stock) AS safety_stock
        FROM scm.inventory i
        JOIN scm.products p3 USING (product_id)
        GROUP BY product_id
    ) r
        ON p.product_id = r.product_id
)
SELECT
    *,
    CASE
        WHEN current_stock = 0 THEN 'Critical'
        WHEN current_stock < safety_stock THEN 'High'
        WHEN current_stock < reorder_point THEN 'Medium'
        ELSE 'Low'
    END AS priority,
    RANK() OVER (
        ORDER BY
            CASE
                WHEN current_stock = 0 THEN 1
                WHEN current_stock < safety_stock THEN 2
                WHEN current_stock < reorder_point THEN 3
                ELSE 4
            END,
            annual_consumption_value DESC
    ) AS replenishment_rank
FROM replenishment
WHERE replenishment_qty > 0
ORDER BY replenishment_rank;

WITH abc AS (
    SELECT
        product_id,
        product_name,
        category,
        annual_consumption_value,
        abc_class
    FROM (
        SELECT
            p.product_id,
            p.product_name,
            p.category,
            SUM(i.sales_qty) * p.unit_cost AS annual_consumption_value,
            CASE
                WHEN SUM(i.sales_qty) * p.unit_cost
                     / SUM(SUM(i.sales_qty) * p.unit_cost) OVER () <= 0.80
                    THEN 'A'
                WHEN SUM(i.sales_qty) * p.unit_cost
                     / SUM(SUM(i.sales_qty) * p.unit_cost) OVER () <= 0.95
                    THEN 'B'
                ELSE 'C'
            END AS abc_class
        FROM scm.products p
        JOIN scm.inventory i
            ON p.product_id = i.product_id
        GROUP BY
            p.product_id,
            p.product_name,
            p.category,
            p.unit_cost
    ) x
),
replenishment AS (
    SELECT
        p.product_id,
        MAX(i.closing_stock) AS current_stock,
        p.reorder_point,
        p.safety_stock,
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
        p.reorder_point,
        p.safety_stock
)
SELECT
    a.product_id,
    a.product_name,
    a.category,
    a.abc_class,
    a.annual_consumption_value,
    r.current_stock,
    r.reorder_point,
    r.safety_stock,
    r.replenishment_qty,
    CASE
        WHEN a.abc_class = 'A'
             AND r.current_stock < r.safety_stock
            THEN 'Critical'
        WHEN a.abc_class = 'A'
             AND r.current_stock < r.reorder_point
            THEN 'High'
        WHEN a.abc_class = 'B'
             AND r.current_stock < r.reorder_point
            THEN 'Medium'
        WHEN r.current_stock < r.reorder_point
            THEN 'Low'
        ELSE 'No Risk'
    END AS inventory_risk
FROM abc a
JOIN replenishment r
    ON a.product_id = r.product_id
WHERE r.current_stock < r.reorder_point
ORDER BY
    CASE
        WHEN a.abc_class = 'A'
             AND r.current_stock < r.safety_stock THEN 1
        WHEN a.abc_class = 'A'
             AND r.current_stock < r.reorder_point THEN 2
        WHEN a.abc_class = 'B'
             AND r.current_stock < r.reorder_point THEN 3
        ELSE 4
    END,
    a.annual_consumption_value DESC;

WITH abc_risk AS (
    SELECT
        a.product_id,
        a.abc_class,
        a.annual_consumption_value,
        r.current_stock,
        r.reorder_point,
        r.safety_stock
    FROM (
        SELECT
            p.product_id,
            CASE
                WHEN SUM(i.sales_qty) * p.unit_cost
                     / SUM(SUM(i.sales_qty) * p.unit_cost) OVER () <= 0.80
                    THEN 'A'
                WHEN SUM(i.sales_qty) * p.unit_cost
                     / SUM(SUM(i.sales_qty) * p.unit_cost) OVER () <= 0.95
                    THEN 'B'
                ELSE 'C'
            END AS abc_class,
            SUM(i.sales_qty) * p.unit_cost AS annual_consumption_value
        FROM scm.products p
        JOIN scm.inventory i
            ON p.product_id = i.product_id
        GROUP BY
            p.product_id,
            p.unit_cost
    ) a
    JOIN (
        SELECT
            p.product_id,
            MAX(i.closing_stock) AS current_stock,
            p.reorder_point,
            p.safety_stock
        FROM scm.products p
        JOIN scm.inventory i
            ON p.product_id = i.product_id
        WHERE i.inventory_date = (
            SELECT MAX(inventory_date)
            FROM scm.inventory
        )
        GROUP BY
            p.product_id,
            p.reorder_point,
            p.safety_stock
    ) r
        ON a.product_id = r.product_id
)
SELECT
    abc_class,
    COUNT(*) AS product_count,
    COUNT(*) FILTER (
        WHERE current_stock < safety_stock
    ) AS below_safety_stock,
    COUNT(*) FILTER (
        WHERE current_stock < reorder_point
    ) AS below_reorder_point,
    ROUND(
        SUM(
            CASE
                WHEN current_stock < reorder_point
                THEN annual_consumption_value
                ELSE 0
            END
        ), 2
    ) AS at_risk_inventory_value,
    ROUND(
        AVG(
            CASE
                WHEN current_stock < reorder_point
                THEN reorder_point - current_stock
            END
        ), 2
    ) AS avg_replenishment_gap
FROM abc_risk
GROUP BY abc_class
ORDER BY abc_class;

WITH product_risk AS (
    SELECT
        p.product_id,
        p.product_name,
        p.supplier_id,
        p.category,
        MAX(i.closing_stock) AS current_stock,
        p.reorder_point,
        p.safety_stock,
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
        p.product_name,
        p.supplier_id,
        p.category,
        p.reorder_point,
        p.safety_stock
),
supplier_risk AS (
    SELECT
        s.supplier_id,
        s.supplier_name,
        s.country,
        s.supplier_category,
        COUNT(pr.product_id) AS risk_products,
        SUM(pr.replenishment_qty) AS total_replenishment_qty,
        ROUND(
            AVG(pr.replenishment_qty), 2
        ) AS avg_replenishment_qty
    FROM scm.suppliers s
    JOIN product_risk pr
        ON s.supplier_id = pr.supplier_id
    WHERE pr.current_stock < pr.reorder_point
    GROUP BY
        s.supplier_id,
        s.supplier_name,
        s.country,
        s.supplier_category
)
SELECT
    *,
    RANK() OVER (
        ORDER BY
            risk_products DESC,
            total_replenishment_qty DESC
    ) AS supplier_risk_rank
FROM supplier_risk
ORDER BY supplier_risk_rank;

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
        COUNT(*) AS risk_products,
        SUM(replenishment_qty) AS total_replenishment_qty
    FROM product_risk
    WHERE replenishment_qty > 0
    GROUP BY supplier_id
),
supplier_performance AS (
    SELECT
        supplier_id,
        COUNT(*) AS purchase_orders,
        COUNT(*) FILTER (
            WHERE actual_receipt_date <= expected_date
        ) AS on_time_orders,
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
            ), 2
        ) AS avg_actual_lead_days
    FROM scm.purchase_orders
    GROUP BY supplier_id
)
SELECT
    s.supplier_id,
    s.supplier_name,
    sr.risk_products,
    sr.total_replenishment_qty,
    sp.purchase_orders,
    sp.on_time_delivery_pct,
    sp.avg_actual_lead_days,
    CASE
        WHEN sr.risk_products >= 3
             AND sp.on_time_delivery_pct < 75
            THEN 'High Procurement Risk'
        WHEN sr.risk_products >= 2
             AND sp.on_time_delivery_pct < 80
            THEN 'Medium Procurement Risk'
        WHEN sr.risk_products >= 1
             AND sp.on_time_delivery_pct < 85
            THEN 'Watch'
        ELSE 'Standard'
    END AS procurement_risk
FROM supplier_risk sr
JOIN scm.suppliers s
    ON sr.supplier_id = s.supplier_id
JOIN supplier_performance sp
    ON sr.supplier_id = sp.supplier_id
ORDER BY
    sr.risk_products DESC,
    sp.on_time_delivery_pct ASC;

WITH monthly_procurement AS (
    SELECT
        DATE_TRUNC('month', po_date)::date AS order_month,
        COUNT(*) AS purchase_orders,
        SUM(ordered_qty) AS ordered_qty,
        SUM(received_qty) AS received_qty,
        SUM(received_qty * unit_cost) AS purchase_value
    FROM scm.purchase_orders
    GROUP BY DATE_TRUNC('month', po_date)
)
SELECT
    order_month,
    purchase_orders,
    ordered_qty,
    received_qty,
    ROUND(purchase_value, 2) AS purchase_value,
    ROUND(
        100.0 * received_qty / NULLIF(ordered_qty, 0),
        2
    ) AS supplier_fill_rate_pct,
    ROUND(
        100.0 * (
            purchase_value
            - LAG(purchase_value) OVER (
                ORDER BY order_month
            )
        )
        / NULLIF(
            LAG(purchase_value) OVER (
                ORDER BY order_month
            ),
            0
        ),
        2
    ) AS mom_purchase_value_growth_pct
FROM monthly_procurement
ORDER BY order_month;

WITH monthly_procurement AS (
    SELECT
        DATE_TRUNC('month', po_date)::date AS order_month,
        SUM(received_qty * unit_cost) AS purchase_value
    FROM scm.purchase_orders
    GROUP BY DATE_TRUNC('month', po_date)
)
SELECT
    order_month,
    ROUND(purchase_value, 2) AS monthly_purchase_value,
    ROUND(
        SUM(purchase_value) OVER (
            ORDER BY order_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_purchase_value,
    ROUND(
        100.0 * purchase_value
        / SUM(purchase_value) OVER (),
        2
    ) AS monthly_spend_pct
FROM monthly_procurement
ORDER BY order_month;

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
)
SELECT
    supplier_id,
    supplier_name,
    supplier_category,
    ROUND(purchase_value, 2) AS purchase_value,
    RANK() OVER (
        ORDER BY purchase_value DESC
    ) AS spend_rank,
    ROUND(
        100.0 * purchase_value
        / SUM(purchase_value) OVER (),
        2
    ) AS spend_percentage,
    ROUND(
        100.0 * SUM(purchase_value) OVER (
            ORDER BY purchase_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(purchase_value) OVER (),
        2
    ) AS cumulative_spend_percentage
FROM supplier_spend
ORDER BY spend_rank;

WITH supplier_spend AS (
    SELECT
        supplier_id,
        SUM(received_qty * unit_cost) AS purchase_value
    FROM scm.purchase_orders
    GROUP BY supplier_id
),
ranked_suppliers AS (
    SELECT
        supplier_id,
        purchase_value,
        RANK() OVER (
            ORDER BY purchase_value DESC
        ) AS spend_rank,
        SUM(purchase_value) OVER () AS total_spend,
        SUM(purchase_value) OVER (
            ORDER BY purchase_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_spend
    FROM supplier_spend
)
SELECT
    COUNT(*) AS total_suppliers,

    COUNT(*) FILTER (
        WHERE spend_rank <= 5
    ) AS top_5_suppliers,

    ROUND(
        100.0 *
        SUM(purchase_value) FILTER (
            WHERE spend_rank <= 5
        )
        / MAX(total_spend),
        2
    ) AS top_5_spend_pct,

    COUNT(*) FILTER (
        WHERE spend_rank <= 10
    ) AS top_10_suppliers,

    ROUND(
        100.0 *
        SUM(purchase_value) FILTER (
            WHERE spend_rank <= 10
        )
        / MAX(total_spend),
        2
    ) AS top_10_spend_pct,

    COUNT(*) FILTER (
        WHERE spend_rank <= 15
    ) AS top_15_suppliers,

    ROUND(
        100.0 *
        SUM(purchase_value) FILTER (
            WHERE spend_rank <= 15
        )
        / MAX(total_spend),
        2
    ) AS top_15_spend_pct,

    ROUND(MAX(total_spend), 2) AS total_purchase_spend

FROM ranked_suppliers;