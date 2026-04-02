#!/bin/bash

# ==============================
# Dataset selection via argument
# ==============================

if [[ "$1" == "--controls" ]]; then
    dataset_dir="../dataset-HCP"
else
    dataset_dir="../dataset"
fi

trash_dir="../trash"   # root folder for extra files
mkdir -p "$trash_dir"

echo "📊 Checking existence of dataset_description.json"

[ ! -f ../dataset/dataset_description.json ] && cat > ../dataset/dataset_description.json << EOF
{
  "Name": "MyProject",
  "BIDSVersion": "1.7.0",
  "Authors": ["Alexandra Steinhilber"],
  "License": "../Licence/licence.txt"
}
EOF


echo "📊 Checking fMRI acquisition durations"
echo "=========================================="

# Loop over all subject directories
for subj in "$dataset_dir"/sub-*; do
    func_dir="$subj/func"

    # Check if func directory exists
    if [ -d "$func_dir" ]; then
        for bold_file in "$func_dir"/*_bold.nii.gz; do
            [ -f "$bold_file" ] || continue  # skip if no file

            # Extract subject and file name
            subj_name=$(basename "$subj")
            bold_name=$(basename "$bold_file")

            # Get info with fslinfo
            dim4=$(fslinfo "$bold_file" | awk '/^dim4/ {print $2}')
            tr=$(fslinfo "$bold_file" | awk '/^pixdim4/ {print $2}')

            # Compute total duration (seconds and minutes)
            duration_sec=$(awk "BEGIN {print $dim4 * $tr}")
            duration_min=$(awk "BEGIN {print $duration_sec / 60}")

            echo "$subj_name → $bold_name"
            echo "  Volumes: $dim4"
            echo "  TR: ${tr}s"
            echo "  Total duration: ${duration_sec}s (~${duration_min} min)"
            echo "------------------------------------------"
        done
    fi
done

# Define expected files per directory (suffixes only)
declare -A expected_files=(
    [anat]="T1w.nii.gz T2w.nii.gz"
    #[anat]="T1w.nii.gz T2w.nii.gz FLAIR.nii.gz"
    #[func]="task-rest_bold.nii.gz task-rest_sbref.nii.gz"
    [func]="task-rest_bold.nii.gz"
    [fmap]="dir-AP_epi.nii.gz"
)

# Required JSON fields per type
declare -A json_fields
json_fields[anat]="Modality"
json_fields[func]="EchoTime PhaseEncodingDirection EffectiveEchoSpacing"
json_fields[fmap]="PhaseEncodingDirection TotalReadoutTime"

for subj_path in "$dataset_dir"/sub-*; do
    subj=$(basename "$subj_path")
    echo "=== Checking $subj ==="

    for d in "${!expected_files[@]}"; do
        dir_path="$subj_path/$d"
        echo "  Checking directory $d : $dir_path"

        # Build list of expected files (nii.gz + JSON)
        files_expected=()
        for suffix in ${expected_files[$d]}; do
            files_expected+=("$subj"_"$suffix")
            files_expected+=("${subj}_${suffix%.nii.gz}.json")
        done

        # Get all actual files in directory
        mapfile -t files_actual < <(find "$dir_path" -maxdepth 1 -type f -printf "%f\n")

        for exp in "${files_expected[@]}"; do
            # Only check expected NIfTI files
            if [[ "$exp" == *.nii.gz ]]; then
                base="${exp%.nii.gz}"
                json_file="$dir_path/${base}.json"

                # Check if JSON exists
                if [ ! -f "$json_file" ]; then
                    echo "    ERROR: missing JSON file for $exp : $json_file"
                else
                    # Check required JSON fields
                    for field in ${json_fields[$d]}; do
                        if ! jq -e ".\"$field\"" "$json_file" >/dev/null; then
                            echo "    WARNING: field '$field' missing in $json_file"
                        fi
                    done
                fi
            fi
        done

        if ! $found; then
            echo "    EXTRA: unexpected file $f"

            # Ask user if file should be moved
            read -p "      Move this file to trash? [y/N] " yn
            case $yn in
                [Yy]* )
                    # Create directory structure in trash
                    dest_dir="$trash_dir/$subj/$d"
                    mkdir -p "$dest_dir"
                    mv "$dir_path/$f" "$dest_dir/"
                    echo "      Moved to $dest_dir/$f"
                    ;;
                * )
                    echo "      File kept in place"
                    ;;
            esac
        fi
    done

    # Check that all expected files are present
    for exp in "${files_expected[@]}"; do
        if [ ! -f "$dir_path/$exp" ]; then
            echo "    ERROR: missing expected file $exp"
        else
            echo "    file present $exp"
        fi
    done
done
