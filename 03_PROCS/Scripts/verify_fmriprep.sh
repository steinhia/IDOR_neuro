#!/bin/bash

# ==============================
# Dataset selection via argument
# ==============================

if [[ "$1" == "--controls" ]]; then
    derivatives_dir="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/PROC_DATA/derivatives-HCP/fmriprep"
else
    derivatives_dir="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/PROC_DATA/derivatives/fmriprep"
fi

# Directory containing fmriprep results
# (set above depending on dataset)

# Define expected file types per subject
declare -A expected_files

# anat files
# anat/sub-XXXX
expected_files[anat]="_T1w.nii.gz _desc-preproc_T1w.nii.gz _space-MNI152NLin6Asym_res-2_desc-brain_mask.nii.gz _desc-aseg_dseg.nii.gz _desc-aparcaseg_dseg.nii.gz"

# func files
expected_files[func]="_task-rest_space-fsLR_den-91k_bold.dtseries.nii _bold.nii.gz _task-rest_desc-confounds_timeseries.tsv"


echo "===== Checking fmriprep outputs in $derivatives_dir ====="
echo

for subj_path in "$derivatives_dir"/sub-*; do
    if [ ! -d "$subj_path" ]; then
      continue  # skip if not a directory
    fi
    subj=$(basename "$subj_path")
    echo "### Subject: $subj ###"

    for type in "${!expected_files[@]}"; do
        echo " Checking $type:"

        found_any=false
        for pattern in ${expected_files[$type]}; do
            found=false

            # Loop over all files matching the pattern
            for f in "$subj_path"/"$type"/*"$pattern" "$subj_path"/*"$pattern"; do
                if [ -f "$f" ]; then
                    #echo "  ✅ found: $f"
                    found=true
                    found_any=true
                fi
            done

            if [ "$found" = false ]; then
                echo "  ❌ missing: $pattern"
            fi
        done

        if [ "$found_any" = false ]; then
            echo "  ⚠ No $type files found for this subject."
        fi
    done

    echo "-------------------------------------------"
done

