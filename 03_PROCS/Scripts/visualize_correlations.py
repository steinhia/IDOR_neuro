import pandas as pd
import glob
import os
import argparse

# =====================
# ARGUMENTS
# =====================
parser = argparse.ArgumentParser()
parser.add_argument("--controls", action="store_true")
args = parser.parse_args()

# =====================
# PATHS
# =====================
PROC_DIR = os.path.join(os.getcwd(), "../PROC_DATA")

if args.controls:
    print("👉 CONTROLS mode")
    DERIVATIVES = os.path.join(PROC_DIR, "derivatives-HCP")
else:
    print("👉 NORMAL mode")
    DERIVATIVES = os.path.join(PROC_DIR, "derivatives")

MELODIC_ROOT = os.path.join(DERIVATIVES, "melodic")

THRESHOLD = 0.05

# =====================
# PROCESS
# =====================
all_rows = []

for file in glob.glob(f"{MELODIC_ROOT}/sub-*/func/*.ica/ica_rsn_correlations.txt"):

    subject = file.split("/")[-4].replace("sub-", "")
    print(f"\n🧠 {subject}")

    df = pd.read_csv(file, sep=r"\s+", header=None)
    df.columns = ["RSN", "IC", "corr"]

    for rsn in sorted(df["RSN"].unique()):

        sub_df = df[df["RSN"] == rsn].sort_values("corr", ascending=False)

        top2 = sub_df.head(2)

        # best match
        best = top2.iloc[0]
        selected = best["corr"] >= THRESHOLD

        print(f"RSN {rsn}:")
        print(top2)
        print(f"👉 selected: {selected} (corr={best['corr']:.3f})")

        for i, row in top2.iterrows():
            all_rows.append({
                "subject": subject,
                "RSN": rsn,
                "IC": row["IC"],
                "corr": row["corr"],
                "rank": "top1" if i == top2.index[0] else "top2",
                "selected": (i == top2.index[0]) and selected
            })

# =====================
# SAVE
# =====================
out_df = pd.DataFrame(all_rows)
out_df.to_csv("rsn_matching_inspection.csv", index=False)

# =====================
# GLOBAL STATS
# =====================
print("\n📊 GLOBAL STATS")

above_thresh = out_df[(out_df["rank"] == "top1") & (out_df["corr"] >= THRESHOLD)]
total = out_df[out_df["rank"] == "top1"]

print(f"Total RSN matches: {len(total)}")
print(f"Above threshold ({THRESHOLD}): {len(above_thresh)}")
print(f"Percentage: {100*len(above_thresh)/len(total):.2f}%")
