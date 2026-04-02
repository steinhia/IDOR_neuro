# DTI Processing Pipeline – README

## Overview

Pipeline to extract, convert, and preprocess diffusion MRI (DTI) data from raw DICOM files into MRtrix-ready format.

---

## Scripts

### `transfer_DTI_files.sh`

Selects and copies only relevant DTI acquisitions:

* `dMRI_dir98_AP`
* `dMRI_dir98_PA`
* `dMRI_dir99_AP`
* `dMRI_dir99_PA`


### `clean_data_from_rs.sh`

Deletes transferred DTI folders from original dataset (used for resting state)

* Removes only the selected DTI folders
* Keeps everything else (T1, fMRI, etc.)

---

### `convert_data.sh`

Converts DICOM → NIfTI using `dcm2niix`.

* Creates BIDS-like structure:

  ```
  sub-XXX/anat/
  sub-XXX/dwi/
  ```
* Standard naming:

  * `sub-XXX_T1w.nii.gz`
  * `sub-XXX_dMRIdirXXYY_dwi.*`
* Generates `.json`, `.bval`, `.bvec`
* Skips existing files

---

### `preproc_01.sh`

First stage of MRtrix preprocessing.

* Converts DWI data to `.mif` (MRtrix format)
* Imports gradients and metadata
* Copies T1 image
* Merges AP and PA acquisitions
* Computes and dilates brain masks
* Applies denoising (`dwidenoise`)
* Applies Gibbs ringing correction (`mrdegibbs`)

---

### `preproc_02.sh`

Second stage of MRtrix preprocessing.

* Merges AP and PA data
* Performs motion & distortion correction (`dwipreproc`)
* Applies bias field correction (`dwibiascorrect`)
* Generates final DWI and brain mask
* Aligns T1 to DWI space (FLIRT)
* Runs tissue segmentation (`5ttgen`)

---

## Pipeline Summary

```
RAW DICOM
   ↓
transfer_DTI_files.sh
   ↓
clean_data_from_rs.sh
   ↓
convert_data.sh
   ↓
preproc_01.sh
   ↓
preproc_02.sh
```

---

## Dependencies

* MRtrix3
* FSL
* ANTs
* dcm2niix

---

## Notes

* Naming is standardized during conversion
* All scripts are safe to re-run (skip existing outputs)

