import matplotlib
matplotlib.use("Agg")

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei"]
plt.rcParams["axes.unicode_minus"] = False

# 1. 读取数据
FILE_PATH = r"C:\Users\李深\Documents\Codex\olist-ecommerce-analytics\data\输出结果\延迟配送_地区.xlsx"
df = pd.read_excel(FILE_PATH, sheet_name="Result 1")

# 2. 数据转换：转成透视表，行是州，列是月份
pivot_df = df.pivot(index="customer_state", columns="order_month", values="late_rate_pct")

# 按 2018-03 的延迟率降序排序，这样最高的排在左边，视觉上更直观
pivot_df = pivot_df.sort_values(by="2018-03", ascending=False)

# 3. 绘图
fig, ax = plt.subplots(figsize=(12, 6))

# 设置柱子的宽度和 X 轴位置
x = np.arange(len(pivot_df.index))
width = 0.35

# 绘制两个月份的柱子
bars1 = ax.bar(x - width/2, pivot_df["2018-02"], width, label="2018年2月", color="#7aa6c2")
bars2 = ax.bar(x + width/2, pivot_df["2018-03"], width, label="2018年3月", color="#c0504d")

# 4. 添加数据标签
for bars in [bars1, bars2]:
    for bar in bars:
        height = bar.get_height()
        # 如果数值为 NaN（某月某州订单不足30被过滤），跳过
        if pd.isna(height): continue
        ax.annotate(f"{height:.1f}%",
                    xy=(bar.get_x() + bar.get_width() / 2, height),
                    xytext=(0, 3),  # 垂直偏移 3 个点
                    textcoords="offset points",
                    ha="center", va="bottom", fontsize=9, color="#333333")

# 5. 细节美化
ax.set_title("2018年2-3月重点州配送延迟率对比：RJ、SC、BA 等州处于高位", fontsize=15, pad=15)
ax.set_xlabel("顾客所在州", labelpad=10)
ax.set_ylabel("配送延迟率 (%)")
ax.set_xticks(x)
ax.set_xticklabels(pivot_df.index)
ax.set_ylim(0, 45) # 顶部留出空间放标签

# 添加图例
ax.legend(loc="upper right", framealpha=0.9)

# 隐藏顶部和右侧边框
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

# 添加 Y 轴水平网格线
ax.grid(axis="y", linestyle="--", alpha=0.5)

plt.tight_layout()
plt.savefig("region_late_rates.png", dpi=300, bbox_inches="tight")
print("已保存 region_late_rates.png")