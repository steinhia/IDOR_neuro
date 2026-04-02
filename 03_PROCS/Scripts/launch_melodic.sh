#!/bin/bash
set -e

# === PATHS ===
export dataset_dir="$(pwd)/../dataset-HCP"
export derivatives_dir="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/PROC_DATA/derivatives-HCP"

export fmriprep_dir="$derivatives_dir/fmriprep"
export melodic_dir="$derivatives_dir/melodic"

participants=("010" "048" "366" "662" "706" "708" "711" "718" "720" "721" "725" "743" "751" "762" "782" "789")
export participants=$(find "$dataset_dir" -maxdepth 1 -type d -name "sub-*" \
           | sed 's|.*/sub-||' \
           | sort)
#export participants=("HCD0183438")
#export participants=("790" "791")

mkdir -p "$melodic_dir"

docker pull alerokhin/fsl6.0


run_subject () {
  participant="$1"
  echo "🧠 MELODIC – sub-${participant}"

   #Chemins vers les fichiers FMRIPrep
  func_dir="$fmriprep_dir/sub-${participant}/func"
  bold_file="$func_dir/sub-${participant}_task-rest_space-MNI152NLin6Asym_res-2_desc-preproc_bold.nii.gz"
  mask_file="$func_dir/sub-${participant}_task-rest_space-MNI152NLin6Asym_res-2_desc-brain_mask.nii.gz"

  # Vérifie que les fichiers existent
  if [[ ! -f "$bold_file" ]]; then
      echo "❌ BOLD manquant pour sub-${participant} : ${bold_file}"
      continue
  else
      echo "✔ BOLD trouvé pour sub-${participant}"
  fi

  if [[ ! -f "$mask_file" ]]; then
      echo "❌ Mask manquant pour sub-${participant} : ${mask_file}"
      continue
  else
      echo "✔ Mask trouvé pour sub-${participant}"
  fi
  out_dir="$melodic_dir/sub-${participant}/func"
  mkdir -p "$out_dir"

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
      --Oall  || {
    echo "⚠️ Erreur ICA pour sub-${participant}, on passe au suivant"
    return 0
}

    echo "✅ ICA terminée pour sub-${participant}"
} 



export -f run_subject 



#for participant in $subjects; do
    parallel -j 2 run_subject ::: $participants
#done
