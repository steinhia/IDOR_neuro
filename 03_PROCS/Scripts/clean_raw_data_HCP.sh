#!/bin/bash

BASE_DIR="/projetos/PRJ1509_MA_FORMACAO/03_PROCS/RAW_DATA/HCP/imagingcollection01"

for subj in ${BASE_DIR}/HCD*; do
    echo "🧹 Cleaning $subj"

    UNPROC="${subj}/unprocessed"

    # Vérifie que le dossier existe
    if [ ! -d "$UNPROC" ]; then
        echo "⚠️  Pas de dossier unprocessed pour $subj"
        continue
    fi

    cd "$UNPROC" || continue

    for d in *; do
        # Garde uniquement ce qu'on veut
        if [[ "$d" == Diffusion* ]] || \
           [[ "$d" == T1* ]] || \
           [[ "$d" == T2* ]] || \
           [[ "$d" == rfMRI_REST* ]]; then
            echo "✅ Keeping $d"
        else
            echo "❌ Removing $d"
            rm -rf "$d"
        fi
    done

done

echo "🎉 Cleaning done"
