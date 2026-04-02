#!/bin/bash
# Remove transferred DTI folders from 03_PROCS (safe version)

RAW_DIR="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/RAW_DATA/DICOM"

for subjdir in "$RAW_DIR"/SUBJ*; do
    [ -d "$subjdir" ] || continue

    echo "Processing $(basename "$subjdir")"

    for dwi in dMRI_dir98_AP dMRI_dir98_PA dMRI_dir99_AP dMRI_dir99_PA; do

        # Exact match
        if [ -d "$subjdir/$dwi" ]; then
            echo "Removing $subjdir/$dwi"
            rm -rf "$subjdir/$dwi"
        fi

        # Match only numeric suffix (NO SBRef)
        for path in "$subjdir"/${dwi}_*; do
            [ -e "$path" ] || continue

            name=$(basename "$path")

            if [[ "$name" =~ ^${dwi}_([0-9]+)$ ]]; then
                echo "Removing $path"
                rm -rf "$path"
            fi
        done

    done

    echo "-----------------------------------"

done

echo "DTI cleanup completed!"
