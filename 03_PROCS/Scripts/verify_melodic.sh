#!/bin/bash

# Folder with melodic results
if [[ "$1" == "--controls" ]]; then
    derivatives_dir="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/PROC_DATA/derivatives-HCP/melodic"
else
    derivatives_dir="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/PROC_DATA/derivatives/melodic"
fi


declare -A expected_folder

# fichiers func
expected_folder[func]="_task-rest_space-MNI152NLin6Asym_res-2_desc-ica_melodic.ica"
expected_results="mask.nii.gz melodic_FTmix melodic_PPCA melodic_mix melodic_pcaD melodic_white eigenvalues_percent mean.nii.gz melodic_IC.nii.gz melodic_Tmodes melodic_oIC.nii.gz melodic_pcaE melodic_FTdewhite melodic_ICstats"
expected_results="mask.nii.gz mean.nii.gz melodic_IC.nii.gz "


echo "===== Verification of file presence in $derivatives_dir ====="
echo

for subj_path in "$derivatives_dir"/sub-*; do
    if [ ! -d "$subj_path" ]; then
      continue  # ignore if not a folder
    fi
    subj=$(basename "$subj_path")
    echo "### Subject: $subj ###"

    for type in "${!expected_folder[@]}"; do
        echo " Verification $type:"

        found_any=false
        for pattern in ${expected_folder[$type]}; do
            found=false
	    for file in ${expected_results}; do

            # Loop on files correpsonding to the pattern
            for f in "$subj_path"/"$type"/*"$pattern"/"$file" "$subj_path"/*"$pattern"; do
		#echo "$f"
                if [ -f "$f" ]; then
                    echo "  ✅ found: $f"
                    found=true
                    found_any=true
                fi
            done
    	done

            if [ "$found" = false ]; then
                echo "  ❌ missing: $pattern"
            fi
        done

        if [ "$found_any" = false ]; then
            echo "  ⚠️ No file $type found for this subject."
        fi
    done

    echo "-------------------------------------------"
done
