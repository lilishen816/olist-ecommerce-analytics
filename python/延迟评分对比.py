import matplotlib
matplotlib.use("Agg")

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei"]
plt.rcParams["axes.unicode_minus"] = False
plt.rcParams["font.size"] = 13  # 【优化】全局基础字体放大

# 1. 读取数据
FILE_PATH = r"C:\Users\李深\Documents\Codex\olist-ecommerce-analytics\data\输出结果\评分_延迟.xlsx"
df = pd.read_excel(FILE_PATH, sheet_name="Result 1")

# 2. 数据预处理
avg_scores = df.groupby("delivery_group").apply(
    lambda g: (g["review_score"] * g["review_count"]).sum() / g["review_count"].sum()
).reset_index(name="avg_score")

def score_group(x):
    if x <= 2.5: return "低分(≤2.5)"
    elif x < 4: return "中评(2.5-4)"
    else: return "高分(≥4)"

df["score_group"] = df["review_score"].apply(score_group)
dist = df.groupby(["delivery_group", "score_group"])["review_count"].sum().unstack(fill_value=0)
dist_pct = dist.div(dist.sum(axis=1), axis=0) * 100
dist_pct = dist_pct[["低分(≤2.5)", "中评(2.5-4)", "高分(≥4)"]]

# 3. 开始绘图（画布稍微加宽，增加间距）
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6.5), gridspec_kw={'width_ratios': [1, 1.3], 'wspace': 0.15})

# ==================== 左图：平均评分对比 ====================
colors_avg = ["#d65f5f", "#7eb875"] # 柔和一点的红绿
# 【优化】柱子变细
bars = ax1.bar(avg_scores["delivery_group"], avg_scores["avg_score"], color=colors_avg, width=0.35)

# 【优化】字体放大
for bar in bars:
    height = bar.get_height()
    ax1.text(bar.get_x() + bar.get_width()/2, height/2,
             f"{height:.2f}", ha="center", va="center", color="white", fontsize=22, fontweight="bold")

ax1.set_ylabel("平均评分 (1-5分)", fontsize=15)
ax1.set_ylim(0, 5.5) # 顶部多留点空间
ax1.set_yticks([0, 1, 2, 3, 4, 5])
ax1.tick_params(axis='x', labelsize=14)
ax1.tick_params(axis='y', labelsize=13)

# 【优化】差值标注放大并上移
score_delay = avg_scores.loc[avg_scores["delivery_group"] == "延迟送达", "avg_score"].values[0]
score_ontime = avg_scores.loc[avg_scores["delivery_group"] == "按时或提前送达", "avg_score"].values[0]
ax1.annotate(f"相差 {score_ontime - score_delay:.2f} 分",
             xy=(0.5, max(score_delay, score_ontime) + 0.6),
             ha="center", color="#d65f5f", fontsize=16, fontweight="bold")
# 调整连接虚线的高度
ax1.plot([0, 0, 1, 1], [score_delay, max(score_delay, score_ontime) + 0.4, max(score_delay, score_ontime) + 0.4, score_ontime],
         color="#888888", linestyle="--", linewidth=1.5)

ax1.spines["top"].set_visible(False)
ax1.spines["right"].set_visible(False)
ax1.spines["left"].set_linewidth(1.2)
ax1.spines["bottom"].set_linewidth(1.2)

# ==================== 右图：评分分布（100% 堆叠图） ====================
colors_dist = ["#d65f5f", "#f4b183", "#7eb875"]
left = np.zeros(len(dist_pct))
for i, col in enumerate(dist_pct.columns):
    # 【优化】柱子变细
    ax2.barh(dist_pct.index, dist_pct[col], left=left, color=colors_dist[i], height=0.35, label=col)
    for j, val in enumerate(dist_pct[col]):
        if val > 5:
            # 【优化】字体放大
            ax2.text(left[j] + val/2, j, f"{val:.0f}%", ha="center", va="center",
                     color="white", fontsize=18, fontweight="bold")
    left += dist_pct[col].values

ax2.set_xlim(0, 100)
ax2.set_xticks([])  # 隐藏底部刻度
ax2.set_yticks(range(len(dist_pct.index)))
ax2.set_yticklabels(dist_pct.index, fontsize=15)
ax2.tick_params(axis='y', length=0) # 去除Y轴刻度小短线

# 【优化】图例位置调高，字体放大
ax2.legend(ncol=3, loc="lower center", bbox_to_anchor=(0.5, 1.02), frameon=False, fontsize=15)

# 【优化】完全隐藏右图的边框，变成极简色块
ax2.spines["top"].set_visible(False)
ax2.spines["right"].set_visible(False)
ax2.spines["bottom"].set_visible(False)
ax2.spines["left"].set_visible(False)

# 全局总标题
fig.suptitle("配送时效与顾客满意度：延迟送达导致低分率飙升至 54%", fontsize=18, fontweight="bold", y=0.98)

plt.tight_layout()
plt.subplots_adjust(top=0.82) # 给总标题和右图图例留出足够空间
plt.savefig("delivery_review_combo.png", dpi=300, bbox_inches="tight")
print("已保存优化后的 delivery_review_combo.png")