-- ============================================================
-- 02 经营核心指标分析（销售表现）
-- 目的：回答第一个业务问题「电商经营表现如何？」
--       ① 全局总览  ② 月度趋势  ③ 商品类别维度  ④ 地区维度
-- 用法：在 DataGrip 控制台整段执行，逐段观察结果
-- ============================================================
-- 口径说明（与 README「关键数据处理规则」保持一致）：
--   · 经营分析只统计已完成并成功送达的订单（order_status = 'delivered'）
--   · 商品销售额 = order_items.price 之和（不含运费）；
--     order_payments.payment_value 是支付金额，属于另一概念，不混用
--   · order_items 对同一订单可能含多条记录（一单多商品）：
--     必须先按订单汇总金额（子查询），再关联到订单层级，
--     避免金额重复累加；订单数一律 COUNT(DISTINCT order_id)
--   · 客单价（AOV）= 销售额 / 订单数，衡量平均每单成交金额
-- 数据范围：样本数据 delivered 订单约 2016-09 ~ 2018-08
-- ============================================================

-- ---------- 1. 全局总览：总订单数 / 总销售额 / 总客单价 ----------
SELECT
    COUNT(DISTINCT o.order_id)              AS total_orders,   -- 订单数
    ROUND(SUM(oi.order_value), 2)           AS total_sales,    -- 销售额（商品价合计，不含运费）
    ROUND(SUM(oi.order_value)
          / COUNT(DISTINCT o.order_id), 2)  AS avg_order_value -- 客单价 = 销售额 / 订单数
FROM orders o
JOIN (
    SELECT order_id, SUM(price) AS order_value
    FROM order_items
    GROUP BY order_id
) oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- ---------- 2. 月度经营趋势：订单量 / 销售额 / 客单价 ----------
-- 注意：样本为随机抽取，个别月份订单很少甚至缺失（抽样特征，非数据错误）
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id)             AS order_cnt,
    ROUND(SUM(oi.order_value), 2)          AS sales,
    ROUND(SUM(oi.order_value)
          / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN (
    SELECT order_id, SUM(price) AS order_value
    FROM order_items
    GROUP BY order_id
) oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY month;

-- ---------- 3. 商品类别维度：销售额 / 订单数 / 商品件数 ----------
-- 说明：
--   · 类别取自商品表，展示用英文名（翻译表为葡语→英语，COALESCE 兜底未翻译类别）
--   · 一单可能含多个类别的商品：订单数用 COUNT(DISTINCT) 去重，
--     销售额按商品行归入对应类别，是「行级」统计
SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name) AS category,
    COUNT(DISTINCT i.order_id)        AS order_cnt,   -- 该类别涉及的去重订单数
    COUNT(*)                          AS item_cnt,    -- 售出商品件数（order_items 一行=一件）
    ROUND(SUM(i.price), 2)            AS sales        -- 该类别销售额
FROM order_items i
JOIN orders o
    ON i.order_id = o.order_id
   AND o.order_status = 'delivered'
LEFT JOIN products p ON i.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name)
ORDER BY sales DESC
LIMIT 20;   -- 想看全部 72 类，删掉这一行

-- ---------- 4. 地区维度：各州订单量 / 销售额 / 客单价 ----------
-- 说明：customer_state 为客户所在州（巴西 27 州，SP 圣保罗通常体量最大）
SELECT
    c.customer_state                          AS state,
    COUNT(DISTINCT o.order_id)                AS order_cnt,
    ROUND(SUM(oi.order_value), 2)             AS sales,
    ROUND(SUM(oi.order_value)
          / COUNT(DISTINCT o.order_id), 2)    AS avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN (
    SELECT order_id, SUM(price) AS order_value
    FROM order_items
    GROUP BY order_id
) oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY sales DESC;
