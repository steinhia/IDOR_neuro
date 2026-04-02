#!/bin/bash
# installation awkward
if ! command -v fslval &> /dev/null; then
    export FSLDIR=/projetos/PRJ1509_MA_FORMACAO/03_PROCS/install/fsl/bin/fsl
    source $FSLDIR/etc/fslconf/fsl.sh
    export PATH=$FSLDIR/bin:$PATH
fi

RAW="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/RAW_DATA/HCP/imagingcollection01"
OUT="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/PROC_DATA/dataset-HCP"

mkdir -p "$OUT"

for subj_path in ${RAW}/HCD*_V1_MR; do

    subj=$(basename "$subj_path" | cut -d'_' -f1)
    echo "Processing $subj"

    out="$OUT/sub-${subj}"
    mkdir -p "$out/anat" "$out/func" "$out/fmap"

    unproc="$subj_path/unprocessed"

    # ==========================================
    # T1
    # ==========================================
    t1="${unproc}/T1w_MPR_vNav_4e_e1e2_mean/${subj}_V1_MR_T1w_MPR_vNav_4e_e1e2_mean.nii.gz"
    t1_json="${unproc}/T1w_MPR_vNav_4e_e1e2_mean/${subj}_V1_MR_T1w_MPR_vNav_4e_e1e2_mean.json"

    [ -f "$t1" ] && cp "$t1" "$out/anat/sub-${subj}_T1w.nii.gz"
    [ -f "$t1_json" ] && cp "$t1_json" "$out/anat/sub-${subj}_T1w.json"

    # ==========================================
    # T2
    # ==========================================
    t2_dir="${unproc}/T2w_SPC_vNav"
    t2=$(ls "$t2_dir"/*.nii.gz 2>/dev/null | head -n 1)
    t2_json=$(ls "$t2_dir"/*.json 2>/dev/null | head -n 1)

    [ -f "$t2" ] && cp "$t2" "$out/anat/sub-${subj}_T2w.nii.gz"
    [ -f "$t2_json" ] && cp "$t2_json" "$out/anat/sub-${subj}_T2w.json"

    # ==========================================
    # REST: pick best REST1* (1 < 1a < 1b ...)
    # ==========================================
    rest_dirs=($(find "$unproc" -maxdepth 1 -type d -name "rfMRI_REST1*_AP" | sort))

    if [ ${#rest_dirs[@]} -eq 0 ]; then
        echo "❌ No REST1* for $subj"
        continue
    fi

    # Take the last (highest suffix)
    rest_dir="${rest_dirs[-1]}"
    echo "→ Using $(basename $rest_dir)"

    # Extract suffix (1, 1a, 1b…)
    rest_suffix=$(basename "$rest_dir" | sed -E 's/.*REST(1[a-z]*)_AP/\1/')

    # Select BOLD
    rest=$(ls "$rest_dir"/*rfMRI_REST${rest_suffix}_AP.nii.gz 2>/dev/null | grep -v SBRef | head -n 1)
    rest_json=$(ls "$rest_dir"/*rfMRI_REST${rest_suffix}_AP.json 2>/dev/null | grep -v SBRef | head -n 1)

    if [ -f "$rest" ]; then

        nvol=$(fslval "$rest" dim4)

        if [ "$nvol" -lt 100 ]; then
            echo "⚠️ $subj REST too short ($nvol vols) → skip"
        else
            cp "$rest" "$out/func/sub-${subj}_task-rest_bold.nii.gz"
            cp "$rest_json" "$out/func/sub-${subj}_task-rest_bold.json"
        fi

    else
        echo "❌ Missing REST file for $subj"
    fi

    # ==========================================
    # FIELDMAP (match REST)
    # ==========================================
    #

    # Map suffix → fieldmap index
    if [[ "$rest_suffix" == "1" ]]; then
        fmap_id="1"
    else
        fmap_id="2"
    fi

    fmap=$(ls "$rest_dir"/*SpinEchoFieldMap${fmap_id}_AP.nii.gz 2>/dev/null | head -n 1)
    fmap_PA=$(ls "$rest_dir"/*SpinEchoFieldMap${fmap_id}_PA.nii.gz 2>/dev/null | head -n 1)
    fmap_json=$(ls "$rest_dir"/*SpinEchoFieldMap${fmap_id}_AP.json 2>/dev/null | head -n 1)
    fmap_json_PA=$(ls "$rest_dir"/*SpinEchoFieldMap${fmap_id}_PA.json 2>/dev/null | head -n 1)

    if [ -f "$fmap" ]; then
        cp "$fmap" "$out/fmap/sub-${subj}_dir-AP_epi.nii.gz"
        cp "$fmap_json" "$out/fmap/sub-${subj}_dir-AP_epi.json"
        cp "$fmap_PA" "$out/fmap/sub-${subj}_dir-PA_epi.nii.gz"
        cp "$fmap_json_PA" "$out/fmap/sub-${subj}_dir-PA_epi.json"
    else
        echo "❌ Missing fmap for $subj"
    fi


    # =========================
    # ADD IntendedFor
    # =========================

    bold_file="sub-${subj}_task-rest_bold.nii.gz"  
    intended="func/${bold_file}"

    for j in AP PA; do
        json="$out/fmap/sub-${subj}_dir-${j}_epi.json"
        tmp=$(mktemp)
        jq --arg val "$intended" '. + {IntendedFor: [$val]}' "$json" > "$tmp" \
            && mv "$tmp" "$json"
    done

done

echo "✅ dataset-HCP ready (best REST1* selected)"





#   if [[ "$rest_suffix" == "1" ]]; then
#       fmap_id="1"
#   else
#       fmap_id="2"
#   fi
#   
#   fmap_ap=$(ls "$rest_dir"/*SpinEchoFieldMap${fmap_id}_AP.nii.gz 2>/dev/null | head -n 1)
#   fmap_pa=$(ls "$rest_dir"/*SpinEchoFieldMap${fmap_id}_PA.nii.gz 2>/dev/null | head -n 1)
#   
#   fmap_ap_json=$(ls "$rest_dir"/*SpinEchoFieldMap${fmap_id}_AP.json 2>/dev/null | head -n 1)
#   fmap_pa_json=$(ls "$rest_dir"/*SpinEchoFieldMap${fmap_id}_PA.json 2>/dev/null | head -n 1)
#   
#   if [[ -f "$fmap_ap" && -f "$fmap_pa" ]]; then
#       cp "$fmap_ap" "$out/fmap/sub-${subj}_dir-AP_epi.nii.gz"
#       cp "$fmap_pa" "$out/fmap/sub-${subj}_dir-PA_epi.nii.gz"
#   
#       cp "$fmap_ap_json" "$out/fmap/sub-${subj}_dir-AP_epi.json"
#       cp "$fmap_pa_json" "$out/fmap/sub-${subj}_dir-PA_epi.json"
#   else
#       echo "❌ Missing AP/PA fmap for $subj"
#   fi


