#!/bin/bash

DICOM_DIR="../RAW_DATA/DICOM"

DRY_RUN=false   # False if you don't wanna test, but really wanna delete the files

for subj in "$DICOM_DIR"/SUBJ*; do
    echo "##################################"
    echo "Cleaning $subj"

    for seq in "$subj"/*; do

        name=$(basename "$seq")

        # KEEP conditions
        if [[ "$name" == *T1w* ]] || \
           [[ "$name" == *T1_3D* ]] || \
           [[ "$name" == *T2w* ]] || \
           [[ "$name" == *T2_3D* ]] || \
           [[ "$name" == *rfMRI_REST* ]] || \
           [[ "$name" == *dMRI* ]] || \
           [[ "$name" == *HARDI* ]] || \
           [[ "$name" == *hardi* ]] || \
           [[ "$name" == *DTI* ]] || \
           [[ "$name" == *dsi* ]] || \
           [[ "$name" == *multishell* ]] || \
           [[ "$name" == *SpinEchoFieldMap* ]]; then

            echo "KEEP   → $name"

        else
            echo "REMOVE → $name"

            if [ "$DRY_RUN" = false ]; then
                rm -rf "$seq"
            fi
        fi

    done

done

echo "Done."
