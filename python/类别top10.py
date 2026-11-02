import matplotlib
matplotlib.use("Agg")

import pandas as pd
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei"]
plt.rcParams["axes.unicode_minus"] = False

# 1. 读取数据
# 记得替换为你的实际路径
FILE_PATH = r"C:\Users\李深\Documents\Codex\olist-ecommerce-analytics\data\输出结果\商品类别销售表现.xlsx"
df = pd.read_excel(FILE_PATH, sheet_name="Result 1")

# 2. 数据预处理：取 Top 10，并翻译成中文
top10 = df.head(10).copy()

# 类别中英映射字典（根据你之前的文档整理）
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

# 因为横向条形图是从下往上画的，我们需要把数据反转，让第一名在最上面
top10 = top10.iloc[::-1]

# 3. 绘图
fig, ax = plt.subplots(figsize=(10, 6))

# 画横向条形图，使用稍微不同的蓝色
bars = ax.barh(top10["category_cn"], top10["sales_amount"], color="#5b9bd5", height=0.6)

# 4. 细节优化
ax.set_title("商品类别销售额 TOP 10", fontsize=15, pad=15)
ax.set_xlabel("销售额")
ax.set_ylabel("")

# 添加数据标签（在柱子右侧显示具体数值）
for bar in bars:
    width = bar.get_width()
    # 将数值格式化为带千分位的字符串
    label_text = f"{width:,.0f}"
    ax.text(
        width + (width * 0.01), # 稍微向右偏移，避免贴得太紧
        bar.get_y() + bar.get_height() / 2,
        label_text,
        va="center", ha="left", fontsize=10, color="#333333"
    )

# 去掉顶部和右侧的边框线
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

# 让 x 轴稍微留一点空间给最右侧的文字标签
ax.set_xlim(0, top10["sales_amount"].max() * 1.15)

plt.tight_layout()
plt.savefig("category_sales_top10.png", dpi=300, bbox_inches="tight")
print("已保存 category_sales_top10.png")