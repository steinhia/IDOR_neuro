#!/bin/bash

# Répertoire contenant les résultats xcp-d
xcpd_dir="/home/alexandra/rs-fMRI/xcpd_out"

# Définir les types de fichiers attendus par sujet
declare -A expected_files

############################################
# ANAT (surfaces, scalaires…)
############################################
expected_files[anat]="
_hemi-L_space-fsLR_den-32k_white.surf
_hemi-L_space-fsLR_den-32k_pial.surf
_hemi-L_space-fsLR_den-32k_desc-hcp_midthickness.surf
_hemi-L_space-fsLR_den-32k_desc-hcp_inflated.surf

_space-fsLR_den-91k_curv.dscalar
_space-fsLR_den-91k_sulc.dscalar
_space-fsLR_den-91k_thickness.dscalar

_space-fsLR_seg-4S156Parcels_stat-mean_desc-curv_morph
_space-fsLR_seg-4S156Parcels_stat-mean_desc-sulc_morph

_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz
"

############################################
# FUNC (dtseries, parcellaire…)
# QUALITY CONTROL
############################################
expected_files[func]="
_task-rest_space-fsLR_den-91k_desc-denoised_bold.dtseries.nii
_task-rest_space-fsLR_seg-4S156Parcels_den-91k_stat-coverage_boldmap
_task-rest_desc-abcc_qc.hdf5
_task-rest_outliers.tsv
_task-rest_motion.tsv
_task-rest_design.tsv
"

############################################

echo "===== Vérification des fichiers XCP-D dans $xcpd_dir ====="
echo

for subj_path in "$xcpd_dir"/sub-*; do
    [ -d "$subj_path" ] || continue  # ignore fichiers isolés
    subj=$(basename "$subj_path")

    echo "### Sujet: $subj ###"

    for type in "${!expected_files[@]}"; do
        echo " Vérification $type:"

        found_any=false

        for pattern in ${expected_files[$type]}; do
            found=false

            # Recherche dans tous les sous-dossiers
            while IFS= read -r f; do
                if [ -f "$f" ]; then
                    echo "  ✅ trouvé: $f"
                    found=true
                    found_any=true
                fi
            done < <(find "$subj_path" -type f -name "*$pattern*" 2>/dev/null)

            if [ "$found" = false ]; then
                echo "  ❌ manquant: $pattern"
            fi
        done

        if [ "$found_any" = false ]; then
            echo "  ⚠️ Aucun fichier $type trouvé pour ce sujet."
        fi
    done

    echo "-------------------------------------------"
done
