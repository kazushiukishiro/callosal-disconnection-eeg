# Callosal disconnection EEG analysis

MATLAB source functions and refactored analysis components accompanying:

**Sequential corpus callosal disconnection reveals preferential interhemispheric network disruption**

Software creator and copyright holder: **Kazushi Ukishiro**. License: **MIT**.
Software version prepared for the first release: **1.0.0**.

## Scope

This source distribution contains the original supplied per-recording EEG
functions, reusable group/sensitivity/clinical analysis components, synthetic
component demonstrations and their author-supplied validation reports.
Supplementary sources include the matched Figure 4 colour-v3 plotting function
and the supplied residual-splenium per-recording function.

It is **not a complete end-to-end reproduction package for the 32-patient study**.
No patient EEG, MRI, clinical record, patient-derived saved model or private
exclusion manifest is distributed. Stages 2-4 generate their own artificial
summary tables rather than consuming the stage-1 EDF output. Figure 2/3 rendering,
the Figure 1 illustration, the complete Figure 5 composite and an automatic
private-cohort driver are not supplied. See `docs/MANUSCRIPT_CODE_MAP.md` and
`docs/INPUTS_AND_PRIVATE_DATA.md` for the exact boundaries.

## Components and execution

| Component | Entry point | Test input | Reported status |
|---|---|---|---|
| `components/CC_public_code_stage1/` | `run_synthetic_demo.m` | New 500-Hz artificial EDFs | PASS |
| `components/CC_public_code_stage2/` | `run_synthetic_group_demo.m` (v3) | Independent artificial epoch/summary tables | PASS |
| `components/CC_public_code_stage3/` | `run_synthetic_sensitivity_demo.m` (v2) | Artificial summaries; logit, 72 LOO fits, 50 cluster-bootstrap draws | PASS |
| `components/CC_public_code_stage4/` | `run_synthetic_clinical_demo.m` (v1) | Artificial summaries/covariates; 28 rank tests and five modifier models | PASS |

Each component retains the exact files tested by the author on MATLAB
26.1.0.3312084 (R2026a) Update 4. Stage 1 requires Signal Processing Toolbox and
Wavelet Toolbox. Stages 2-4 require Statistics and Machine Learning Toolbox.
MATLAB and its toolboxes must be installed separately and are not redistributed.

Start each example at the repository root, change to the chosen component folder
and call its entry point without arguments. For example:

```matlab
cd(fullfile('components','CC_public_code_stage1'))
outDir = run_synthetic_demo();
```

Or, again starting at the repository root:

```matlab
cd(fullfile('components','CC_public_code_stage2'))
outDir = run_synthetic_group_demo();
```

The sensitivity and clinical components use the corresponding stage3/stage4
folder and entry point in the table. Each entry point creates a new local output
directory, restores its internal path/directory changes and returns the output
path. It may return that path after writing a FAIL report: **inspect `STATUS`
in the generated `SHARE_DEMO_REPORT.txt`, `SHARE_STAGE2_REPORT.txt`,
`SHARE_STAGE3_REPORT.txt` or `SHARE_STAGE4_REPORT.txt`**. A return value alone
is not a successful validation result. Do not put all component directories on
the MATLAB path simultaneously: some intentionally preserve identical copies
of dependency functions.

No repeated MATLAB run is required merely to store the unchanged files.
Outputs are excluded from Git by `.gitignore`; manual browser uploads still
require reviewing every file.

## Supplementary source code

| Source | Purpose | Validation boundary |
|---|---|---|
| `supplementary_code/figure4/make_figure4_matched_epoch_v3.m` | Plot supplied matched/original group summaries without refitting models | Unchanged supplied source; five external CSV inputs required; no new automated export test |
| `supplementary_code/residual_splenium/analyze_residual_splenium_case.m` | Per-recording Pre/Splenium/Post analysis | Unchanged supplied source; no stage-5 synthetic or clinical run |

See the README in each folder. These sources are not a fifth PASS test, and
patient-derived inputs or publication images are not bundled with them.

## Validation and provenance

Latest author-supplied reports are preserved verbatim in `validation/`:
`stage1_pass_report.txt`, `stage2_v3_pass_report.txt`,
`stage3_v2_pass_report.txt`, and `stage4_v1_pass_report.txt`.

The first report covers the 500-Hz artificial EDF fixture. The later reports
cover independent artificial summaries and explicitly scoped checks. Their PASS
results do not establish biological validity, clinical safety, real-cohort
numerical equivalence or validation of all possible inputs. The 50-resample
cluster-bootstrap test is not the full 2,000-resample study-code run.

`docs/VALIDATION.md` preserves the detailed limits. `docs/SNAPSHOT_MANIFEST.json`
records the 69 unchanged component files and their source archives.
`docs/STAGE5_AUDIT.json` records the reviewed GitHub archive and the two added
source files. `PACKAGE_SHA256SUMS.txt` covers the current tree except itself.
`.gitattributes` disables automatic Git newline conversion to help preserve
source bytes; it is not an access-control or privacy mechanism.

The component folders also retain preparation notes, earlier FAIL reports and
pending-test statements as history. Later PASS reports establish the bounded
status of their corresponding unchanged component versions. Preparation-time
"license not assigned" statements are superseded by the root `LICENSE`;
see `NOTICE.md`. No component code or internal manifest was edited for release
packaging. The packaging environment did not execute MATLAB.

## Analysis distinctions

Primary regional WTC selection, exact-time Inter/Intra pairing and post hoc
matching of complementary metrics to primary-selected keys remain separate.
The original numerical code, extracted source blocks and refactored wrappers
are identified in the component provenance notes. Residual coefficient inference
is distinguished from Satterthwaite omnibus/contrast inference. The paired-patient
dwPLI bootstrap is not the refitted patient-cluster LMM bootstrap.

Clinical measures retain explicit primary/exact-time source labels. Outcome
inputs must already be masked for eligibility by the caller. The synthetic
tests do not determine the historical MRI-laterality route or validate clinical
follow-up eligibility. Do not infer a missing clinical route from synthetic P
values or change exclusions to match the manuscript.

## Data protection

Do not commit patient recordings, images, identifiers, clinical spreadsheets,
patient-level derivatives, private manifests, saved clinical models, histories,
credentials or diagnostic logs. Use a separate local working copy when running
any supplied function on authorized private data. The synthetic examples
construct their inputs without reading patient records.

The inspected source archive contained no bundled EDF, MAT, clinical spreadsheet,
patient-level CSV/TSV or image file. This is a bounded file/content review of that
snapshot, not a guarantee about Git history or future uploads.

## License and citation

The MIT License in `LICENSE` carries `Copyright (c) 2026 Kazushi Ukishiro`.
External dependencies remain under their own terms. The software creator is
listed in `CITATION.cff`; paper coauthorship is not automatically software
authorship. Please cite the specific archived software version when its Zenodo
record is available, in addition to the paper when appropriate.

A version string in this source tree is not evidence that a GitHub Release or
Zenodo record has been published. No DOI, release date or ORCID has been invented.
`docs/RELEASE_STEPS.md` describes publication and archival; the actual version
DOI belongs in the manuscript and the GitHub release description after it is
verified. Availability must not be claimed while the repository is private.
