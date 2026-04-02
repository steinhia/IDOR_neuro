#!/bin/bash

# Répertoire des résultats MELODIC
ICA_DIR=~/rs-fMRI/melodic.ica/filtered_func_data.ica

# Fichier RSN de référence (PNAS)
RSN_FILE=$ICA_DIR/PNAS_Smith09_rsn10.nii.gz

# Fichier de sortie
OUT_FILE=$ICA_DIR/ICxRSN_corr.txt
echo "IC_index RSN_index FSLCC_correlation" > $OUT_FILE

# Nombre de composantes ICA
NUM_IC=$(fslval $ICA_DIR/melodic_IC.nii.gz dim4)
echo "Nombre de composantes ICA détectées: $NUM_IC"

# Nombre de RSNs (supposé dans la 4ème dimension)
NUM_RSN=$(fslval $RSN_FILE dim4)
echo "Nombre de RSNs dans PNAS: $NUM_RSN"

for (( ic=0; ic<NUM_IC; ic++ )); do
    # Extraire l'IC
    IC_FILE=$ICA_DIR/IC_${ic}.nii.gz
    fslroi $ICA_DIR/melodic_IC.nii.gz $IC_FILE $ic 1 0 1 0 1

    # Resampler l'IC sur la grille du RSN
    IC_RESAMP=$ICA_DIR/IC_${ic}_resampled.nii.gz
    flirt -in $IC_FILE -ref $RSN_FILE -applyisoxfm 2 -out $IC_RESAMP -interp trilinear

    for (( rsn=0; rsn<NUM_RSN; rsn++ )); do
        # Extraire le RSN
        RSN_VOL=$ICA_DIR/RSN_${rsn}.nii.gz
        fslroi $RSN_FILE $RSN_VOL $rsn 1 0 1 0 1

        # Calculer FSLCC
        CORR=$(fslcc $IC_RESAMP $RSN_VOL)
        echo "$((ic+1)) $((rsn+1)) $CORR" >> $OUT_FILE
        echo "IC $((ic+1)) vs RSN $((rsn+1)) -> correlation $CORR"
    done
done

echo "Terminé! Résultats sauvegardés dans $OUT_FILE"
