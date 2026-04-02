#!/bin/bash
# Fix T1 filenames to BIDS format: sub-XXX_T1w.*

DATASET_DIR="/projetos/PRJ1509_MA_FORMACAO/03_PROCS_DTI/PROC_DATA/dataset"

cd "$DATASET_DIR" || exit 1

for subjdir in sub-*; do
    [ -d "$subjdir" ] || continue

    subj=$(basename "$subjdir")
    anat_dir="$subjdir/anat"

    [ -d "$anat_dir" ] || continue

    echo "Processing $subj"

    # Find all wrongly named T1 files
    for f in "$anat_dir"/*T1w_MPR*; do
        [ -e "$f" ] || continue

        ext="${f##*.}"

        # Handle .nii.gz separately
        if [[ "$f" == *.nii.gz ]]; then
            newfile="$anat_dir/${subj}_T1w.nii.gz"
        elif [[ "$f" == *.json ]]; then
            newfile="$anat_dir/${subj}_T1w.json"
        else
            continue
        fi

        echo "Renaming $(basename "$f") → $(basename "$newfile")"

        mv -f "$f" "$newfile"
    done

done

echo "Renaming completed!"
