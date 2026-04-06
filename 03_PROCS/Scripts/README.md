# PRJ1509 – Neuroimaging Processing Pipeline (Patients vs Controls)

## Project Structure

Main scripts:

* `clean_raw_data.sh` / `clean_raw_data_HCP.sh`
* `extract_DICOM.sh` / `extract_HCP.sh`
* `verify_bids.sh`
* `launch_fmriprep.sh`
* `verify_fmriprep.sh`
* `launch_melodic.sh`
* `verify_melodic.sh`
* `launch_atlas.sh`
* `visualize_correlations.py`
* `launch_reconstruction.py`
* `correlations_atlas.py`
* `launch_xcpd.sh` 
* `verify_xcpd.sh`

## Data Organization & Paths

All paths are relative to the project root:

```

03_PROCS/
|-- RAW_DATA/
|   |-- DICOM/            # Patients raw DICOM data
|   `-- HCP/              # Controls (HCP raw structure)
|
|-- PROC_DATA/
|   |-- dataset/              # BIDS dataset (patients)
|   |-- dataset-HCP/          # BIDS-like dataset (controls)
|   |
|   |-- derivatives/          # Patients outputs
|   |   |-- fmriprep/         # fMRIPrep outputs (sub-XXX, HTML reports)
|   |   `-- melodic/          # ICA (MELODIC results)
|   |   |__ reconstruction/   # reconstruction output
|   |
|   |-- derivatives-HCP/      # Controls outputs
|   |   |-- fmriprep/
|   |   `-- melodic/
|   |   |__ reconstruction/   
|   |
|   `-- freesurfer/           # FreeSurfer outputs
|
|-- Scripts/                  # All processing scripts (this README)
|-- atlases/                 # Atlases used for analysis
|-- csv/                     # Final outputs (correlations, metrics)
`-- install/                 # Software installations (FSL, etc.)

