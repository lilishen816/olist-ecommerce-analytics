# -*- coding: utf-8 -*-
"""
Olist 数据集导入脚本（一键版）
用途：将 9 个 CSV 导入 MySQL（olist_analytics 库）
特点：导入前自动清空目标表（TRUNCATE），可重复运行，结果可控

运行前提：
  1. 已执行 sql/00_schema.sql 完成建库建表
  2. pip install pymysql
  3. 修改下方 DB_CONFIG 和 DATA_DIR
运行：
  python import_data.py
"""

import csv
import os
import sys
import pymysql

# ================== 修改这里 ==================
DB_CONFIG = {
    'host': 'rm-wz94u5xm7324t98xnyo.mysql.rds.aliyuncs.com',   # 在 DataGrip 里右键连接 → 属性 → Host 查看
    'port': 3306,                      # 如果 DataGrip 连接属性里端口不是 3306，改这里
    'user': 'lilishen',
    'password': 'ABCabc1234@',
    'database': 'olist_analytics',
    'charset': 'utf8mb4',
}

# CSV 所在目录（改成你解压数据的文件夹，注意用正斜杠或双反斜杠）
DATA_DIR = 'C:/Users/李深/Documents/Codex/olist-ecommerce-analytics/data/sample_data'
# 导入前是否清空目标表（True = 每张表导入前先 TRUNCATE，可重复运行）
TRUNCATE_FIRST = True

# 表名 -> 文件名
FILES = {
    'customers':    'olist_customers_dataset.csv',
    'orders':       'olist_orders_dataset.csv',
    'order_items':  'olist_order_items_dataset.csv',
    'order_payments': 'olist_order_payments_dataset.csv',
    'order_reviews':  'olist_order_reviews_dataset.csv',
    'products':     'olist_products_dataset.csv',
    'sellers':      'olist_sellers_dataset.csv',
    'geolocation':  'olist_geolocation_dataset.csv',
    'product_category_name_translation': 'product_category_name_translation.csv',
}
# ==============================================


def connect():
    try:
        return pymysql.connect(**DB_CONFIG)
    except Exception as e:
        print('❌ 连接数据库失败，请检查 DB_CONFIG 连接信息')
        print('   错误信息：', e)
        sys.exit(1)


def import_table(conn, table, filepath):
    """导入单个 CSV，空值转 NULL，每 5000 行批量提交。"""
    if TRUNCATE_FIRST:
        try:
            conn.cursor().execute(f'TRUNCATE TABLE {table}')
            conn.commit()
            print(f'  已清空 {table}')
        except Exception as e:
            print(f'  ⚠️ 清空 {table} 失败（表可能不存在），继续导入：{e}')

    total = 0
    batch = []
    with open(filepath, encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f)
        cols = reader.fieldnames
        placeholders = ','.join(['%s'] * len(cols))
        col_str = ','.join(cols)
        insert_sql = f"INSERT INTO {table} ({col_str}) VALUES ({placeholders})"

        for row in reader:
            # 空字符串 -> None，保证 NULL 语义
            values = [row[c].strip() if row.get(c) else None for c in cols]
            batch.append(values)
            total += 1
            if len(batch) >= 5000:
                conn.cursor().executemany(insert_sql, batch)
                conn.commit()
                batch = []
                print(f'  {table}: 已导入 {total:,} 行')

        if batch:
            conn.cursor().executemany(insert_sql, batch)
            conn.commit()
    print(f'✅ {table}: 完成，共 {total:,} 行')


if __name__ == '__main__':
    conn = connect()
    try:
        for table, filename in FILES.items():
            path = os.path.join(DATA_DIR, filename)
            if not os.path.exists(path):
                print(f'⚠️ 文件不存在，跳过：{path}')
                continue
            print(f'开始导入 {filename} ...')
            import_table(conn, table, path)
    finally:
        conn.close()
    print('🎉 全部导入完成！')
