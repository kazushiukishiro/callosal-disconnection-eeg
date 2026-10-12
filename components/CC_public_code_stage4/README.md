# Clinical-analysis component: synthetic verification, stage 4

**Private preparation package; not a public release.** This component adds
callable clinical-modifier and rank-test code to the previously tested
connectivity components. Its new MATLAB entry point has not been executed in
MATLAB by the package preparer. Author-side testing is required.

## Run

In MATLAB R2026a with Statistics and Machine Learning Toolbox, open this
folder and execute:

```matlab
outDir = run_synthetic_clinical_demo();
```

No patient EDF, MAT file, Excel file or clinical table is selected. The demo
creates a new `clinical_demo_output/` directory on each run and restores the
caller's directory, path and random-number state on exit. It reads only this
package's source files and manifest. It does not access the base workspace.

Send `SHARE_STAGE4_REPORT.txt` for review. Keep `LOCAL_DIAGNOSTICS.txt` local:
full exceptions may contain local filesystem paths. The generated CSVs contain
synthetic-only results and must not be substituted for manuscript results.

## Test phases

1. Construct artificial regional/exact-time inputs and shuffled clinical
   covariates; check joins, source-specific reductions and invalid inputs.
2. Test explicitly routed Spearman, Wilcoxon rank-sum and Kruskal-Wallis
   analyses with comparison to native MATLAB calls and independent rank
   calculations. Constant/insufficient data produce labelled undefined tests.
3. Fit five clinical-modifier LMMs on the artificial primary regional table:
   age at onset, age at surgery, epilepsy duration, onset-plus-duration and
   standardized onset-plus-duration.
4. Refit extracted historical numerical blocks on the same artificial input.
   Compare centering, formulas, coefficient estimates/SEs/CIs/P values,
   Satterthwaite F-tests and model-specific observation counts.

No significance threshold, expected clinical statistic or desired direction
is used as a test-success criterion. There is no bootstrap or EDF processing
in this component. Stages 1-3 are not rerun.

## What this does not establish

A PASS is limited to these artificial inputs and checks. It does not establish
numerical equivalence on the real cohort, recreate the original eligibility
review, verify the clinical MRI-laterality output source, or reproduce the
published tables. It is not an end-to-end EDF-to-cohort test. Native-rate EDF
tests and figure exports are not included.

## Files

- `src/`: new callable clinical adapters, tests and synthetic fixture.
- `dependencies/`: unchanged functions from the stage-2 v3 package.
- `reference/`: selected numerical blocks from the supplied modifier script,
  with test-only function wrapping and warning capture; no clinical I/O.
- `docs/`: input schema, provenance, source routing and validation limits.
- `SHA256SUMS.txt`: file integrity manifest, excluding the manifest itself.

The software license and final public-release metadata are not assigned by
this preparation package. Preserve source attribution. Do not upload clinical
inputs, source workspaces, patient-level outputs or model objects.