```


## Overview

This pipeline processes two types of datasets:

* **Patients** → local DICOM data
* **Controls** → HCP dataset

Each dataset follows a similar structure:

1. Clean raw DICOM data
2. Convert DICOM → BIDS (NIfTI)
3. Verify BIDS dataset
4. Run fMRIPrep (fMRI preprocessing)
5. Verify fMRIPrep outputs
6. Run ICA decomposition (MELODIC)
7. Verify MELODIC outputs
8. RSN matching from ICA components
9. RSN matching inspection
10. Reconstruction of RSNs
11. Run ICA decomposition (MELODIC)
12. Connectivity ↔ Behavioral correlation analysis

---

##  PATIENTS PIPELINE

### 1. Clean raw DICOM data

Remove non-neuroimaging sequences (scout, angiography, etc.) to aliviate the disk:

```bash
bash clean_raw_data.sh
```

---

### 2. Convert DICOM → BIDS (NIfTI)

Extract relevant sequences (T1, T2, resting-state, fieldmaps, diffusion):

```bash
bash extract_DICOM.sh
```

---

### 3. Verify BIDS dataset

Check that all required files are present:

```bash
bash verify_bids.sh
```

---

### 4. Run fMRIPrep (fMRI preprocessing)

This script runs fMRIPrep to preprocess raw fMRI data for all subjects.

#### Processing
- For each subject:
  - Load raw BIDS dataset
  - Perform standard preprocessing using fMRIPrep (via Docker):
    - motion correction
    - spatial normalization to MNI space
    - brain extraction and masking
    - anatomical (T1w) processing
  - Outputs are generated in both native (T1w) and MNI space

```bash
bash launch_fmriprep.sh
```

#### Output
- Preprocessed data stored in:


- Key files:
  - `*_desc-preproc_bold.nii.gz`: preprocessed BOLD signal
  - `*_desc-brain_mask.nii.gz`: brain mask
  - `sub-XXX.html`: quality control report

#### Features
- Automatically skips already processed subjects
- Supports two datasets:
  - patients (default)
  - controls (HCP) via `--controls`


---

### 5. Verify fMRIPrep outputs

Check for missing subjects or failed runs:

```bash
bash verify_fmriprep.sh
```

---

### 6. Run ICA decomposition (MELODIC)

This script runs ICA decomposition (MELODIC, FSL) on preprocessed resting-state fMRI data from fMRIPrep.

#### Processing
- For each subject:
  - Load preprocessed BOLD data and brain mask from fMRIPrep
  - Run MELODIC (Independent Component Analysis) using Docker (FSL)
  - Decompose the BOLD signal into spatially independent components (ICs)

```bash
bash launch_melodic.sh
```

#### Output
- One `.ica` folder per subject: derivatives/melodic/sub-XXX/func/*.ica

- Contains:
  - `melodic_IC.nii.gz`: spatial maps of ICA components
  - `melodic_mix`: time series of components
  - QC report (`report.html`)

#### Purpose
- Identify resting-state networks and noise components
- Provide input for RSN matching (next step)


---

### 7. Verify MELODIC outputs

Check for missing subjects or failed runs:

```bash
bash verify_melodic.sh
```

---

### 8 - RSN matching from ICA components


```bash
bash launch_atlas.sh
```

This script performs spatial matching between subject-specific ICA components (from MELODIC) and a reference set of resting-state networks (RSNs; Smith et al., 2009).

#### Input
- Precomputed MELODIC outputs:
  - `melodic_IC.nii.gz` (4D ICA components)
  - `mean.nii.gz` (reference image)
- RSN atlas:
  - `PNAS_Smith09_rsn10.nii.gz`

#### Processing steps
For each subject:
1. Compute transformation from MNI space to ICA space (FLIRT)
2. Split ICA components into individual 3D volumes (`fslsplit`)
3. Resample RSN atlas into subject ICA space
4. Compute spatial correlations between each ICA component and each RSN (`fslcc`)

#### Output
Results are stored in: derivatives[-HCP]/melodic/sub-XXX/func/*.ica/


Main outputs:
- `rsn_matching/PNAS_Smith09_rsn10_resampled.nii.gz`  
  → RSN atlas in subject space
- `rsn_matching/melodic_IC_*.nii.gz`  
  → individual ICA components
- `ica_rsn_correlations.txt`  
  → matrix of spatial correlations (RSN × ICA components)

#### Interpretation
- Each value represents the spatial correlation between an ICA component and a reference RSN.
- For each RSN, the best-matching ICA component can be identified (e.g., maximum correlation).
- These values can be used for group-level analyses or correlated with behavioral measures.

---

### 9 - RSN matching inspection

This script provides a quick quality check of ICA ↔ RSN correlations and select highest correlations (if above threshold) to be used for reconstruction.

####  Run the extraction script

```python
python visualize_correlations.py
```

#### 📄 Output

This step generates:

- A CSV file for inspection:
```bash
rsn_matching_inspection.csv
```

- A TSV file for reconstruction:
```bash
rsn_selected_for_reconstruction.tsv
```

## 🧾 TSV Format

```text
subject    RSN    IC
003        4      12
003        7      21
...
```

- `subject` → subject ID (without `sub-`)
- `RSN` → network ID (1–10)
- `IC` → selected component


#### Features
- Displays top 2 ICA components per RSN
- Shows correlation values
- Applies a threshold (e.g., r ≥ 0.1)
- Shows which component is selected (highest correlation)

#### Purpose
This step is useful to:
- Validate automatic selection
- Adjust threshold if needed
- Detect misclassified components

## 🧠 RSN Labels

```text
1 - Visual
2 - Visual
3 - Visual
4 - Default Mode Network
5 - Cerebellum
6 - Sensorimotor
7 - Auditory
8 - Executive Control
9 - Frontoparietal
10 - Frontoparietal
```

### 10. Reconstruction of RSNs

This step reconstructs each RSN by summing selected ICs.

---

#### ▶️ Run reconstruction

```bash
bash launch_reconstruction.sh
```

#### 📁 Output structure

```bash
../PROC_DATA/derivatives/reconstruction/
    sub-003/
        sub-003_RSN-4_DefaultModeNetwork.nii.gz
        sub-003_RSN-1_Visual.nii.gz
        ...
