# Numerical provenance and new packaging code

## Retained helpers

The following functions are exact text extracts, including their function
headers and internal logic, from the saved post hoc analysis utility
`run_cc_matched_epoch_sensitivity.m`:

- `valueEpochs`, `alignToPrimary`, `patientValues`, `describeValues`, `moments`
- `modelTable`, `omnibusTable`, `lmmContrasts`
- `bootstrapContrasts`, `contrastTable`
- `canonicalEpochs`, `canonicalGroups`, `epochKey`, `groupKey`
- `selectPrimary`, `groupedValues`, `appendTable`, `requireColumns`, `requireNumeric`

Hashes of the complete source and each extracted block are in
`NUMERIC_SOURCE_HASHES.json`. The original complete source is not distributed
here: its workstation-specific paths and clinical exclusion identifiers have
not been copied into this package. All 19 extracted blocks were compared to
the saved source during packaging.

The original paired bootstrap helper labels its method as 10000 resamples.
The public dispatcher therefore fixes B=10000 and does not expose a different
count under that label. Its random-number changes are scoped and restored.
Negative finite dwPLI values are retained; no percent-normalized dwPLI is used.

## New code, not an untouched historical script

`cc_public_group_ops` adds a public dispatcher with input validation. It does
not derive a real-cohort selection mask or an exclusion list.

`cc_connectivity_change_sources` is a newly packaged implementation of the
previously documented metric definitions. It takes input tables directly,
checks uniqueness, distinguishes primary and exact-time sources, and propagates
missing source measurements. It does not merge patient identifiers, fit
clinical models, classify outcomes, or validate follow-up dates.

`cc_regional_contrasts` is a new name-based contrast construction wrapper for
a State x Region model with Pre and CP reference categories. It computes the
15 adjacent-stage regional contrasts and Holm adjustment. It has not been
checked against a private clinical result in this package. No printed
manuscript P values are input to it.

The fixture and `run_synthetic_group_demo` are new test code. Their model
formulas follow the reviewed manuscript/source definitions. They fit only
artificial tables and make no assertion that the complete clinical pipeline
has been reconstructed or that study outputs have been reproduced.

## Inference interfaces

- The primary and exact-time synthetic fits expose both Residual and
  Satterthwaite coefficient summaries. The test verifies identical estimates
  and SEs, and checks Residual degrees of freedom against n minus p.
- Omnibus tests use explicit Satterthwaite degrees of freedom.
- Matched complementary contrasts use the retained `coefTest` helper with
  explicit Satterthwaite degrees of freedom.
- The synthetic report replaces the helper's `N_RegionalObservations` output
  label with `N_Observations` and states each model's observation unit; the
  exact-time model does not use regional observations.

Official interface references consulted during preparation:

https://www.mathworks.com/help/stats/linearmixedmodel.html
https://www.mathworks.com/help/stats/linearmixedmodel.fixedeffects.html
https://www.mathworks.com/help/stats/linearmixedmodel.coeftest.html
https://www.mathworks.com/help/stats/linearmixedmodel.anova.html

The currently served documentation may show a later MATLAB release. The
runtime target of this test remains the user's MATLAB R2026a; runtime success
is not inferred from the documentation.
