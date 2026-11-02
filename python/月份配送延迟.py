import matplotlib
matplotlib.use("Agg")

import pandas as pd
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei"]
plt.rcParams["axes.unicode_minus"] = False

# 1. 读取数据
FILE_PATH = r"C:\Users\李深\Documents\Codex\olist-ecommerce-analytics\data\输出结果\延迟率_月份.xlsx"
df = pd.read_excel(FILE_PATH, sheet_name="Result 1")

# 2. 数据过滤与排序
# 剔除 2016-09 极小样本（仅 1 笔，延迟率 100%，会破坏坐标轴比例）
df = df[df["order_month"] != "2016-09"].copy()
df = df.sort_values("order_month").reset_index(drop=True)

# 3. 绘图
fig, ax = plt.subplots(figsize=(12, 5))

# 画折线图
ax.plot(df["order_month"], df["late_rate_pct"],
        color="#c0504d", marker="o", markersize=6, linewidth=2.5)

# 4. 背景色块高亮重点月份（2018-02 和 2018-03）
# 找到对应月份的索引位置
idx_feb = df[df["order_month"] == "2018-02"].index[0]
idx_mar = df[df["order_month"] == "2018-03"].index[0]
# 画半透明红色背景带
ax.axvspan(idx_feb - 0.5, idx_mar + 0.5, color="#f4b183", alpha=0.3, label="2018年2-3月高发期")

# 5. 添加重点标注
# 标注 2018-03 (最高峰)
ax.annotate(f"20.07%\n(最高峰)",
            xy=(idx_mar, df.loc[idx_mar, "late_rate_pct"]),
            xytext=(0, 15), textcoords="offset points",
            ha="center", va="bottom", color="#c0504d", fontsize=10, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="#c0504d", alpha=0.9))

# 标注 2018-02
ax.annotate(f"16.76%",
            xy=(idx_feb, df.loc[idx_feb, "late_rate_pct"]),
            xytext=(-15, 5), textcoords="offset points",
            ha="right", va="bottom", color="#c0504d", fontsize=10, fontweight="bold")

# 标注 2017-11 的另一波小高峰
idx_nov = df[df["order_month"] == "2017-11"].index[0]
ax.annotate(f"14.62%",
            xy=(idx_nov, df.loc[idx_nov, "late_rate_pct"]),
            xytext=(0, 10), textcoords="offset points",
            ha="center", va="bottom", color="#c0504d", fontsize=10, fontweight="bold")

# 6. 细节美化
ax.set_title("月度配送延迟率趋势：2018年2-3月延迟率显著飙升", fontsize=15, pad=15)
ax.set_xlabel("月份", labelpad=10)
ax.set_ylabel("延迟率 (%)")
ax.set_ylim(0, 25) # Y轴固定在 0-25% 让趋势更清晰
ax.tick_params(axis="x", rotation=45)
plt.setp(ax.get_xticklabels(), ha="right", rotation_mode="anchor")

# 添加水平网格线，方便看数值
ax.grid(axis="y", linestyle="--", alpha=0.5)
ax.legend(loc="upper left")

# 隐藏右边和上边的边框线
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

plt.tight_layout()
plt.savefig("monthly_late_rate.png", dpi=300, bbox_inches="tight")
print("已保存 monthly_late_rate.png")