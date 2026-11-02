-- 三：分析配送表现
-- 订单是否按时送达？哪些订单存在配送延迟？

SELECT
    COUNT(*) AS delivered_order_count,
    SUM(
        CASE
            WHEN order_delivered_customer_date
                 IS NOT NULL
             AND order_estimated_delivery_date
                 IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS assessable_order_count,
    SUM(
        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_order_count,
    ROUND(
        AVG(
            CASE
                WHEN order_delivered_customer_date IS NOT NULL
                 AND order_purchase_timestamp IS NOT NULL
                THEN TIMESTAMPDIFF(
                    DAY,
                    order_purchase_timestamp,
                    order_delivered_customer_date
                )
            END
        ),
        2
    ) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered';


-- 看不同月份的订单延迟率是否存在明显差异
SELECT
    DATE_FORMAT(
        order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,
    COUNT(*) AS delivered_order_count,
    SUM(
        CASE
            WHEN order_delivered_customer_date IS NOT NULL
             AND order_estimated_delivery_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS assessable_order_count,
    SUM(
        CASE
            WHEN order_delivered_customer_date IS NOT NULL
             AND order_estimated_delivery_date IS NOT NULL
             AND order_delivered_customer_date
                 > order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_order_count,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date IS NOT NULL
                 AND order_estimated_delivery_date IS NOT NULL
                 AND order_delivered_customer_date
                     > order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        ) / NULLIF(
            SUM(
                CASE
                    WHEN order_delivered_customer_date IS NOT NULL
                     AND order_estimated_delivery_date IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS late_rate_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
GROUP BY DATE_FORMAT(
    order_purchase_timestamp,
    '%Y-%m'
)
ORDER BY order_month;


-- 查明 2018 年 2—3 月为什么延迟率高
-- 分析实际配送时长与预计送达时间之间的差距，确认这两个月究竟是整体配送时间变长，还是订单更多地超过了承诺日期

SELECT
    DATE_FORMAT(
        order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,
    COUNT(*) AS assessable_order_count,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                DAY,
                order_purchase_timestamp,
                order_delivered_customer_date
            )
        ),
        2
    ) AS avg_actual_delivery_days,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                DAY,
                order_purchase_timestamp,
                order_estimated_delivery_date
            )
        ),
        2
    ) AS avg_estimated_delivery_days,
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_estimated_delivery_date
            )
        ),
        2
    ) AS avg_days_after_estimate
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY DATE_FORMAT(
    order_purchase_timestamp,
    '%Y-%m'
)
ORDER BY order_month;


-- 统计延迟订单的平均延迟天数和最严重的延迟天数
SELECT
    DATE_FORMAT(
        order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,
    COUNT(*) AS late_order_count,
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_estimated_delivery_date
            )
        ),
        2
    ) AS avg_late_days,
    MAX(
        DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        )
    ) AS max_late_days
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_delivered_customer_date
      > order_estimated_delivery_date
GROUP BY DATE_FORMAT(
    order_purchase_timestamp,
    '%Y-%m'
)
ORDER BY order_month;


-- 按客户所在州拆分这两个月的数据，看看哪些地区的延迟率相对较高

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,
    c.customer_state,
    COUNT(*) AS assessable_order_count,
    SUM(
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_order_count,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_rate_pct,
    ROUND(
        AVG(
            CASE
                WHEN o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN DATEDIFF(
                    o.order_delivered_customer_date,
                    o.order_estimated_delivery_date
                )
            END
        ),
        2
    ) AS avg_late_days
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2018-02-01'
  AND o.order_purchase_timestamp < '2018-04-01'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
    c.customer_state
HAVING COUNT(*) >= 30
ORDER BY
    order_month,
    late_rate_pct DESC;


-- --------------------------------------------
-- 分析配送延迟是否影响顾客评分

SELECT
    CASE
        WHEN o.order_delivered_customer_date
             > o.order_estimated_delivery_date
        THEN '延迟送达'
        ELSE '按时或提前送达'
    END AS delivery_group,
    COUNT(*) AS order_count,
    COUNT(r.review_score) AS reviewed_order_count,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date
             > o.order_estimated_delivery_date
        THEN '延迟送达'
        ELSE '按时或提前送达'
    END
ORDER BY delivery_group;


-- 两组订单中，1-5评分分别占多少

SELECT
    CASE
        WHEN o.order_delivered_customer_date
             > o.order_estimated_delivery_date
        THEN '延迟送达'
        ELSE '按时或提前送达'
    END AS delivery_group,
    r.review_score,
    COUNT(*) AS review_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (
            PARTITION BY
                CASE
                    WHEN o.order_delivered_customer_date
                         > o.order_estimated_delivery_date
                    THEN '延迟送达'
                    ELSE '按时或提前送达'
                END
        ),
        2
    ) AS review_percentage
FROM orders o
JOIN (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    delivery_group,
    r.review_score
ORDER BY
    delivery_group,
    r.review_score;
