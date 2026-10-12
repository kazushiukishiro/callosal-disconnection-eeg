# Validation record for the private stage-1/stage-2/stage-3/stage-4 snapshot

## Evidence

The evidence is the four author-supplied runtime reports in `../validation/`.
All report MATLAB 26.1.0.3312084 (R2026a) Update 4. The reports contain no run
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

## Stage 3 sensitivity v2

The author-supplied report records STATUS: PASS for stage3-sensitivity-v2.
The fixture contains 24 fictional subjects, 469 regional summaries and 190
exact-time summaries. Checks cover package integrity/function resolution,
the natural-log function in the report-writing workspace, logit boundaries,
duplicate rejection, missing-pair rejection and distinct bootstrap cluster IDs
when one subject is drawn repeatedly.

The report records successful logit transform/model checks, explicit
Satterthwaite F tests versus Residual coefficients, and 72 leave-one-out fits
with independent checks of subject/observation deletion. No effect direction
or significance threshold was used as a pass criterion.

Fifty bootstrap draws were requested: 50 primary and 50 exact-time fits
succeeded. Failed fits, fits with recorded warnings and baseline warnings are
all reported as zero. Draw pairing, percentile construction, failure accounting
and RNG restoration checks passed. The monitor records only the last warning
per fit/test; this is not an exhaustive convergence-diagnostics record.

The test uses newly generated artificial summary tables and callable wrappers,
not byte-identical historical clinical scripts. The 50-resample percentile
intervals are not the manuscript's confidence intervals. The full 2000-resample
run and original-versus-wrapper clinical numerical equivalence were not tested.

## Stage 4 clinical v1

The author-supplied SHARE_STAGE4_REPORT.txt records STATUS: PASS for
stage4-clinical-v1 on the same MATLAB version. The fixture has 24 fictional
covariate rows, 24 joined subjects and 469 primary regional rows. These counts
are fixture descriptions, not study inclusion criteria.

The report records package integrity/function resolution, independent
reconstruction of all five primary/exact-time change measures, rejection of
duplicate keys/invalid coding/infinite values/inconsistent MRI codes, and checks
for small exact-rank examples, constant or missing inputs and unavailable groups.

Twenty-eight explicitly source-routed tests passed comparisons of N, medians,
statistics and native MATLAB P values. Independent checks covered tied-rank
Spearman rho, group-0 rank sums and tie-corrected Kruskal-Wallis statistics.
Both primary and exact-time laterality routes remain labelled; the report does
not identify which produced the historical clinical laterality table.

Five ML modifier fits (onset, surgery age, duration, joint and standardized
joint) passed. The report records agreement with extracted source blocks for
synthetic centering, the five models, coefficients, CIs, F/P values and
observation counts. Joined-regional-row centering and unique-patient covariate
correlations were preserved. Satterthwaite omnibus tests were distinguished from
Residual coefficient tests/CIs. These are agreement checks at the tolerances
specified in the component documentation, not a claim of real-cohort equivalence.

Wrapper-fit and reference-fit recorded warning counts were both zero. Monitoring
records only the last warning per test/fit; it is not an exhaustive diagnostic
record. The stage consumes artificial summaries, not stage-1 EDF outputs. Outcome
inputs are already eligibility-masked by the caller; no dates are inspected and
no real follow-up eligibility is verified. Clinical significance or effect
direction is not a test-success criterion.

## Not established

These reports do not establish end-to-end EDF-to-cohort reproduction, equality
with saved clinical outputs, biological validity, or a validated clinical tool.
Stages 2, 3 and 4 use freshly generated summary tables, not stage-1 outputs.

The reports explicitly do not cover native 1000/2000-Hz EDFs, all possible
artefacts/missing-data patterns, real-cohort exclusions/private manifest,
the full 2000-resample patient-cluster bootstrap run, original-versus-wrapper
real-cohort numerical equivalence, postoperative outcome eligibility, or figure
export. Clinical-modifier and rank-test coverage is limited to the stage-4
artificial inputs and checks described above.

## Packaging check performed for this snapshot

All 69 component files, including 30 MATLAB files, retain the bytes from the
stage-1 ZIP, stage-2 v3 ZIP, stage-3 sensitivity v2 ZIP and stage-4 clinical v1 ZIP.
All four internal manifests were verified during assembly. The four PASS reports
are retained verbatim. Stage-1, stage-2 and stage-3 component directories are
unchanged from the previously assembled private snapshot. The outer
README, exclusion rules, newline-preservation rule, validation record, coverage
map and package inventory are new documentation/packaging files, not historical
study scripts. No MATLAB analysis function or test criterion was modified.

No MATLAB runtime execution was performed in the packaging environment. Moving
the intact component directories beneath a common parent preserves their relative
layout, but does not itself provide a new runtime result.


## Stage-5 archive and licensing review

The author-supplied GitHub archive `callosal-disconnection-eeg-main.zip` had
82 files. Its ZIP comment identified commit
`ed6ee982f5f145da43944ec09d7f7de8e309b133`. All 81 entries in the root checksum
manifest matched. All 69 files in the four component folders, including 30
MATLAB files, matched the author-tested source ZIPs byte-for-byte. All four
component manifests passed, and all four root PASS reports matched the supplied
reports without modification.

The review then added the authorized MIT License and creator citation metadata,
updated release-scope documentation, and included two additional, unchanged
supplied `.m` sources: matched Figure 4 colour v3 and residual-splenium analysis.
These two functions are **not covered by the four component PASS reports**.
No new MATLAB execution or figure export was performed during packaging.
The final source tree contains the original 30 MATLAB files plus these two.

All inspected files were text. No bundled patient EDF/MAT, clinical spreadsheet,
CSV/TSV, image, local diagnostic log, private path or recognized credential
pattern was found in the reviewed snapshot. Source literals and matched patterns
were inspected; this is not a guarantee against all identifiers or a review of
past commits. A GitHub source ZIP is not a Git-history audit.

The root LICENSE supersedes preparation-time license-pending statements in
unchanged snapshots. The retained statements are history, not alternative
licensing terms. No clinical workflow or numerical clinical equivalence has
been newly established by this packaging step.
