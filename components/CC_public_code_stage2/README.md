# CC public code: stage-2 group-level integration candidate

This is a **test and packaging candidate**, not a complete public release.
It must not replace the frozen study code or be described as reproducing
clinical findings. No patient data are distributed or read by its entry point.

## Run

In MATLAB R2026a with Statistics and Machine Learning Toolbox, change to this
folder and run:

```matlab
outDir = run_synthetic_group_demo();
```

Do not edit package files before the test: their hashes are checked.
The entry point restores the current folder, search path, and random-number
state. Outputs are in a newly created `group_demo_output` subfolder. It reads
only its source files and checksum manifest; it does not search the clinical
project, load EDFs, read a clinical workbook, load a frozen MAT, or use base
workspace datasets. Only synthetic statistical models are fitted.

## Data used

`cc_synthetic_group_fixture` generates artificial epoch-level **summary** tables
for 24 fictional subjects. These are independently generated summary test
fixtures, **not** outputs of the stage-1 artificial EDFs and not de-identified
patient data. Numerical parameters and missingness are deliberately arbitrary.
No clinical WTC mean, F statistic, P value, patient count, or significant
state effect is required for a PASS. A fictional regional exclusion tests
post-selection handling; it is not the actual clinical exclusion manifest.

## Tested interfaces

1. Primary epoch selection, uniqueness and missing/nonfinite value rejection.
2. Matching all complementary metrics to a fixed primary key set.
3. Regional averaging before patient averaging; within-patient Pre normalization.
4. Primary, regional, exact-time, individual-band, signal-level, and frequency
   interaction LMM interfaces on synthetic observations.
5. Residual coefficient inference versus Satterthwaite omnibus/contrast inference.
6. Regional contrast construction and Holm-adjustment invariants.
7. The saved paired-patient dwPLI bootstrap helper, with exactly 10,000 resamples
   for each contrast; RNG restoration and pairing checked.
8. Primary versus exact-time metric source separation and missing-pair handling.

No test requires a particular biological conclusion or a nominally significant P.

## Provenance

Nineteen local numerical helpers are copied exactly from the previously saved
`run_cc_matched_epoch_sensitivity.m`. Their extraction hashes are recorded in
`docs/NUMERIC_SOURCE_HASHES.json`. New code consists of an in-memory dispatcher,
a synthetic fixture, the test driver, an explicit regional-contrast wrapper,
and a primary/exact-time metric-source wrapper.

This reuse does **not** mean the complete original source-file loading,
clinical exclusion manifest, or final clinical-data workflow has been copied.
See `docs/SOURCE_PROVENANCE.md` and `docs/VALIDATION_STATUS.md`.

## Outputs

`SHARE_STAGE2_REPORT.txt` contains aggregate test status only.
`LOCAL_DIAGNOSTICS.txt` may contain local paths in exception traces; it is not
intended for sharing. `SYNTHETIC_ONLY_*.csv` are artificial demonstration output,
not manuscript results. No fitted model object or MAT file is saved.

A fit warning produces `REVIEW_REQUIRED`, even if all assertions complete.
An exception produces `FAIL`; inspect the failed stage rather than removing
checks. `PASS` requires all checks to complete without a recorded fit warning.

## Not tested or not included

- Real-cohort final technical exclusion decisions and private input manifests.
- Numerical equivalence to the final clinical tables or figures.
- Raw 1000/2000-Hz EDFs; stage 2 performs no EDF or signal calculations.
- Refitted patient-cluster bootstrap, leave-one-out models, modifier LMMs,
  clinical rank tests, seizure outcome eligibility, or Figure 4 export.
- The actual GitHub upload, public release, license decision, or Zenodo DOI.

The stage-1 report is retained separately in `validation/STAGE1_REPORT.txt`.
It records a successful 500-Hz synthetic EDF smoke test, not clinical validation.
The stage-2 entry point has not been run in MATLAB in the authoring environment.

## License

A license has not been assigned in this preparation package. The authorized
rights holder must finalize licensing before public release.

## Current candidate: stage2-v3

This patch corrects the empty selected-time comparison in the test harness,
not the primary selection algorithm. See `docs/PATCH_V3.md`.
Do not claim PASS based on packaging checks alone.
