#!/bin/bash
if ! command -v fslmaths &> /dev/null; then
    export FSLDIR=/projetos/PRJ1509_MA_FORMACAO/03_PROCS/install/fsl/bin/fsl
    source $FSLDIR/etc/fslconf/fsl.sh
    export PATH=$FSLDIR/bin:$PATH
fi
# =====================
# ARGUMENTS
# =====================
CONTROLS_FLAG=$1

# =====================
# PATHS
# =====================
BASE_DIR=$(pwd)
PROC_DIR="${BASE_DIR}/../PROC_DATA"

if [ "$CONTROLS_FLAG" == "--controls" ]; then
    DERIVATIVES="${PROC_DIR}/derivatives-HCP"
    INPUT_TSV="${BASE_DIR}/rsn_selected_for_reconstruction_controls.tsv"
    echo "Using controls dataset"
else
    DERIVATIVES="${PROC_DIR}/derivatives"
    INPUT_TSV="${BASE_DIR}/rsn_selected_for_reconstruction.tsv"
    echo "Using standard dataset"
fi

if [ ! -f "$INPUT_TSV" ]; then
    echo "Error: TSV file not found: $INPUT_TSV"
    exit 1
fi

MELODIC_ROOT="${DERIVATIVES}/melodic"
RECON_ROOT="${DERIVATIVES}/reconstruction"

# =====================
# RSN LABELS
# =====================
declare -A RSN_LABELS
RSN_LABELS[1]="Visual"
RSN_LABELS[2]="Visual"
RSN_LABELS[3]="Visual"
RSN_LABELS[4]="DefaultModeNetwork"
RSN_LABELS[5]="Cerebellum"
RSN_LABELS[6]="Sensorimotor"
RSN_LABELS[7]="Auditory"
RSN_LABELS[8]="ExecutiveControl"
RSN_LABELS[9]="Frontoparietal"
RSN_LABELS[10]="Frontoparietal"

# =====================
# PROCESS
# =====================
while read SUB RSN IC; do

    echo "Processing sub-${SUB} | RSN ${RSN} | IC ${IC}"

    ICA_DIR=$(ls -d ${MELODIC_ROOT}/sub-${SUB}/func/*.ica 2>/dev/null | head -n 1)

    if [ -z "$ICA_DIR" ]; then
        echo "Warning: No ICA directory found for sub-${SUB}"
        continue
    fi

    MATCH_DIR="${ICA_DIR}/rsn_matching"

    if [ ! -d "$MATCH_DIR" ]; then
        echo "Warning: No rsn_matching directory for sub-${SUB}"
        continue
    fi

    OUT_DIR="${RECON_ROOT}/sub-${SUB}"
    mkdir -p "$OUT_DIR"

    LABEL=${RSN_LABELS[$RSN]}

    IC_PADDED=$(printf "%04d" $IC)
    IC_FILE="${MATCH_DIR}/melodic_IC_${IC_PADDED}.nii.gz"

    OUT_FILE="${OUT_DIR}/sub-${SUB}_RSN-${RSN}_${LABEL}.nii.gz"

    if [ ! -f "$IC_FILE" ]; then
        echo "Warning: Missing file ${IC_FILE}"
        continue
    fi

    # accumulate ICs
    if [ -f "$OUT_FILE" ]; then
        fslmaths "$OUT_FILE" -add "$IC_FILE" "$OUT_FILE"
    else
        cp "$IC_FILE" "$OUT_FILE"
    fi

done < "$INPUT_TSV"

# =====================
# APPLY THRESHOLD
# =====================
echo "Applying threshold..."

for f in ${RECON_ROOT}/sub-*/sub-*_RSN-*.nii.gz; do
    fslmaths "$f" -thr 5.0 "$f"
done

echo "Reconstruction completed."
