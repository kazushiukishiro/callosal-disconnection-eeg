# Inputs and limits

The demonstration takes no input arguments or real data files. It generates
new artificial tables. The reusable wrapper's schemas are as follows.

## Regional WTC input `W`

One row per `CaseNo`, `State`, `Region` combination:

- `CaseNo`: non-missing identifier (string/categorical/numeric convertible to
  string); no vertical-bar character.
- `State`: Pre, Anterior, Posterior, Post.
- `Region`: CP, FT, PO, T, TO.
- `mean_MeanWTC_4_13`: finite, real numeric WTC in [0,1].

These are region summaries, not epochs or patient-averaged values. Real users
must supply the intended **already QC-clean** summaries; this wrapper does
not select a clinical version or apply clinical exclusion identities.

## Exact-time WTC input `X`

One row per `CaseNo`, `State`, `ConnectionType` combination:

- `ConnectionType`: Intra or Inter.
- `MeanWTC`: finite, real numeric WTC in [0,1].

Both connection types must be present for each case/state included. A whole
case/state pair may be absent. The input is the patient/state/connection-type
summary, not the long epoch table. Exact-time matching and exclusion decisions
must already have been applied upstream for a real-data call.

The shared-draw bootstrap requires the same source case set in W and X; it does
not silently replace it by their intersection. LOO uses the source case set of
each model family separately.

## Reusable calls (not instructions to run clinical analyses now)

```matlab
[L,C] = cc_wtc_sensitivity('loo',W,X);
G = cc_wtc_sensitivity('logit',W);
B = cc_wtc_sensitivity('bootstrap',W,X); % supplied source default: 2000 draws
```

The demo explicitly passes 50 instead. `ProportionNegative` is a descriptive
fraction of bootstrap estimates below zero, **not a P value**. LMM bootstrap
percentiles and Residual model-based coefficient confidence intervals are
separate outputs; do not attach one to the other's statistic by name alone.

## Not included or certified

No clinical source/version verification, original-versus-wrapper equality,
final-cohort exclusion manifest, native-rate EDF test, clinical modifier LMM,
clinical rank/correlation test, follow-up eligibility, or figure export is added
by this package. The 50-resample test cannot certify the full 2000-resample run
or the precision/coverage of percentile confidence intervals.

This is software preparation, not a validated clinical tool or a change to the
manuscript's reported analyses.
