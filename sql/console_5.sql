
-- ==========================================
-- Olist 电商经营表现分析
-- 第4天：月度核心经营指标
-- 统计范围：已送达订单
-- ==========================================
-- 订单量，销售额，客单价（不带运费）
SELECT
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS sales_amount,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL;

-- 按时间排序
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,

    COUNT(DISTINCT o.order_id) AS order_count,

    ROUND(SUM(oi.price), 2) AS sales_amount,

    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value

FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL

GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')

ORDER BY order_month;

-- 检查缺失月份
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    order_status,
    COUNT(DISTINCT order_id) AS order_count
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m'),
    order_status
ORDER BY order_month, order_status;


-- 哪些商品类别贡献了更多销售额？订单量和销售额排名是否一致？
SELECT
    p.product_category_name AS product_category,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(oi.order_item_id) AS item_count,
    ROUND(SUM(oi.price), 2) AS sales_amount,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY p.product_category_name
ORDER BY sales_amount DESC;


-- 检查为什么有一个null
SELECT
    COUNT(*) AS item_count,
    COUNT(DISTINCT oi.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS sales_amount
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND p.product_category_name IS NULL;


-- 确认缺失类别涉及多少种商品

SELECT
    p.product_category_name,
    COUNT(*) AS item_count,
    COUNT(DISTINCT oi.product_id) AS product_count,
    ROUND(SUM(oi.price), 2) AS sales_amount
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND p.product_category_name IS NULL
GROUP BY p.product_category_name;


-- 统计相关商品的类别缺失和翻译匹配情况
SELECT
    COUNT(*) AS total_products,
    SUM(
        CASE
            WHEN p.product_category_name IS NULL THEN 1
            ELSE 0
        END
    ) AS null_category_products,
    SUM(
        CASE
            WHEN t.product_category_name IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS translated_products
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_id IN (
    SELECT DISTINCT oi.product_id
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM products p2
          WHERE p2.product_id = oi.product_id
            AND p2.product_category_name IS NOT NULL
      )
);


-- 检查缺失的其他商品信息是否存在
-- 都是null
SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty
FROM products
WHERE product_category_name IS NULL
LIMIT 20;


-- 分析各商品类别的销售额占比（未分类的也在）

SELECT
    COALESCE(p.product_category_name, '未分类') AS product_category,
    ROUND(SUM(oi.price), 2) AS sales_amount,
    ROUND(
        SUM(oi.price) * 100.0
        / (
            SELECT SUM(oi2.price)
            FROM orders o2
            JOIN order_items oi2
                ON o2.order_id = oi2.order_id
            WHERE o2.order_status = 'delivered'
              AND o2.order_purchase_timestamp IS NOT NULL
        ),
        2
    ) AS sales_percentage
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY COALESCE(p.product_category_name, '未分类')
ORDER BY sales_amount DESC;
