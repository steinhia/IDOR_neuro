#!/bin/bash

base_dir="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/RAW_DATA/HCP/imagingcollection01"

for subj in "$base_dir"/*/unprocessed; do
    [ -d "$subj" ] || continue

    echo "=== Checking $subj ==="

    # AP
    if [ -d "$subj/rfMRI_REST1_AP" ]; then
        if [ -d "$subj/rfMRI_REST2_AP" ]; then
            echo "Removing REST2_AP in $subj"
            rm -rf "$subj/rfMRI_REST2_AP"
        fi
    fi

    # PA
    if [ -d "$subj/rfMRI_REST1_PA" ]; then
        if [ -d "$subj/rfMRI_REST2_PA" ]; then
            echo "Removing REST2_PA in $subj"
            rm -rf "$subj/rfMRI_REST2_PA"
        fi
    fi

done
