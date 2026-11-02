import matplotlib
matplotlib.use("Agg")

import pandas as pd
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei"]
plt.rcParams["axes.unicode_minus"] = False

# 注意替换为你的实际路径，建议加上 r 前缀
FILE_PATH = r"C:\Users\李深\Documents\Codex\olist-ecommerce-analytics\data\输出结果\月份销售.xlsx"
df = pd.read_excel(FILE_PATH, sheet_name="Result 1")
df = df.sort_values("order_month").reset_index(drop=True)

# 加宽画布
fig, ax1 = plt.subplots(figsize=(14, 6))

# 左轴：销售额柱状图
ax1.bar(df["order_month"], df["sales_amount"], color="#7aa6c2", label="销售额")
ax1.set_xlabel("月份", labelpad=10)
ax1.set_ylabel("销售额")
ax1.tick_params(axis="x", rotation=45)  # 倾斜标签

# 增加Y轴顶部留白，防止标注贴边
ax1.set_ylim(0, df["sales_amount"].max() * 1.2)

# 右轴：订单量折线
ax2 = ax1.twinx()
ax2.plot(df["order_month"], df["order_count"], color="#c0504d", marker="o", linewidth=2, label="订单量")
ax2.set_ylabel("订单量")
ax2.set_ylim(0, df["order_count"].max() * 1.15) # 右侧也留白

# 标注关键点
max_sales_idx = df["sales_amount"].idxmax()
max_order_idx = df["order_count"].idxmax()

# 销售额最高：向上偏移，加白色背景框
ax1.annotate(
    f"销售额最高\n{df.loc[max_sales_idx, 'sales_amount']:,.0f}",
    xy=(max_sales_idx, df.loc[max_sales_idx, "sales_amount"]),
    xytext=(0, 15),
    textcoords="offset points",
    ha="center", va="bottom",
    fontsize=10, color="#1f4e79",
    bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="#1f4e79", alpha=0.9)
)

# 订单量最高：向右下偏移避开折线，加白色背景框
ax2.annotate(
    f"订单量最高\n{df.loc[max_order_idx, 'order_count']:,}",
    xy=(max_order_idx, df.loc[max_order_idx, "order_count"]),
    xytext=(20, 10),
    textcoords="offset points",
    ha="left", va="bottom",
    fontsize=10, color="#c0504d",
    bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="#c0504d", alpha=0.9)
)

# 合并图例，放在左上角并加半透明背景
lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc="upper left", framealpha=0.9)

ax1.set_title("月度销售额与订单量：2018-05 销售额最高，2017-11 订单量最高", fontsize=14, pad=15)

# 优化X轴标签对齐
plt.xticks(rotation=45, ha='right')

plt.tight_layout()
plt.savefig("monthly_sales_orders.png", dpi=300, bbox_inches="tight")
print("已保存优化后的 monthly_sales_orders.png")