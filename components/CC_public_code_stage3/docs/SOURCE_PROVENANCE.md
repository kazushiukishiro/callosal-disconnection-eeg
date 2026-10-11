# Source provenance and adaptation boundaries

## Supplied sources consulted

- Uploaded MATLAB command history, lines 3566-3628: primary and State x Region LOO
  loops, named coefficient extraction, Satterthwaite omnibus tests.
- Same history, lines 3757-3805: exact-time State x ConnectionType LOO loop.
- Same history, lines 6358-6378: later QC-clean logit block, epsilon 1e-6 bound,
  logit transform and primary model. In the immediately preceding preparation,
  region categories were FT,T,TO,CP,PO. The logit wrapper retains that reference.
- `run_cluster_bootstrap_sensitivity.m`, particularly lines 129-228: shared
  subject draws, replicated clusters with new BootCase and BootCaseRegion IDs,
  primary/exact-time LMM refits and recording of failed refits. Its specified
  random seed is 20260820 and replicate count 2000. These are defaults of that
  supplied source; this document does not independently certify the parameters
  or numerical outputs of a final clinical run.

The relevant excerpts are supplied as text under `source_excerpts`. They are
not complete runnable scripts. They omit workstation paths and private input
loading. `SOURCE_EXCERPT_HASHES.json` records the exact ranges and SHA-256
checksums of the UTF-8 text extracts. The full command history is not distributed.

The available historical LOO/bootstrap code by itself does not establish which
final QC-clean table was used for every later reported result. This package
therefore accepts cleaned tables as inputs rather than inventing that history.
It does not relabel the supplied historical loops as a verified final-cohort run.

## New code

`src/cc_wtc_sensitivity.m` is newly assembled, callable code, not a byte-for-byte
copy of the original scripts. `run_synthetic_sensitivity_demo.m` is a new test
driver. Changes relative to the historical execution context include:

- Explicit table arguments instead of base-workspace variables or file searches.
- Strict validation of observation keys, finite WTC and exact-time pairs. Invalid
  inputs are rejected rather than silently filtered or repaired.
- Explicit ML fits (the documented `fitlme` default), explicit Satterthwaite
  omnibus tests, and separately labelled Residual coefficient tests/intervals.
- Explicit state/reference categories; unused CaseNo levels are removed for LOO.
  Primary/regional/bootstrap region order is CP,FT,PO,T,TO. Logit uses the later
  block's explicit FT,T,TO,CP,PO order. No category order is inferred from results.
- Non-finite/out-of-[0,1] WTC is rejected; the documented epsilon 1e-6 bound is
  retained for the logit transformation and boundary-change counts are returned.
- Bootstrap draws retain complete subject clusters with new replicate-specific
  IDs. Both model families share draws and require the same source case set.
- The bootstrap default is 2000; the new synthetic driver explicitly requests 50
  and labels its outputs accordingly. RNG state is restored after bootstrapping.
- Failed refits are retained in the accounting and the percentile construction
  uses finite complete coefficient triplets, as in the supplied algorithm.
  No retries, significance-target tuning or forced replacements are performed.
- Warning/failure identifiers, counts and messages are returned; warnings are not
  disabled. `lastwarn` captures the last warning from a fit, not all diagnostics.
- Outputs are ordinary tables/arrays rather than saved clinical model objects.
  The new wrappers have no file I/O; only the synthetic driver writes new files.

These changes make clinical-output equality an explicit **unperformed** check.
Matching formulas and synthetic invariants do not prove such equality.

## Unchanged dependencies

`dependencies/cc_public_group_ops.m` and
`dependencies/cc_synthetic_group_fixture.m` are byte-identical to stage2-v3.
They are included locally so this test does not depend on the research folder
or require downloading the GitHub repository. The stage-2 driver and its already
passed test suite are not run again. The fixture remains 24 fictional subjects
with arbitrary, non-monotonic patterns and no clinical input values.

## Official interface documentation consulted

- https://www.mathworks.com/help/stats/fitlme.html
- https://www.mathworks.com/help/stats/linearmixedmodel.html
- https://www.mathworks.com/help/stats/linearmixedmodel.anova.html

Served documentation may describe a later MATLAB version. The runtime target is
R2026a; compatibility/success is established only by the author's actual test.
