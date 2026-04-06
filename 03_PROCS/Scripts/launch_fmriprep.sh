#!/usr/bin/env bash

# ==============================
#  PARSING ARGUMENTS
# ==============================

USE_CONTROLS=0

for arg in "$@"; do
  case $arg in
    --controls|--hcp)
      USE_CONTROLS=1
      shift
      ;;
    *)
      echo "Argument inconnu: $arg"
      exit 1
      ;;
  esac
done

# ==============================
#  CONFIGURATION
# ==============================

# === ROOT DIRECTORY ===
# Assumes script is run from the scripts/ folder
PROC_DIR="$(pwd)/../PROC_DATA"

# === COMMON PATHS ===
export fs_dir="${PROC_DIR}/freesurfer"
export work_dir="${PROC_DIR}/work"
export tmp_dir="${PROC_DIR}/tmp"
export fs_license="$(pwd)/../Licence/license.txt"

# === DATASET SELECTION ===
if [[ $USE_CONTROLS -eq 1 ]]; then
  echo "🧠 Mode CONTROLS (HCP)"
  export dataset_dir="${PROC_DIR}/dataset-HCP"
  export derivatives_dir="${PROC_DIR}/derivatives-HCP"
else
  echo "🧠 Mode PATIENTS"
  export dataset_dir="${PROC_DIR}/dataset"
  export derivatives_dir="${PROC_DIR}/derivatives"
fi

# ==============================
#  CREATE FOLDERS
# ==============================

mkdir -p "$fs_dir" "$derivatives_dir" "$work_dir" "$tmp_dir"

# ==============================
#  SUBJECTS
# ==============================

subjects=$(find "$dataset_dir" -maxdepth 1 -type d -name "sub-*" \
           | sed 's|.*/sub-||' \
           | sort)



#subjects=("720 739 711 366")
subjects=("048 721 010 003")

echo "=============================="
echo "📋 Sujets détectés :"
for s in $subjects; do
    echo "  - sub-$s"
done
echo "=============================="


# ==============================
#  CHECK FMRIPREP
# ==============================

check_fmriprep_subject () {
    local sub=$1

    local sub_dir="${fmriprep_dir}/sub-${sub}"
    local func_dir="${sub_dir}/func"
    local report_file="${fmriprep_dir}/sub-${sub}.html"
    local bold_glob="${func_dir}/*desc-preproc_bold.nii.gz"

    echo "🔎 sub-${sub}"

    if [[ -f "$report_file" ]] && ls $bold_glob 1>/dev/null 2>&1; then
        echo "✅ Déjà traité"
        return 0
    else
        echo "❌ À traiter"
        return 1
    fi
}

# ==============================
#  RUN
# ==============================

docker pull nipreps/fmriprep:25.2.3

run_subject () {
  local participant="$1"

  echo "------------------------------"
  echo " sub-${participant}"

  if check_fmriprep_subject "$participant"; then
    echo " skip"
    return
  fi

  echo " running..."

  docker run --rm \
    --user root \
    -v "$dataset_dir":/data \
    -v "$fs_license":/opt/freesurfer/license.txt \
    -v "$derivatives_dir":/out \
    -v "$tmp_dir":/tmp \
    -v "$work_dir":/work \
    nipreps/fmriprep:25.2.3 \
    /data /out/fmriprep participant \
    --participant-label "$participant" \
    --ignore slicetiming \
    --output-spaces MNI152NLin6Asym:res-2 T1w \
    --nthreads 14 \
    --omp-nthreads 8 \
    --work-dir /work \
    --cifti-output 91k || {
        echo "⚠ error for $participant"
    }

  echo "✅ end sub-${participant}"
}


export -f run_subject
export -f check_fmriprep_subject

# ==============================
#  LOOP MAIN
# ==============================

for participant in $subjects; do
    run_subject "$participant"
done

    
#parallel -j 1 run_subject ::: $subjects
