#!/bin/bash

dataset_dir="../PROC_DATA/dataset/"
patients_dir="../PROC_DATA/PATIENTS"

# boucle sur tous les dossiers sub-XXX
#for sub_path in "${dataset_dir}"/sub-*; do
#    # vérifie que c'est bien un dossier
#    [ -d "$sub_path" ] || continue

#    # extrait XXX depuis sub-XXX
#    sub=$(basename "$sub_path" | sed 's/sub-//')

#    echo "=== Processing subject $sub ==="
#
#    ./preproc_02.sh "$sub" "$dataset_dir" "$patients_dir"

#done

# concaténation des 2 listes de sujets
subjects=("720" "739" "711" "366" "048" "721" "010" "003")

# boucle sur la liste de sujets
for sub in "${subjects[@]}"; do
    echo "=== Processing subject $sub ==="
    ./preproc_01.sh "$sub" "$dataset_dir" "$patients_dir"
done
