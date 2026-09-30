-- ============================================================
-- 06 - XYZ ANALYSIS
-- ============================================================

WITH monthly_demand AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        DATE_TRUNC('month', i.inventory_date) AS demand_month,
        SUM(i.sales_qty) AS monthly_demand
    FROM scm.products p
    JOIN scm.inventory i
        ON p.product_id = i.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        DATE_TRUNC('month', i.inventory_date)
)

SELECT
    product_id,
    product_name,
    category,
    demand_month,
    monthly_demand
FROM monthly_demand
ORDER BY
    product_id,
    demand_month;

-- 2. Demand variability by product

WITH monthly_demand AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        DATE_TRUNC('month', i.inventory_date) AS demand_month,
        SUM(i.sales_qty) AS monthly_demand
    FROM scm.products p
    JOIN scm.inventory i
        ON p.product_id = i.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        DATE_TRUNC('month', i.inventory_date)
),

demand_stats AS (
    SELECT
        product_id,
        product_name,
        category,
        AVG(monthly_demand) AS avg_monthly_demand,
        STDDEV_POP(monthly_demand) AS demand_stddev
    FROM monthly_demand
    GROUP BY
        product_id,
        product_name,
        category
)

SELECT
    product_id,
    product_name,
    category,
    ROUND(avg_monthly_demand, 2) AS avg_monthly_demand,
    ROUND(demand_stddev, 2) AS demand_stddev,
    ROUND(
        demand_stddev
        / NULLIF(avg_monthly_demand, 0) * 100,
        2
    ) AS coefficient_of_variation_pct
FROM demand_stats
ORDER BY coefficient_of_variation_pct DESC;

-- 3. XYZ classification

WITH monthly_demand AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        DATE_TRUNC('month', i.inventory_date) AS demand_month,
        SUM(i.sales_qty) AS monthly_demand
    FROM scm.products p
    JOIN scm.inventory i
        ON p.product_id = i.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        DATE_TRUNC('month', i.inventory_date)
),

demand_stats AS (
    SELECT
        product_id,
        product_name,
        category,
        AVG(monthly_demand) AS avg_monthly_demand,
        STDDEV_POP(monthly_demand) AS demand_stddev
    FROM monthly_demand
    GROUP BY
        product_id,
        product_name,
        category
)

SELECT
    product_id,
    product_name,
    category,
    ROUND(avg_monthly_demand, 2) AS avg_monthly_demand,
    ROUND(demand_stddev, 2) AS demand_stddev,
    ROUND(
        demand_stddev
        / NULLIF(avg_monthly_demand, 0) * 100,
        2
    ) AS coefficient_of_variation_pct,
    CASE
        WHEN demand_stddev
             / NULLIF(avg_monthly_demand, 0) <= 0.20
            THEN 'X'
        WHEN demand_stddev
             / NULLIF(avg_monthly_demand, 0) <= 0.50
            THEN 'Y'
        ELSE 'Z'
    END AS xyz_class
FROM demand_stats
ORDER BY coefficient_of_variation_pct DESC;

-- 4. XYZ class summary

WITH monthly_demand AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        DATE_TRUNC('month', i.inventory_date) AS demand_month,
        SUM(i.sales_qty) AS monthly_demand
    FROM scm.products p
    JOIN scm.inventory i
        ON p.product_id = i.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        DATE_TRUNC('month', i.inventory_date)
),

demand_stats AS (
    SELECT
        product_id,
        product_name,
        category,
        AVG(monthly_demand) AS avg_monthly_demand,
        STDDEV_POP(monthly_demand) AS demand_stddev
    FROM monthly_demand
    GROUP BY
        product_id,
        product_name,
        category
),

classified_products AS (
    SELECT
        *,
        demand_stddev / NULLIF(avg_monthly_demand, 0) AS cv,
        CASE
            WHEN demand_stddev / NULLIF(avg_monthly_demand, 0) <= 0.20
                THEN 'X'
            WHEN demand_stddev / NULLIF(avg_monthly_demand, 0) <= 0.50
                THEN 'Y'
            ELSE 'Z'
        END AS xyz_class
    FROM demand_stats
)

SELECT
    xyz_class,
    COUNT(*) AS product_count
FROM classified_products
GROUP BY xyz_class
ORDER BY xyz_class;

-- ============================================================
-- 5. ABC-XYZ Product Segmentation
-- ============================================================

WITH product_demand AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,
        SUM(i.sales_qty) AS annual_demand
    FROM scm.products p
    JOIN scm.inventory i
        ON p.product_id = i.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

consumption_value AS (
    SELECT
        *,
        annual_demand * unit_cost AS annual_consumption_value
    FROM product_demand
),

abc_calculation AS (
    SELECT
        *,
        SUM(annual_consumption_value) OVER () AS total_consumption_value,
        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_consumption_value
    FROM consumption_value
),

