#!/bin/bash
# Convert DICOM → NIfTI with BIDS-like subject naming (sub-XXX)
# Organize outputs into anat/ and dwi/
# T1 renamed to sub-XXX_T1w

INPUT_DIR="/projetos/PRJ1509_MA_FORMACAO/03_PROCS_DTI/RAW_DATA/DICOM"
OUTPUT_DIR="/projetos/PRJ1509_MA_FORMACAO/03_PROCS_DTI/PROC_DATA/dataset"

mkdir -p "$OUTPUT_DIR"

for subjdir in "$INPUT_DIR"/SUBJ*; do
    [ -d "$subjdir" ] || continue

    subj_raw=$(basename "$subjdir")
    subj_num=${subj_raw#SUBJ}
    subj="sub-${subj_num}"

    out_subj="$OUTPUT_DIR/$subj"
    mkdir -p "$out_subj/dwi" "$out_subj/anat"

    ########################
    # DWI (unchanged)
    ########################
    for dwi_dir in "$subjdir"/dMRI_dir*; do
        [ -d "$dwi_dir" ] || continue

        name=$(basename "$dwi_dir")

        if ls "$out_subj/dwi/${subj}_${name}"*.nii.gz 1> /dev/null 2>&1; then
            echo "Skipping (already converted): $subj $name"
            continue
        fi

        echo "Converting DWI: $dwi_dir → $out_subj/dwi"

        dcm2niix \
            -z y \
            -f "${subj}_${name}" \
            -o "$out_subj/dwi" \
            "$dwi_dir"
    done

    ########################
    # T1w (fixed naming)
    ########################
    if ls "$out_subj/anat/${subj}_T1w.nii.gz" 1> /dev/null 2>&1; then
        echo "Skipping (already converted): $subj T1w"
    else
        t1_dir=$(ls -d "$subjdir"/T1w_MPR* 2>/dev/null | head -n 1)

        if [ -n "$t1_dir" ]; then
            echo "Converting T1: $t1_dir → $out_subj/anat"

            dcm2niix \
                -z y \
                -f "${subj}_T1w" \
                -o "$out_subj/anat" \
                "$t1_dir"
        else
            echo "Warning: no T1 found for $subj"
        fi
    fi

done

echo "Conversion completed!"
