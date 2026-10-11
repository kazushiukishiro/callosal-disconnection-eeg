# Stage 3: WTC sensitivity code preparation

**Local validation candidate, not a public release.**

**Package: stage3-sensitivity-v2.** This patch fixes a report-buffer name
collision with MATLAB `log` in the test driver. See `docs/PATCH_V2.md`.
The statistical wrapper and synthetic fixture are unchanged; MATLAB
runtime validation of this patched driver is still pending.

This adds callable versions of the documented leave-one-patient-out (LOO),
patient-cluster bootstrap and logit-WTC sensitivity procedures. It is a new
packaging layer based on supplied code/history, **not an untouched final
clinical script and not proof that the final cohort results are reproduced**.

## Run this test

MATLAB R2026a and Statistics and Machine Learning Toolbox are required. Java
is used for SHA-256 integrity checks, as in the preceding test packages.

From this extracted folder:

```matlab
outDir = run_synthetic_sensitivity_demo();
winopen(outDir);
```

The driver accepts no study-data filename. It generates artificial summary
tables from the unchanged stage-2 fixture. It never loads patient EDFs, clinical
spreadsheets, saved MAT/model files or the base workspace. Stage 1 and Stage 2
are **not** re-executed.

The new output folder contains `SHARE_STAGE3_REPORT.txt` and synthetic-only
CSV outputs. The text report is intended for review; `LOCAL_DIAGNOSTICS.txt`
can contain local paths and should remain local. Output filenames explicitly
identify artificial data and the short bootstrap test.

## Test scope

1. Validate input uniqueness, exact Inter/Intra pairing, logit boundary handling,
   and distinct new bootstrap cluster IDs for repeated draws of one subject.
2. Fit the logit-WTC model on the artificial table.
3. Remove every artificial subject once, fitting primary, region-interaction
   and exact-time-interaction models. Check row counts independently.
4. Fit both bootstrap models on the same 50 artificial subject-cluster draws.
   Check failure accounting, percentile construction and RNG restoration.

**50 resamples are used only to exercise the software loop.** They are not a
precision assessment, a replacement for the source script's default 2000
resamples, or a reproduction of the manuscript's bootstrap intervals.
The published paired-patient dwPLI bootstrap is a different procedure and
is not rerun or changed here.

`STATUS: PASS` means the specified tests completed without failures/recorded
fit warnings. `REVIEW_REQUIRED` means checks completed but failures or recorded
warnings require review. `FAIL` means an error/assertion stopped execution.
The driver records the last warning per fit; it does not suppress MATLAB warnings
and is not an exhaustive warning-monitoring or convergence-diagnostics system.
No expected significance, direction, clinical effect size or patient count is
used as a success criterion.

## Source and data boundaries

See `docs/SOURCE_PROVENANCE.md` for historical code ranges and all adaptations,
and `docs/INPUTS_AND_LIMITS.md` for the input schema and exclusions.
Source excerpts are reference text, not standalone scripts to execute.

No study files were altered while this package was prepared. The preparation
environment had no MATLAB runtime; runtime success is not claimed in advance.
A package manifest and lexical delimiter checks do not replace MATLAB tests.

Before a manuscript-wide release, clinical modifiers/rank tests, cohort assembly
with an explicit private exclusion interface, plotting and source equivalence
still require their own mapping/status. Do not carry this synthetic PASS forward
as evidence for those separate components. No license or DOI is assigned here.