abc_classification AS (
    SELECT
        *,
        CASE
            WHEN cumulative_consumption_value
                 / NULLIF(total_consumption_value, 0) <= 0.80
                THEN 'A'
            WHEN cumulative_consumption_value
                 / NULLIF(total_consumption_value, 0) <= 0.95
                THEN 'B'
            ELSE 'C'
        END AS abc_class
    FROM abc_calculation
),

monthly_demand AS (
    SELECT
        p.product_id,
        DATE_TRUNC('month', i.inventory_date) AS demand_month,
        SUM(i.sales_qty) AS monthly_demand
    FROM scm.products p
    JOIN scm.inventory i
        ON p.product_id = i.product_id
    GROUP BY
        p.product_id,
        DATE_TRUNC('month', i.inventory_date)
),

demand_stats AS (
    SELECT
        product_id,
        AVG(monthly_demand) AS avg_monthly_demand,
        STDDEV_POP(monthly_demand) AS demand_stddev
    FROM monthly_demand
    GROUP BY product_id
),

xyz_classification AS (
    SELECT
        product_id,
        demand_stddev / NULLIF(avg_monthly_demand, 0) AS cv,
        CASE
            WHEN demand_stddev / NULLIF(avg_monthly_demand, 0) <= 0.20
                THEN 'X'
            WHEN demand_stddev / NULLIF(avg_monthly_demand, 0) <= 0.50
                THEN 'Y'
            ELSE 'Z'
        END AS xyz_class
    FROM demand_stats
)

SELECT
    a.product_id,
    a.product_name,
    a.category,
    a.abc_class,
    x.xyz_class,
    a.abc_class || x.xyz_class AS abc_xyz_class,
    a.annual_demand,
    ROUND(a.annual_consumption_value, 2) AS annual_consumption_value,
    ROUND(x.cv * 100, 2) AS coefficient_of_variation_pct
FROM abc_classification a
JOIN xyz_classification x
    ON a.product_id = x.product_id
ORDER BY
    a.abc_class,
    x.xyz_class,
    a.annual_consumption_value DESC;

-- 6. ABC-XYZ matrix summary

WITH product_demand AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost,
        SUM(i.sales_qty) AS annual_demand
    FROM scm.products p
    JOIN scm.inventory i
        ON p.product_id = i.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.unit_cost
),

consumption_value AS (
    SELECT
        *,
        annual_demand * unit_cost AS annual_consumption_value
    FROM product_demand
),

abc_calculation AS (
    SELECT
        *,
        SUM(annual_consumption_value) OVER () AS total_consumption_value,
        SUM(annual_consumption_value) OVER (
            ORDER BY annual_consumption_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_consumption_value
    FROM consumption_value
),

abc_classification AS (
    SELECT
        *,
        CASE
            WHEN cumulative_consumption_value
                 / NULLIF(total_consumption_value, 0) <= 0.80
                THEN 'A'
            WHEN cumulative_consumption_value
                 / NULLIF(total_consumption_value, 0) <= 0.95
                THEN 'B'
            ELSE 'C'
        END AS abc_class
    FROM abc_calculation
),

monthly_demand AS (
    SELECT
        p.product_id,
        DATE_TRUNC('month', i.inventory_date) AS demand_month,
        SUM(i.sales_qty) AS monthly_demand
    FROM scm.products p
    JOIN scm.inventory i
        ON p.product_id = i.product_id
    GROUP BY
        p.product_id,
        DATE_TRUNC('month', i.inventory_date)
),

demand_stats AS (
    SELECT
        product_id,
        AVG(monthly_demand) AS avg_monthly_demand,
        STDDEV_POP(monthly_demand) AS demand_stddev
    FROM monthly_demand
    GROUP BY product_id
),

xyz_classification AS (
    SELECT
        product_id,
        CASE
            WHEN demand_stddev / NULLIF(avg_monthly_demand, 0) <= 0.20
                THEN 'X'
            WHEN demand_stddev / NULLIF(avg_monthly_demand, 0) <= 0.50
                THEN 'Y'
            ELSE 'Z'
        END AS xyz_class
    FROM demand_stats
),

segmentation AS (
    SELECT
        a.abc_class,
        x.xyz_class,
        a.abc_class || x.xyz_class AS abc_xyz_class
    FROM abc_classification a
    JOIN xyz_classification x
        ON a.product_id = x.product_id
)

SELECT
    abc_class,
    COUNT(*) FILTER (WHERE xyz_class = 'X') AS x_products,
    COUNT(*) FILTER (WHERE xyz_class = 'Y') AS y_products,
    COUNT(*) FILTER (WHERE xyz_class = 'Z') AS z_products,
    COUNT(*) AS total_products
FROM segmentation
GROUP BY abc_class
ORDER BY abc_class;