# Matched Figure 4 plotting source, colour version 3

`make_figure4_matched_epoch_v3.m` is copied byte-for-byte from the previously
supplied `CC_Figure4_colours_v3.zip`. It is the matched-epoch colour-v3 function,
not `Figure4_FINAL_QC_clean.m` or an original-epoch Figure 4 replacement.
No statistical model is refitted by this plotting function.

## Input and output contract

Call `outDir = make_figure4_matched_epoch_v3(inputDir)` after adding this
function's folder to the MATLAB path. `inputDir` must contain all five authentic
analysis outputs, with the exact schemas enforced by `readResultCSV`:

- `CC_matched_epoch_descriptive.csv`
- `CC_matched_epoch_models.csv`
- `CC_matched_epoch_contrasts.csv`
- `CC_matched_epoch_status.csv`
- `CC_matched_source_verification.csv`

These input CSVs are **not** included in this repository. The function checks
column names, source-verification and module statuses, state/metric uniqueness,
means/SDs/SEMs, sample counts, epoch coverage and model observation counts before
plotting. A status value must originate from its actual analysis; do not create
fictitious PASS rows, substitute a different selection or relax checks to force
figure export.

The Matched rows produce `Figure4_matched_epoch`; Original rows produce
`Supplementary_original_epoch_selection`. The latter is descriptive and does
not inherit Matched-model F/P annotations. The code exports vector PDF/EPS and
TIFF/PNG at 18.5 x 7.4 cm. A/B use raw patient-level means +/- SEM; C uses
within-patient Pre-normalized means +/- SEM. F/P labels are read from the model
CSV, never inferred from the visual trajectories.

## Privacy and runtime status

The function copies its input CSVs into a newly created output folder beneath
its own folder. **For private inputs, run a copy of this function in a separate
local working directory outside the Git repository.** Do not commit the copied
inputs, generated images or other outputs. `.gitignore` is not a privacy check.

The four synthetic PASS reports concern `components/`, not this function.
No new MATLAB execution or automated figure-export test was performed when it
was added here. It is included as supplied source, not labelled as a fifth
synthetic PASS. Only source bytes and the input/export contract were checked.
The publication's final EPS formatting may include subsequent manual cropping.