```

#### ⚙️ How it works

For each subject:

1. Reads selected ICs from TSV
2. Finds corresponding MELODIC directory
3. Loads IC files from:

```bash
melodic/sub-XXX/func/*.ica/rsn_matching/
```

4. Reconstructs RSN using:

```bash
fslmaths IC1 -add IC2 -add IC3 ...
```

5. Applies threshold:

```bash
fslmaths output.nii.gz -thr 5.0 output.nii.gz
```

### 11 - Connectivity ↔ Behavioral correlation analysis

This script computes associations between resting-state networks (RSNs), derived from ICA decomposition, and behavioral scores across subjects.

#### Input
- ICA ↔ RSN correlation files:
  - `ica_rsn_correlations.txt` (one per subject, from RSN matching step)
- Behavioral scores:
  - `behavioral_scores.csv` (must include `subject_id` column)

#### Processing steps
1. Load ICA ↔ RSN correlation files for all subjects
2. For each RSN, select the ICA component with the highest correlation (best match)
3. Apply a correlation threshold (e.g., r ≥ 0.05):
   - values below threshold are set to 0 (no reliable match)
4. Construct a subject × RSN matrix
5. Align imaging data with behavioral scores
6. Compute Pearson correlations between RSN values and behavioral measures

```python
python correlations_atlas.py
```

#### Output
- `rsn_behavior_correlations.csv`
  - columns:
    - `RSN`: network index
    - `score`: behavioral variable
    - `r`: correlation coefficient
    - `p`: p-value

#### Interpretation
- Each result reflects the relationship between a functional network (RSN) and a behavioral measure.
- Thresholding ensures that only meaningful ICA–RSN matches contribute to the analysis.
- Multiple comparison correction (e.g., FDR) is recommended.

#### Purpose
- Identify brain–behavior relationships at the network level using ICA-derived resting-state components.


### 12. Post-processing (XCP-D) optional, unfinished work (not useful if using ICA)

```bash
bash launch_xcpd.sh
```

Verify:

```bash
bash verify_xcpd.sh
```

---

## CONTROLS PIPELINE (HCP)

Warning: Same logic, but different input format

---

### 1. Clean raw HCP data
Remove non-useful sequences to aliviate the disk:

```bash
bash clean_raw_data_HCP.sh
```

---

### 2. Extract HCP data

Convert HCP structure into BIDS-like dataset:

```bash
bash extract_HCP.sh
```

---

### 3. Verify BIDS dataset

 Use controls mode:

```bash
bash verify_bids.sh --controls
```

---

### 4. Run fMRIPrep

```bash
bash launch_fmriprep.sh --controls
```

---

### 5. Verify fMRIPrep

```bash
bash verify_fmriprep.sh --controls
```

---

### 6. Run MELODIC

```bash
bash launch_melodic.sh --controls
```

---

### 7. Verify MELODIC

```bash
bash verify_melodic.sh --controls
```

---


### 8. Atlas analysis

```bash
bash launch_atlas.sh --controls
```

### 9 - RSN matching inspection


```python
python visualize_correlations.py --controls
```
---
### 10 - Reconstruction of RSNs

```bash
bash launch_reconstruction.sh
```

### 11 - Connectivity ↔ Behavioral correlation analysis

```python
python correlations_atlas.py
```

### 12. Post-processing (XCP-D)

```bash
bash launch_xcpd.sh --controls
bash launch_xcpd_PCA.sh --controls
```

Verify:

```bash
bash verify_xcpd.sh --controls
```

---

### Notes

* Re-running scripts is safe: existing outputs are skipped
* Always verify each step before moving to the next

---

##  Typical Order Summary

### Patients

```
* clean_raw_data.sh
* extract_DICOM.sh
* verify_bids.sh
* launch_fmriprep.sh
* verify_fmriprep.sh
* launch_melodic.sh
* verify_melodic.sh
* launch_atlas.sh
* visualize_correlations.py
* correlations_atlas.py
```

### Controls

```
* clean_raw_data_HCP.sh
* extract_HCP.sh
* verify_bids.sh --controls
* launch_fmriprep.sh --controls
* verify_fmriprep.sh --controls
* launch_melodic.sh --controls
* verify_melodic.sh --controls
* launch_atlas.sh --controls
* visualize_correlations.py --controls
* correlations_atlas.py
```

---

## Output

Final outputs include:

* Preprocessed BOLD data
* ICA components
* Network correlation matrices (`csv/`)
* Atlas-based metrics


# Resting-State Network (RSN) Analysis Pipeline

This repository provides a complete pipeline to:

1. Extract Independent Components (ICs) from MELODIC
2. Match them to known Resting-State Networks (RSNs)
3. Manually inspect and validate results
4. Reconstruct RSN maps per subject


# 🧠 2. RSN Matching (Extraction)


---

# 🔍 3. Visualization / Manual Inspection

A Python script allows you to inspect the matching results.

## ▶️ Run visualization

```bash
python visualize_rsn.py
```

---


---

