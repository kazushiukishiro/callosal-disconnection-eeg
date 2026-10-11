# Validation record for the private stage-1/stage-2 snapshot

## Evidence

The evidence is the two author-supplied runtime reports in `../validation/`.
Both report MATLAB 26.1.0.3312084 (R2026a) Update 4. The reports contain no run
timestamp, operating-system field, raw output matrices, or complete console log;
those details are not inferred. `STATUS: PASS` is the driver's reported outcome,
not independent certification of the numerical implementation or biology.

## Stage 1

The recorded fixture is 500 Hz, 630 s, 16 channels, with fictional event offsets
330/360/390 s. The report records package integrity/function resolution,
small-overlap trimming, positive-gap preservation, selected dwPLI edge cases,
primary WTC/dwPLI/exact-time processing, multiband processing, signal metrics,
common-output agreement and synthetic-only summary export.

It records 85 candidate epoch-region rows, 80 selected rows, 20 summaries and
16 exact times for that fixture only. Those are not clinical cohort counts.

## Stage 2 v3

The report records successful selection/normalization boundary checks, including
empty arrays and rejection of wrong times/counts; key uniqueness and handling of
missing/non-finite inputs; an explicit fictional exclusion after selection without
refill; matching of eight complementary metrics to selected primary keys; primary,
regional and exact-time model checks; 15 regional contrasts with Holm adjustment;
eight complementary models; and the State-by-FrequencyBand model.

It also records 10,000 paired-patient bootstrap resamples per dwPLI contrast,
pairing/mean-difference checks, RNG restoration, and separation of primary versus
exact-time metric sources with incomplete-pair handling.

The fixture has 24 fictional subjects, 3,960 candidate rows, 3,370 selected rows
after a fictional exclusion, and 469 regional rows. These values describe a
software fixture, not the study cohort or a target for the clinical analysis.

The empty-vector probe records logical indexing as 0-by-1 and bracket indexing
as 0-by-0, unequal directly but equal after column-vector conversion. The v3
selection boundary checks passed; the earlier v2 failure report remains only as
historical evidence inside the component snapshot.

## Not established

These reports do not establish end-to-end EDF-to-cohort reproduction, equality
with saved clinical outputs, biological validity, or a validated clinical tool.
Stage 2 uses freshly generated summary tables, not stage-1 outputs.

The reports explicitly do not cover native 1000/2000-Hz EDFs, all possible
artefacts/missing-data patterns, real-cohort exclusions/private manifest,
leave-one-out refits, the refitted patient-cluster bootstrap, modifier LMMs,
clinical rank tests, postoperative outcome eligibility, or figure export.

## Packaging check performed for this snapshot

All 34 source-package files, including 16 MATLAB files, were copied byte for byte
from the stage-1 ZIP and stage-2 v3 ZIP. Both original internal manifests were
verified during assembly. The two PASS reports were copied verbatim. The outer
README, exclusion rules, newline-preservation rule, validation record, coverage
map and package inventory are new documentation/packaging files, not historical
study scripts. No MATLAB analysis function or test criterion was modified.

No MATLAB runtime execution was performed in the packaging environment. Moving
the intact component directories beneath a common parent preserves their relative
layout, but does not itself provide a new runtime result.
