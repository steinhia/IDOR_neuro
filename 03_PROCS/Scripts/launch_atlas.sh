#!/bin/bash
set -e

# Root processing directory (relative to current script location)
PROC_DIR="$(pwd)/../PROC_DATA"

# Folder with melodic results
if [[ "$1" == "--controls" ]]; then
    echo "👉 CONTROLS mode (HCP)"
    DERIVATIVES="${PROC_DIR}/derivatives-HCP"
else
    echo "👉 NORMAL mode"
    DERIVATIVES="${PROC_DIR}/derivatives"
fi


MELODIC_ROOT="${DERIVATIVES}/melodic"

# RSN atlas (Smith 2009)
ATLAS="$(pwd)/..//atlases/PNAS_Smith09_rsn10.nii.gz"

docker_image="alerokhin/fsl6.0"

for ICA_DIR in ${MELODIC_ROOT}/sub-*/func/*.ica ; do

    SUBJECT=$(basename $(dirname $(dirname "$ICA_DIR")))
    echo "🧠 Processing ${SUBJECT}"

    OUTDIR="${ICA_DIR}/rsn_matching"
    mkdir -p "$OUTDIR"

    # Run each subject safely: if it fails, continue to next
    if ! docker run --rm \
      -v "${DERIVATIVES}:/data" \
      -v "$(dirname $ATLAS):/atlas" \
      -e FSLOUTPUTTYPE=NIFTI_GZ \
      $docker_image bash -c "

        echo '➡ FLIRT: compute transformation matrix'
        flirt \
          -in \$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz \
          -ref /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/mean.nii.gz \
          -out /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/rsn_matching/mni_resampled.nii.gz \
          -omat /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/rsn_matching/mni2ica.mat

        echo '➡ Split ICA components'
        fslsplit \
          /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/melodic_IC.nii.gz \
          /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/rsn_matching/melodic_IC_ \
          -t

        echo '➡ Resample atlas to ICA space'
        flirt \
          -in /atlas/$(basename $ATLAS) \
          -ref /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/rsn_matching/melodic_IC_0000.nii.gz \
          -applyxfm \
          -init /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/rsn_matching/mni2ica.mat \
          -usesqform \
          -out /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/rsn_matching/PNAS_Smith09_rsn10_resampled.nii.gz

        echo '➡ Compute ICA ↔ RSN correlations'
        fslcc \
          --noabs \
          -p 3 \
          -t 0.05 \
          /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/rsn_matching/PNAS_Smith09_rsn10_resampled.nii.gz \
          /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/melodic_IC.nii.gz \
          > /data/melodic/${SUBJECT}/func/$(basename $ICA_DIR)/ica_rsn_correlations.txt
      "
    then
        echo "❌ Error for ${SUBJECT}, skipping..."
        continue
    fi

    echo "✅ ${SUBJECT} done"
    echo
done
