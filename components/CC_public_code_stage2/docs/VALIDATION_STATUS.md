# Validation status at package preparation

## Stage 1: author-supplied runtime report received

The unmodified report in `validation/STAGE1_REPORT.txt` says `STATUS: PASS`
on MATLAB 26.1.0.3312084 (R2026a) Update 4. It reports a 500-Hz, 630-second,
16-channel artificial recording fixture with fixed fictional headers.
Primary WTC/dwPLI/exact-time, multiband, signal metrics, boundary handling,
and the specified dwPLI edge cases passed the stage-1 smoke test.

Those observations do not validate 1000/2000-Hz input or the clinical cohort.

## Stage 2: v2 repair awaiting the user's MATLAB execution

The original stage-2 run failed during stage 1/5 with a parse error in
`cc_synthetic_group_fixture.m`, line 59. The denominator lacked one closing
parenthesis. No synthetic group-model fits were reached in that run.
Version 2 adds that parenthesis and preserves all four other MATLAB files.
See `PATCH_V2.md`. This correction has not yet received a MATLAB runtime
PASS report.

During package preparation, source block hashes, file contents and the
synthetic-only input/output design were inspected. The new stage-2 MATLAB
entry point was NOT executed in the authoring environment. It must not be
labelled as runtime-tested until its report is reviewed.

`PASS` is limited to the explicitly listed synthetic tests. A fit warning is
reported as `REVIEW_REQUIRED`. A thrown exception is reported as `FAIL`.
Warnings and failures must not be hidden to obtain a passing status.

The stage-2 summary fixtures are not generated through stage 1. A passing
stage 1 plus a passing stage 2 is not a claim of end-to-end clinical
reproducibility or a complete software-validation study.


## Stage 2 v3

The v2 runtime stopped with CCGroupDemo:Selection after package integrity passed.
V3 fixes empty-vector orientation in the newly written verifier, adds boundary
regressions and diagnostic output, and retains all four src files unchanged.
No v3 MATLAB runtime result is available yet. See PATCH_V3.md.
