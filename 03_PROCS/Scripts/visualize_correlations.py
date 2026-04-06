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
DERIVATIVES = os.path.join(PROC_DIR, "derivatives-HCP" if args.controls else "derivatives")
MELODIC_ROOT = os.path.join(DERIVATIVES, "melodic")

THRESHOLD = 0.05

# =====================
# RSN LABELS
# =====================
RSN_LABELS = {
    1: "Visual",
    2: "Visual",
    3: "Visual",
    4: "Default Mode Network",
    5: "Cerebellum",
    6: "Sensorimotor",
    7: "Auditory",
    8: "Executive Control",
    9: "Frontoparietal",
    10: "Frontoparietal"
}

# =====================
# PROCESS
# =====================
all_rows = []

for file in glob.glob(f"{MELODIC_ROOT}/sub-*/func/*.ica/ica_rsn_correlations.txt"):
    subject = file.split(os.sep)[-4].replace("sub-", "")
    print(f"\n🧠 Subject {subject}")

    df = pd.read_csv(file, sep=r"\s+", header=None, names=["RSN", "IC", "corr"])

    for rsn, sub_df in df.groupby("RSN"):
        rsn_name = RSN_LABELS.get(rsn, "Unknown")
        top2 = sub_df.sort_values("corr", ascending=False).head(2)
        best_corr = top2.iloc[0]["corr"]
        selected = best_corr >= THRESHOLD

        # Display compactly with RSN label
        print(f"RSN {rsn} ({rsn_name}): {[(int(row['IC']), round(row['corr'],3)) for _, row in top2.iterrows()]} -> selected: {selected}")

        for rank, (_, row) in zip(["top1", "top2"], top2.iterrows()):
            all_rows.append({
                "subject": subject,
                "RSN": rsn,
                "RSN_name": rsn_name,
                "IC": int(row["IC"]),
                "corr": row["corr"],
                "rank": rank,
                "selected": (rank == "top1") and selected
            })

# =====================
# SAVE RESULTS
# =====================
out_df = pd.DataFrame(all_rows)
out_df.to_csv("rsn_matching_inspection.csv", index=False)

# =====================
# GLOBAL STATS
# =====================
top1 = out_df[out_df["rank"] == "top1"]
above_thresh = top1[top1["corr"] >= THRESHOLD]

print("\n📊 GLOBAL STATS")
print(f"Total RSN matches: {len(top1)}")
print(f"Above threshold ({THRESHOLD}): {len(above_thresh)}")
print(f"Percentage: {100*len(above_thresh)/len(top1):.2f}%")
# =====================
# GLOBAL EXPORT FOR RECONSTRUCTION
# =====================
selected_df = out_df[(out_df["rank"] == "top1") & (out_df["selected"] == True)]

# nom du fichier selon controls ou pas
out_name = "rsn_selected_for_reconstruction_controls.tsv" if args.controls else "rsn_selected_for_reconstruction.tsv"

# format: subject RSN IC
selected_df[["subject", "RSN", "IC"]].to_csv(
    out_name,
    sep="\t",
    index=False,
    header=False
)

print(f"\n💾 Global reconstruction file saved: {out_name}")
