# Stage 3 sensitivity patch v2

## Observed failure

The author-supplied stage3-sensitivity-v1 report states `STATUS: FAIL`,
`FAILED_STAGE: logit synthetic fit`, `ERROR_IDENTIFIER: MATLAB:badsubscript`,
and `STACK: run_synthetic_sensitivity_demo | line 69`. Package integrity,
fixture construction, boundary/input checks and cluster-ID checks passed.
The reported fixture contained 24 fictional subjects, 469 regional summaries
and 190 exact-time summaries.

## Cause found in the distributed v1 source

The main demo function created a cell-array report buffer named `log` at
line 21. Its line 69 then used `log(expectedY./(1-expectedY))` to check the
returned transformation. In that workspace MATLAB resolves the variable
before the mathematical function, so the expression attempts array indexing.
The local `checkUnitInputs` function has a separate workspace; its earlier
natural-log check therefore did not expose this collision.

The `cc_wtc_sensitivity('logit',W)` call is on line 67, before the reported
line 69. This is a failure in checking the returned logit result, not evidence
that the optimizer failed. LOO and bootstrap had not yet been reached.
No validity or convergence claim is made for unreviewed model outputs.

## Changes

1. Rename the driver's report buffer from `log` to `reportLines`, including
   all reads, writes and failure reporting. Leave numerical `log(...)` calls
   unchanged.
2. Add a same-workspace check before the model fits: no `log` variable, plus
   a natural-log probe at exp(-1), 1 and exp(1). This is an additional test;
   no old numerical acceptance check is removed or relaxed.
3. Distinguish the stage label `logit output verification` from the fitting
   stage, so a subsequent checking error cannot be mistaken for fit failure.
4. Update the package tag, README and checksum manifest; add these patch notes
   and a static diff-verification record.

No changes were made to `src/cc_wtc_sensitivity.m`,
`dependencies/cc_public_group_ops.m` or
`dependencies/cc_synthetic_group_fixture.m`.
The transformation bound (1e-6), formulas, ML/DF methods, artificial fixture,
seeds, 50-resample test, 2000-resample function default, warning/failure policy,
and numerical test tolerances are unchanged.

## Verification limits

Patch changes were checked using a reversible exact source diff, byte-by-byte
comparison of unchanged MATLAB files, and SHA-256 verification of all listed
package files. This is not MATLAB execution, MATLAB Code Analyzer output, or
a MATLAB parser result. No MATLAB or Octave runtime is available in the
patch-authoring environment. Runtime validation of v2 remains pending.

Run only this stage on synthetic inputs in a newly extracted folder. Do not
change the manuscript or clinical analyses in response to this driver error.
Keep the repository private and do not publish this candidate as a release.
