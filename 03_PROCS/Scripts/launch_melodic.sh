set -e

# === OPTION PARSING ===
# Check if the script is called with --controls
use_controls=false

for arg in "$@"; do
  case $arg in
    --controls)
      use_controls=true
      shift
      ;;
  esac
done

# === PATHS ===
# Define dataset and derivatives paths depending on the option
if [ "$use_controls" = true ]; then
  echo "👉 CONTROLS mode (HCP dataset)"
  export dataset_dir="$(pwd)/../PROC_DATA/dataset-HCP"
  export derivatives_dir="$(pwd)/../PROC_DATA/derivatives-HCP"
else
  echo "👉 NORMAL mode (non-HCP dataset)"
  export dataset_dir="$(pwd)/../PROC_DATA/dataset"
  export derivatives_dir="$(pwd)/../PROC_DATA/derivatives"
fi

# Derived paths
export fmriprep_dir="$derivatives_dir/fmriprep"
export melodic_dir="$derivatives_dir/melodic"

# Automatically detect all subjects (sub-XXX) in dataset directory
export participants=$(find "$dataset_dir" -maxdepth 1 -type d -name "sub-*" \
           | sed 's|.*/sub-||' \
           | sort)

# Create output directory if it does not exist
mkdir -p "$melodic_dir"

# Pull FSL docker image (only if not already present)
docker pull alerokhin/fsl6.0


# === FUNCTION TO PROCESS ONE SUBJECT ===
run_subject () {
  participant="$1"
  echo "🧠 Running MELODIC for sub-${participant}"

  # Paths to fMRIPrep outputs
  func_dir="$fmriprep_dir/sub-${participant}/func"
  bold_file="$func_dir/sub-${participant}_task-rest_space-MNI152NLin6Asym_res-2_desc-preproc_bold.nii.gz"
  mask_file="$func_dir/sub-${participant}_task-rest_space-MNI152NLin6Asym_res-2_desc-brain_mask.nii.gz"

  # Check if BOLD file exists
  if [[ ! -f "$bold_file" ]]; then
      echo "❌ Missing BOLD file for sub-${participant}: ${bold_file}"
      return 0  # skip subject
  else
      echo "✔ BOLD file found"
  fi

  # Check if mask file exists
  if [[ ! -f "$mask_file" ]]; then
      echo "❌ Missing mask file for sub-${participant}: ${mask_file}"
      return 0  # skip subject
  else
      echo "✔ Mask file found"
  fi

  # Output directory for MELODIC results
  out_dir="$melodic_dir/sub-${participant}/func"
  mkdir -p "$out_dir"

  # Run MELODIC via Docker
  docker run --cpus=6 --rm  \
      -e FSLOUTPUTTYPE=NIFTI_GZ \
      -v "$derivatives_dir":/data \
      alerokhin/fsl6.0 \
      melodic \
      -i /data/fmriprep/sub-${participant}/func/$(basename "$bold_file") \
      -o /data/melodic/sub-${participant}/func/sub-${participant}_task-rest_space-MNI152NLin6Asym_res-2_desc-ica_melodic.ica \
      --mask=/data/fmriprep/sub-${participant}/func/$(basename "$mask_file") \
      --nobet \
      --bgthreshold=10 \
      --mmthresh=0.5 \
      --tr=0.8 \
      --report \
      --Oall || {
        echo "⚠ ICA failed for sub-${participant}, skipping"
        return 0
      }

  echo "✅ ICA completed for sub-${participant}"
}

# Export function for GNU parallel
export -f run_subject

# Run subjects in parallel (2 at a time)
parallel -j 2 run_subject ::: $participants
