#!/bin/bash
# Copy DWI + T1w folders with strict matching:
#   - exact name OR name with numeric suffix (_XXX)
#   - exclude SBRef (for DWI)
#   - pick highest XXX if multiple
#   - remove date from subject folder name
#   - skip copy if already exists

RAW_SOURCE="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/RAW_DATA/DICOM"
RAW_TARGET="/projetos/PRJ1509_MA_FORMACAO/03_PROCS_DTI/RAW_DATA/DICOM"

DWI_TYPES=("dMRI_dir98_AP" "dMRI_dir98_PA" "dMRI_dir99_AP" "dMRI_dir99_PA")
T1_TYPE="T1w_MPR"

for subjdir in "$RAW_SOURCE"/*; do
    [ -d "$subjdir" ] || continue

    subj_full=$(basename "$subjdir")
    subj=${subj_full%%_*}

    target_subj="$RAW_TARGET/$subj"
    mkdir -p "$target_subj"

    missing_any=false

    ########################
    # DWI PART (unchanged)
    ########################
    for dwi in "${DWI_TYPES[@]}"; do

        chosen=""

        if [ -d "$subjdir/$dwi" ]; then
            chosen="$subjdir/$dwi"
        else
            max_num=-1
            best_match=""

            for path in "$subjdir"/${dwi}_*; do
                [ -e "$path" ] || continue
                name=$(basename "$path")

                # strict + exclude SBRef
                if [[ "$name" =~ ^${dwi}_([0-9]+)$ ]]; then
                    num=${BASH_REMATCH[1]}
                    num=$((10#$num))

                    if (( num > max_num )); then
                        max_num=$num
                        best_match="$path"
                    fi
                fi
            done

            if [ -n "$best_match" ]; then
                chosen="$best_match"
            else
                echo "Warning: no valid match for $dwi in $subj_full"
                missing_any=true
                continue
            fi
        fi

        dest="$target_subj/$(basename "$chosen")"

        if [ -d "$dest" ]; then
            echo "Skipping (already exists): $dest"
        else
            echo "Copying $chosen → $target_subj/"
            cp -r "$chosen" "$target_subj/"
        fi
    done

    ########################
    # T1w PART (new)
    ########################

    chosen=""

    # Exact match
    if [ -d "$subjdir/$T1_TYPE" ]; then
        chosen="$subjdir/$T1_TYPE"
    else
        max_num=-1
        best_match=""

        for path in "$subjdir"/${T1_TYPE}_*; do
            [ -e "$path" ] || continue
            name=$(basename "$path")

            # strict numeric suffix
            if [[ "$name" =~ ^${T1_TYPE}_([0-9]+)$ ]]; then
                num=${BASH_REMATCH[1]}
                num=$((10#$num))

                if (( num > max_num )); then
                    max_num=$num
                    best_match="$path"
                fi
            fi
        done

        if [ -n "$best_match" ]; then
            chosen="$best_match"
        else
            echo "Warning: no valid match for $T1_TYPE in $subj_full"
            missing_any=true
        fi
    fi

    if [ -n "$chosen" ]; then
        dest="$target_subj/$(basename "$chosen")"

        if [ -d "$dest" ]; then
            echo "Skipping (already exists): $dest"
        else
            echo "Copying $chosen → $target_subj/"
            cp -r "$chosen" "$target_subj/"
        fi
    fi

    ########################
    # DEBUG
    ########################
    if [ "$missing_any" = true ]; then
        echo "Available dMRI folders for $subj_full:"
        ls "$subjdir" | grep -i dMRI
        echo "Available T1w folders for $subj_full:"
        ls "$subjdir" | grep -i T1
        echo "----------------------------------------"
    fi

done

echo "Copy completed successfully!"
