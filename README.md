# Callosal disconnection EEG analysis

MATLAB code being prepared to accompany the manuscript:

**Sequential corpus callosal disconnection reveals preferential interhemispheric network disruption**

## Current status

**Private preparation snapshot, not a public release or a complete manuscript
reproduction package.** Two component-level synthetic tests have author-supplied
PASS reports on MATLAB 26.1.0.3312084 (R2026a) Update 4. The tested MATLAB source
bytes and component manifests are preserved in this snapshot.

The scope of these PASS results is limited to the specified fixtures and checks.
No clinical dataset, patient-derived saved model, private exclusion manifest,
or expected clinical result is bundled. No public-release DOI or software license
has been finalized. Do not create a public release from this snapshot yet.

## Components and execution

| Component | Entry point | Test input | Recorded outcome |
|---|---|---|---|
| `components/CC_public_code_stage1/` | `run_synthetic_demo.m` | Newly generated 500-Hz artificial EDFs | PASS |
| `components/CC_public_code_stage2/` | `run_synthetic_group_demo.m` (stage2-v3) | Independently generated summary tables for 24 fictional subjects | PASS |

Stage 1 requires Signal Processing Toolbox and Wavelet Toolbox. Stage 2 requires
Statistics and Machine Learning Toolbox. MATLAB is a separate dependency and is
not distributed with this repository.

To run a component, make that component folder the MATLAB current folder and run
its entry point without arguments. For example, from the repository root:

```matlab
cd(fullfile('components','CC_public_code_stage1'))
outDir = run_synthetic_demo();
```

Or, in a separate invocation from the repository root:

```matlab
cd(fullfile('components','CC_public_code_stage2'))
outDir = run_synthetic_group_demo();
```

Inspect the report written to the returned directory. A returned output directory
by itself is not a PASS: read `STATUS` in `SHARE_DEMO_REPORT.txt` or
`SHARE_STAGE2_REPORT.txt`. Generated output directories are excluded from Git.
There is no need to rerun these tests solely to upload this unchanged snapshot.

Stage 2 does **not** consume the output of stage 1. These are two component tests,
not an end-to-end raw-EDF-to-manuscript run. No biological effect direction or
nominally significant P value is required as a test target.

## Validation evidence and source provenance

The latest author-supplied reports are retained verbatim:

- `validation/stage1_pass_report.txt`
- `validation/stage2_v3_pass_report.txt`

See `docs/VALIDATION.md` for the tested scope and limitations, and
`docs/COVERAGE_AND_NEXT_STEPS.md` for remaining release assembly.

All files under `components/` are unchanged snapshots of the tested packages.
Their original preparation notes, warnings that execution was still pending,
and earlier failure reports are preserved as history. Those historical notes do
not override the later PASS reports above. The authoring environment did not
itself execute MATLAB, and the combined directory layout has not been separately
runtime-tested.

`docs/SNAPSHOT_MANIFEST.json` records the source archive, original member path,
SHA-256 and byte length for each component file. The unchanged internal
`SHA256SUMS.txt` manifests can still be checked by the component entry points.
`.gitattributes` requests preservation of file bytes without automatic newline
conversion by Git clients. Do not edit a component simply to make a hash pass.

## Important analysis distinctions

The source and manuscript distinguish primary regional WTC selection from
exact-time interhemispheric/intrahemispheric pairing, and both from the post hoc
matching of complementary metrics to primary-selected keys. The group component
checks these interfaces on artificial observations, including missing pairs.

Residual coefficient inference and Satterthwaite omnibus/contrast inference are
explicit in the group test. Its paired-patient dwPLI bootstrap is not the
refitted patient-cluster LMM bootstrap. Clinical comparisons, final-cohort
exclusion decisions and manuscript figure export are not supplied as a complete
reproduction workflow in this snapshot.

## Data protection

Do not commit patient EEGs, MRI images, clinical spreadsheets, identifiers,
patient-level derived datasets, private manifests, saved clinical model objects,
local command histories, credentials or local diagnostic logs. Private repository
visibility does not make those files appropriate for inclusion.

The tests generate artificial signals/tables locally without reading patient
records. Only reviewed source code, documentation and synthetic-test reports are
included here. `.gitignore` is an exclusion aid, not proof that a file is safe.

## License, citation and release

Licensing, authorized software creators, citation metadata and the exact release
scope remain to be finalized. No license is assigned by this preparation
snapshot. Do not list every manuscript coauthor as a software creator without
confirming their actual software contribution and agreement.

No placeholder DOI is used as a real identifier. The manuscript's public code
availability statement must be finalized only when the stated code scope is
actually available and the archived version can be accessed.
