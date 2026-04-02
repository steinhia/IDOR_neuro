import numpy as np
import pandas as pd
import glob

# 1. Charger les scores
scores = pd.read_csv("behavioral_scores.csv")  # colonnes: subject_id, score1, score2...

# Dossier XCP-D
xcpd_dir="/home/alexandra/rs-fMRI/xcpd_out_old"

# Récupérer tous les fichiers de corrélation
from nilearn import image, input_data

atlas_file = "atlas-4S156Parcels_res-01_dseg.nii.gz"
atlas_img = image.load_img(atlas_file)

masker = input_data.NiftiLabelsMasker(labels_img=atlas_img, standardize=True)
time_series = masker.fit_transform(bold_file)  # bold_file = ton fichier BOLD denoised





# Réindexer les scores pour être sûr que l'ordre correspond
scores = scores.set_index("subject_id").loc[subject_ids]

from scipy.stats import pearsonr

score_name = "score1"
correlations = []
pvals = []

for i in range(connectivity_data.shape[1]):
    r, p = pearsonr(connectivity_data[:, i], scores[score_name])
    correlations.append(r)
    pvals.append(p)

correlations = np.array(correlations)
pvals = np.array(pvals)