import matplotlib
matplotlib.use("Agg")  # 只保存不弹窗，最稳，避免 PyCharm backend 报错

import pandas as pd
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["Microsoft YaHei"]  # Windows 中文字体
plt.rcParams["axes.unicode_minus"] = False

df = pd.read_excel(r"C:\Users\李深\Documents\Codex\olist-ecommerce-analytics\data\输出结果\评分_延迟.xlsx", sheet_name="Result 1")

def score_group(x):
    if x <= 2.5:
        return "低分(≤2.5)"
    elif x < 4:
        return "中评(2.5-4)"
    else:
        return "高分(≥4)"

df["score_group"] = df["review_score"].apply(score_group)

summary = (
    df.groupby(["delivery_group", "score_group"], as_index=False)["review_count"]
      .sum()
)
summary["total"] = summary.groupby("delivery_group")["review_count"].transform("sum")
summary["pct"] = summary["review_count"] / summary["total"] * 100

order = ["低分(≤2.5)", "中评(2.5-4)", "高分(≥4)"]
summary["score_group"] = pd.Categorical(summary["score_group"], categories=order, ordered=True)
summary = summary.sort_values(["delivery_group", "score_group"])

print(summary)
summary.to_csv("review_score_group_summary.csv", index=False, encoding="utf-8-sig")

pivot = summary.pivot(index="delivery_group", columns="score_group", values="pct").fillna(0)
pivot = pivot[order]

ax = pivot.plot(kind="barh", stacked=True, figsize=(8, 3.5), color=["#c0504d", "#f4b183", "#70ad47"])
ax.set_xlabel("占比 (%)")
ax.set_ylabel("")
ax.set_title("延迟送达订单的低分占比明显更高")
ax.legend(title="评分分组", bbox_to_anchor=(1.02, 1), loc="upper left")

for container in ax.containers:
    ax.bar_label(container, fmt="%.1f%%", label_type="center", fontsize=8, color="white")

plt.tight_layout()
plt.savefig("review_score_group_stacked.png", dpi=300, bbox_inches="tight")
print("已保存 review_score_group_stacked.png")