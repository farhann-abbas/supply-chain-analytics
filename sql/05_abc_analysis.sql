-- ============================================================
-- 05 - ABC ANALYSIS
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
)

SELECT
    product_id,
    product_name,
    category,
    annual_demand,
    unit_cost,
    ROUND(annual_consumption_value, 2) AS annual_consumption_value,
    ROUND(
        annual_consumption_value
        / NULLIF(total_consumption_value, 0) * 100,
        2
    ) AS value_percentage,
    ROUND(
        cumulative_consumption_value
        / NULLIF(total_consumption_value, 0) * 100,
        2
    ) AS cumulative_percentage,
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
ORDER BY annual_consumption_value DESC;

-- 2. ABC class summary

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

classified_products AS (
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
)

SELECT
    abc_class,
    COUNT(*) AS product_count,
    ROUND(SUM(annual_consumption_value), 2) AS consumption_value,
    ROUND(
        SUM(annual_consumption_value)
        / NULLIF(MAX(total_consumption_value), 0) * 100,
        2
    ) AS value_percentage
FROM classified_products
GROUP BY abc_class
ORDER BY abc_class;