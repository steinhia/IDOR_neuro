#!/bin/bash
# Script bash to convert DICOM into BIDS-ready NIfTI 

DICOM_DIR="../RAW_DATA/DICOM"
DATASET_DIR="../PROC_DATA/dataset"

mkdir -p "$DATASET_DIR"


DATASET_DIR="../dataset"

for subj in "$DICOM_DIR"/*; do
    base=$(basename "$subj")
    if [[ " ${exclude[@]} " =~ " ${base} " ]]; then
        continue
    fi
    echo "##################################"
    subj_name=$(basename "$subj")
    echo "Traitement du sujet : $subj_name"
    subj_num=$(echo "$subj_name" | sed -E 's/^SUBJ([0-9]+).*/\1/')
    subj_bids="sub-${subj_num}"
    subj_dir="$DATASET_DIR/$subj_bids"

convert_sequence() {

local name="$1"                # ex: "T1w"
local dicom_name="$2"          # ex: "T1w_MPR"
local output_subdir="$3"       # ex: "anat"
local output_suffix="$4"       # ex: "T1w.nii.gz"

echo "=== Processing of $name for $subj ==="
echo "Dicom base name: $dicom_name"

# 1) Search for candidates
local candidates=( $(ls -d "$subj/${dicom_name}"_[0-9]* 2>/dev/null | grep -E "^$subj/${dicom_name}_[0-9]+$" || true) )


if [ ${#candidates[@]} -gt 0 ]; then
    # Extract numbers and keep biggest one
    local sorted_candidates=$(printf "%s\n" "${candidates[@]}" |
        sed -E "s/.*_([0-9]+)$/\1 \0/" |
        sort -nr |
        awk '{print $2}')
    echo "Folders in decreasing order"
    echo "$sorted_candidates"
    dicom_dir=$(echo "$sorted_candidates" | head -n1)
    echo " folder selected : $dicom_dir"
elif [ -d "$subj/$dicom_name" ]; then
    dicom_dir="$subj/$dicom_name"
    echo " folder selected : $dicom_dir"
else
    echo " No folder found for $name"
    return
fi

# 2) Output path
local output_dir="$subj_dir/$output_subdir"
mkdir -p "$output_dir"
local output_file="$output_dir/${subj_bids}_$output_suffix"

echo "Output dir: $output_dir"
echo "Output file final: $output_file"

# 3) Conversion
if [ ! -f "$output_file" ]; then
    echo "➡ Conversion of $name from $dicom_dir ..."
    dcm2niix -z y -f "${subj_bids}_${output_suffix%.nii.gz}" -o "$output_dir" "$dicom_dir"

    # Verification of created files
    echo "NIfTI files generated :"
    ls -l "$output_dir"/*.nii.gz 2>/dev/null

    converted_file=$(ls -t "$output_dir"/*.nii.gz 2>/dev/null | head -n1)
    echo "File chose for renaming"

    if [ -n "$converted_file" ]; then
        if [ "$converted_file" != "$output_file" ]; then
            mv "$converted_file" "$output_file"
            echo " File renamed into : $output_file"
        else
            echo " Already good name: $output_file"
        fi
    else
        echo " No NIfTI found after conversion"
    fi
else
    echo "ℹ $name already exists : $output_file, no conversion"
fi
echo "=============================================="
}

    convert_dicom_to_bids() {

        local name="$1"                # ex: "T1w"
        local dicom_name="$2"          # ex: "T1w_MPR"
        local output_subdir="$3"       # ex: "anat"
        local output_suffix="$4"       # ex: "T1w.nii.gz"

        local dicom_dir="$subj/$dicom_name"       # ex: "$subj/T1w_MPR"
        local output_dir="$subj_dir/$output_subdir" # ex: "$subj_dir/anat"
        local output_file="$output_dir/${subj_bids}_$output_suffix" # ex: "$subj_dir/anat/${subj_bids}_T1w.nii.gz"

#        echo "Name:          $name"
#        echo "DICOM dir:     $dicom_dir"
#        echo "Output dir:    $output_dir"
#        echo "Output file:   $output_file"
#        echo "=============================================="


    mkdir -p "$output_dir"

    if [ ! -f "$output_file" ]; then
        if [ ! -d "$dicom_dir" ]; then
            alternative_dir=$(ls -d "$subj/${dicom_name}"_* 2>/dev/null | head -n1)
            if [ -n "$alternative_dir" ]; then
                dicom_dir="$alternative_dir"
                echo "  modified name detected for $name : $dicom_dir"
            else
                echo "  ERROR: no folder found for $name"
                return  
            fi
        fi

        echo "  Converting $name from $dicom_dir"
        ls -l "$dicom_dir"
        dcm2niix -z y -f "${subj_bids}_${output_suffix%.nii.gz}" -o "$output_dir" "$dicom_dir"

        converted_file=$(ls -t "$output_dir"/*.nii.gz 2>/dev/null | head -n1)
        echo "  Looking for $converted_file"

        if [ -n "$converted_file" ]; then
            if [ "$(realpath "$converted_file")" != "$(realpath "$output_file")" ]; then
                mv "$converted_file" "$output_file"
            else
                echo "  Note: converted file already matches target name: $output_file"
            fi
            echo "  → $name converted: $output_file"
        else
            echo "  ERROR: No NIfTI file found after conversion for $name"
        fi
    else
        echo "  $name already exists: $output_file, skipping conversion"
    fi
    }

    add_intended_for() {
        local fmap_json="$1"
        local func_file="func/${subj_bids}_task-rest_bold.nii.gz"
        if [ -f "$fmap_json" ]; then
            tmp=$(mktemp)
            jq --arg func "$func_file" '. + {IntendedFor: [$func]}' "$fmap_json" > "$tmp" && mv "$tmp" "$fmap_json"
        fi
    }

    convert_sequence "T1w" "T1w_MPR" "anat" "T1w.nii.gz"
    convert_sequence "T2w" "T2w_SPC" "anat" "T2w.nii.gz"
    #convert_sequence "Flair" "T2w_FLAIR_3D_PRJ1509" "anat" "FLAIR.nii.gz"
    convert_sequence "BOLD" "rfMRI_REST_AP" "func" "task-rest_bold.nii.gz"
    #convert_sequence "SBREF" "rfMRI_REST_AP_SBRef" "func" "task-rest_sbref.nii.gz"
    convert_sequence "FMap" "SpinEchoFieldMap_AP" "fmap" "dir-AP_epi.nii.gz"
    convert_sequence "FMap" "SpinEchoFieldMap_PA" "fmap" "dir-PA_epi.nii.gz"

    add_intended_for "$subj_dir/fmap/${subj_bids}_dir-AP_epi.json"
    add_intended_for "$subj_dir/fmap/${subj_bids}_dir-PA_epi.json"

done

# Display incomplete subjects
if [ ${#incomplete_subjects[@]} -ne 0 ]; then
    echo
    echo "Subjects with missing files: ${incomplete_subjects[*]}"
else
    echo
    echo "All subjects have T1w and BOLD correctly converted."
fi

echo "Conversion finished. Dataset BIDS ready in $DATASET_DIR"
