#!/bin/bash

# -------------------------------------------------
# Script XCP-D post-processing fMRIPrep
# -------------------------------------------------

# Chemins
dataset_dir="$(pwd)/../dataset"
derivatives_dir="/home/alexandra/rs-fMRI/derivatives"
xcpd_out_dir="/home/alexandra/rs-fMRI/xcpd_atlas"
fs_license="$(pwd)/../Licence/license.txt"

# Participants à traiter
participants=("010" "048" "366" "662" "706" "708" "711" "718" "720" "721" "725" "743" "751" "762" "782" "789")
#participants=("762")

# Créer le dossier de sortie si nécessaire
mkdir -p "$xcpd_out_dir"

# Boucle sur les participants
for participant in "${participants[@]}"; do
    echo "--------------------------------------"
    echo "Traitement du participant $participant..."

    #--atlases Schaefer100 \
    docker run --rm -ti \
      --user root \
      -v "$dataset_dir":/data \
      -v "$derivatives_dir":/deriv \
      -v "$xcpd_out_dir":/out \
      -v "$fs_license":/opt/freesurfer/license.txt \
      pennlinc/xcp_d:0.12.0 \
      /deriv/fmriprep /out participant \
        --mode none \
        --fs-license-file /opt/freesurfer/license.txt \
        --participant-label $participant \
        --input-type fmriprep \
        --task-id rest \
        --dummy-scans auto \
        --atlases 4S156Parcels \
        --abcc-qc y \
        --combine-runs y \
        --nuisance-regressors 36P \
        --despike y \
        --fd-thresh 0.5 \
        --file-format cifti \
        --linc-qc n \
        --min-coverage 0.8 \
        --motion-filter-type none \
        --output-type interpolated \
        --warp-surfaces-native2std y \
        --smoothing 4 \
        --lower-bpf 0.009 \
        --upper-bpf 0.08 \
        --min-time 240 \
        --nprocs 16 --mem-mb 64000\
        -vv || {
            echo "⚠️ Erreur pour $participant, on passe au suivant"
            continue
        }
    echo "Terminé pour $participant"
done

echo "--------------------------------------"
echo "Tous les participants ont été traités."
