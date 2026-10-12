# Source provenance and changes

This package adds newly callable wrappers. It is not a claim that the complete
historical scripts are reproduced byte-for-byte or that real-cohort outputs
are verified. Patient files and expected clinical results are excluded.

## Supplied sources reviewed

- `run_FINAL_QC_clean_effect_modifiers.m`: joined regional-row centering and
  standardization; five model formulas; Satterthwaite ANOVAs, Residual
  coefficients; unique-patient Spearman correlations among covariates.
- `run_FINAL_QC_clean_clinical_outcome.m`: finite-pair correlation masks;
  group-0/group-1 rank-sum tests; laterality Kruskal-Wallis tests; output-grade
  convention. Its original ordinary reductions all use exact-time data.
- The later patient-table reconstruction in the supplied command history and
  the final manuscript clarify the alternative primary reductions used for
  binary and seizure-outcome comparisons, while selective reduction remains
  exact-time. The raw command history is NOT packaged.

## Reference blocks

`reference/cc_modifier_reference_blocks.m` contains the source script's
numerical line ranges:
- 50-62
- 77-80
- 86-86
- 94-97
- 103-103
- 111-114
- 120-120
- 128-132
- 138-138
- 146-150
- 156-156
- 164-173

Every listed numerical block is retained as text. Added scaffolding passes W
as an input, captures the last warning per fit and returns outputs; console
printing, research-path setup, base-workspace lookup, patient-file reads and
save operations are omitted. No patient-specific expected values are added.

## New production adapters

- `cc_join_clinical_inputs`: strict key/coding checks and pseudonymous in-memory
  joins. Duplicate/invalid input now stops rather than being silently recoded.
- `cc_clinical_test_plan`: source-specific test routing. Two ordinary reduction
  sources for laterality are retained rather than choosing one automatically.
- `cc_clinical_rank_tests`: native MATLAB tests with labelled undefined
  outputs and additional N/statistic/provenance fields. P values are not
  adjusted and method selection is not forced.
- `cc_clinical_modifier_models`: same centered variables/model formulas;
  FitMethod='ML' made explicit; ordinary tables returned without saving models.
- `cc_synthetic_clinical_fixture`, `run_synthetic_clinical_demo`: new artificial
  input and test harness only. Not analysis of the clinical cohort.

Three dependencies copied from stage-2 v3 are byte-identical; their hashes
are in SOURCE_HASHES.json. Local manifest/report/path/RNG utility definitions
are reused from the author-tested stage-3 v2 entry point. Source-line and
hash records support traceability, not numerical validation by themselves.

## Primary documentation consulted

- MATLAB fitlme: https://www.mathworks.com/help/stats/fitlme.html
- MATLAB ranksum: https://www.mathworks.com/help/stats/ranksum.html
- MATLAB kruskalwallis: https://www.mathworks.com/help/stats/kruskalwallis.html

Preserve original-source attribution when choosing the final software license.
No software license is assigned by this private test package.
