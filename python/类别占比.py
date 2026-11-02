import matplotlib
matplotlib.use("Agg")

import pandas as pd
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei"]
plt.rcParams["axes.unicode_minus"] = False

# 1. 读取数据
FILE_PATH = r"C:\Users\李深\Documents\Codex\olist-ecommerce-analytics\data\输出结果\销售额占比.xlsx"
df = pd.read_excel(FILE_PATH, sheet_name="Result 1")

# 2. 数据预处理：取 Top 10
top10 = df.head(10).copy()

# 中文映射字典
category_map = {
    "beleza_saude": "美妆健康",
    "relogios_presentes": "手表礼品",
    "cama_mesa_banho": "床品家纺",
    "esporte_lazer": "运动休闲",
    "informatica_acessorios": "电脑配件",
    "moveis_decoracao": "家具装饰",
    "utilidades_domesticas": "家居用品",
    "cool_stuff": "潮流商品",
    "automotivo": "汽车用品",
    "ferramentas_jardim": "工具园艺"
}
top10["category_cn"] = top10["product_category"].map(category_map)

# 计算 Top 10 的累计占比
top10["cumulative_pct"] = top10["sales_percentage"].cumsum()

# 3. 绘图 (双轴：左轴销售额，右轴累计占比)
fig, ax1 = plt.subplots(figsize=(12, 6))

# 左轴：柱状图
bars = ax1.bar(top10["category_cn"], top10["sales_amount"], color="#7aa6c2", width=0.6, label="销售额")
ax1.set_ylabel("销售额")

# 修复报错的这两行
ax1.tick_params(axis="x", rotation=45)
plt.setp(ax1.get_xticklabels(), ha="right", rotation_mode="anchor")

# 右轴：折线图
ax2 = ax1.twinx()
line = ax2.plot(top10["category_cn"], top10["cumulative_pct"], color="#c0504d", marker="o", linewidth=2, label="累计占比(%)")
ax2.set_ylabel("累计占比 (%)")
ax2.set_ylim(0, 100) # 占比固定在 0-100

# 4. 添加标注
# 标出前五名的累计占比线（约39.6%）
ax2.axhline(y=39.6, color="gray", linestyle="--", linewidth=1.2, alpha=0.7)
ax2.text(9, 46, "前五合计贡献 39.6%", color="gray", fontsize=10, ha="right")

# 在柱子上标出具体百分比
for i, (bar, pct) in enumerate(zip(bars, top10["sales_percentage"])):
    # 只在柱子上半部分显示百分比文字
    ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() - 10000,
             f"{pct:.1f}%", ha="center", va="top", color="white", fontsize=9, fontweight="bold")

# 合并图例
lines_1, labels_1 = ax1.get_legend_handles_labels()
lines_2, labels_2 = ax2.get_legend_handles_labels()
ax1.legend(lines_1 + lines_2, labels_1 + labels_2, loc="upper right")

ax1.set_title("商品类别销售额集中度：长尾效应明显，前五类合计占 39.6%", fontsize=15, pad=15)

# 隐藏顶部边框
ax1.spines["top"].set_visible(False)
ax2.spines["top"].set_visible(False)

plt.tight_layout()
plt.savefig("category_sales_pareto.png", dpi=300, bbox_inches="tight")
print("已保存 category_sales_pareto.png")