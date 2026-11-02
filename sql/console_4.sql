-- ============================================================
-- Olist E-commerce Analytics · 建库建表脚本
-- 目标：MySQL 8.0
-- 用法：在 DataGrip 中打开 SQL 控制台，整段执行即可
-- ============================================================

CREATE DATABASE IF NOT EXISTS olist_analytics DEFAULT CHARACTER SET utf8mb4;
USE olist_analytics;

-- ---------- 1. 客户表 ----------
CREATE TABLE customers (
    customer_id              VARCHAR(64) PRIMARY KEY,
    customer_unique_id       VARCHAR(64) NOT NULL,
    customer_zip_code_prefix VARCHAR(8),
    customer_city            VARCHAR(64),
    customer_state           CHAR(2)
);

-- ---------- 2. 订单主表 ----------
CREATE TABLE orders (
    order_id                       VARCHAR(64) PRIMARY KEY,
    customer_id                    VARCHAR(64),
    order_status                   VARCHAR(32),
    order_purchase_timestamp       DATETIME,
    order_approved_at              DATETIME,
    order_delivered_carrier_date   DATETIME,
    order_delivered_customer_date  DATETIME,
    order_estimated_delivery_date  DATETIME
);

-- ---------- 3. 订单商品明细表 ----------
CREATE TABLE order_items (
    order_id           VARCHAR(64),
    order_item_id      INT,
    product_id         VARCHAR(64),
    seller_id          VARCHAR(64),
    shipping_limit_date DATETIME,
    price              DECIMAL(10,2),
    freight_value      DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- ---------- 4. 支付表 ----------
CREATE TABLE order_payments (
    order_id            VARCHAR(64),
    payment_sequential  INT,
    payment_type        VARCHAR(32),
    payment_installments INT,
    payment_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- ---------- 5. 评价表 ----------
CREATE TABLE order_reviews (
    review_id               VARCHAR(64) PRIMARY KEY,
    order_id                VARCHAR(64),
    review_score            INT,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    VARCHAR(32),
    review_answer_timestamp VARCHAR(32)
);

-- ---------- 6. 商品表 ----------
CREATE TABLE products (
    product_id                 VARCHAR(64) PRIMARY KEY,
    product_category_name      VARCHAR(128),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

-- ---------- 7. 商家表 ----------
CREATE TABLE sellers (
    seller_id              VARCHAR(64) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(8),
    seller_city            VARCHAR(64),
    seller_state           CHAR(2)
);

-- ---------- 8. 地理位置表（约100万行） ----------
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(8),
    geolocation_lat             DECIMAL(10,8),
    geolocation_lng             DECIMAL(10,8),
    geolocation_city            VARCHAR(64),
    geolocation_state           CHAR(2)
);

-- ---------- 9. 商品类别翻译表 ----------
CREATE TABLE product_category_name_translation (
    product_category_name        VARCHAR(128) PRIMARY KEY,
    product_category_name_english VARCHAR(128)
);

-- reviews里的emoj表情要用不同编码格式
ALTER DATABASE olist_analytics CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE order_reviews CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 主键重复处理
ALTER TABLE order_reviews DROP PRIMARY KEY;
ALTER TABLE order_reviews ADD PRIMARY KEY (review_id, order_id);

-- 成功导入数据后核对
SELECT 'customers' AS t, COUNT(*) AS cnt FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'translation', COUNT(*) FROM product_category_name_translation;


-- ============================================================
-- 01 数据质量检查
-- 目的：系统检查 9 张表的主键唯一性、订单状态、空值、关联完整性
-- 用法：在 DataGrip 控制台整段执行，逐段观察结果
-- ============================================================

-- ---------- 1. 各表行数核对（和 CSV 行数对比） ----------
SELECT 'customers' AS tbl, COUNT(*) AS row_cnt FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'translation', COUNT(*) FROM product_category_name_translation;

-- ---------- 2. 主键唯一性检查 ----------
-- 方法：总数 vs 去重数，两者不一致说明存在重复

-- 2.1 orders: 主键 order_id
SELECT COUNT(*) AS total, COUNT(DISTINCT order_id) AS unique_order_id FROM orders;

-- 2.2 order_items: 联合主键 (order_id, order_item_id)
SELECT COUNT(*) AS total,
       COUNT(DISTINCT CONCAT(order_id, '|', order_item_id)) AS unique_key
FROM order_items;

-- 2.3 order_payments: 联合主键 (order_id, payment_sequential)
SELECT COUNT(*) AS total,
       COUNT(DISTINCT CONCAT(order_id, '|', payment_sequential)) AS unique_key
FROM order_payments;

-- 2.4 order_reviews: 联合主键 (review_id, order_id)
--     注意：review_id 单列重复是源数据已知质量问题（36 个重复）
SELECT COUNT(*) AS total, COUNT(DISTINCT review_id) AS unique_review_id FROM order_reviews;

-- 找出重复的 review_id（万能公式：GROUP BY + HAVING）
SELECT review_id, COUNT(*) AS cnt
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

-- 2.5 其他单主键表
SELECT COUNT(*) AS total, COUNT(DISTINCT customer_id) AS unique_key FROM customers;
SELECT COUNT(*) AS total, COUNT(DISTINCT product_id) AS unique_key FROM products;
SELECT COUNT(*) AS total, COUNT(DISTINCT seller_id) AS unique_key FROM sellers;
SELECT COUNT(*) AS total, COUNT(DISTINCT product_category_name) AS unique_key
FROM product_category_name_translation;
-- 注：geolocation 无主键（一个邮编对应多个坐标点，正常）

-- ---------- 3. 订单状态分布 ----------
SELECT order_status, COUNT(*) AS cnt
FROM orders
GROUP BY order_status
ORDER BY cnt DESC;

-- ---------- 4. 关键空值检查 ----------
-- 4.1 订单表各时间字段空值（NULL = 该环节未发生/未记录）
SELECT
    COUNT(*) AS total_orders,
    SUM(order_purchase_timestamp IS NULL)       AS null_purchase,
    SUM(order_approved_at IS NULL)              AS null_approved,
    SUM(order_delivered_carrier_date IS NULL)   AS null_carrier,
    SUM(order_delivered_customer_date IS NULL)  AS null_delivered_customer,
    SUM(order_estimated_delivery_date IS NULL)  AS null_estimated
FROM orders;

-- 4.2 异常检查：状态=已送达，但实际送达时间为空（不应该出现）
SELECT COUNT(*) AS delivered_without_time
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 4.3 评价表评分空值
SELECT COUNT(*) AS total_reviews, SUM(review_score IS NULL) AS null_score
FROM order_reviews;

-- ---------- 5. 关联完整性检查（孤儿记录） ----------
-- 5.1 订单 -> 客户：孤儿订单（没有客户的订单）
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 5.2 订单商品 -> 订单：孤儿商品行
SELECT COUNT(*) AS orphan_items
FROM order_items i
LEFT JOIN orders o ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 5.3 订单商品 -> 商品：没有商品信息的行
SELECT COUNT(*) AS items_without_product
FROM order_items i
LEFT JOIN products p ON i.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 假设 orders 表是 utf8mb4_0900_ai_ci，将 reviews 的关联字段改过来
ALTER TABLE order_reviews
MODIFY COLUMN order_id VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
-- 5.4 评价 -> 订单：孤儿评价

SELECT COUNT(*) AS orphan_reviews
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 5.5 支付 -> 订单：孤儿支付
SELECT COUNT(*) AS orphan_payments
FROM order_payments p
LEFT JOIN orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;
