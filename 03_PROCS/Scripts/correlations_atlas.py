import pandas as pd
import glob
import os
from scipy.stats import pearsonr

THRESHOLD = 0.05

DERIVATIVES = "../PROC_DATA/derivatives"
MELODIC_ROOT = os.path.join(DERIVATIVES, "melodic")

scores = pd.read_csv("behavioral_scores.csv")
scores = scores.set_index("subject_id")

all_data = []

for file in glob.glob(f"{MELODIC_ROOT}/sub-*/func/*.ica/ica_rsn_correlations.txt"):

    subject = file.split("/")[-4].replace("sub-", "")
    
    df = pd.read_csv(file, sep=r"\s+", header=None)
    df.columns = ["RSN", "IC", "corr"]

    # best IC per RSN
    best = df.loc[df.groupby("RSN")["corr"].idxmax()]
    
    # apply threshold
    best["corr"] = best["corr"].apply(lambda x: x if x >= THRESHOLD else 0)

    best = best.set_index("RSN")["corr"]
    best["subject_id"] = subject

    all_data.append(best)

data = pd.DataFrame(all_data)
data = data.set_index("subject_id")

# join with scores
data = data.join(scores, how="inner")

# correlations
results = []

for rsn in data.columns[:-len(scores.columns)]:
    for score in scores.columns:
        r, p = pearsonr(data[rsn], data[score])
        results.append({"RSN": rsn, "score": score, "r": r, "p": p})

results_df = pd.DataFrame(results)
results_df.to_csv("rsn_behavior_correlations.csv", index=False)

print("✅ Done")
