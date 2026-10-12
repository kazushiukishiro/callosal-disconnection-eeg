# Input schema and explicit source routing

All numerical functions are in-memory functions. The demo constructs every
input from fixed-seed artificial values; real inputs are neither required nor
read. Column names in this document describe interfaces, not patient records.

## Connectivity inputs

`W`: one primary regional mean per `CaseNo`, `State`, `Region`; numeric `Value`.
`E`: one exact-time mean per `CaseNo`, `State`, `ConnectionType`; numeric
`MeanWTC`. States are `Pre`, `Anterior`, `Posterior`, `Post`. Regions are
`CP`, `FT`, `PO`, `T`, `TO`. Connection types are `Intra`, `Inter`.

`cc_connectivity_change_sources` (unchanged stage-2 helper) returns:

| Column | Definition |
|---|---|
| Primary_PrePost | Primary patient mean Pre minus Post |
| Primary_AnteriorPosterior | Primary patient mean Anterior minus Posterior |
| Exact_PrePost | Exact-time Inter Pre minus Post |
| Exact_AnteriorPosterior | Exact-time Inter Anterior minus Posterior |
| Exact_Selective | (Inter Pre - Inter Post) - (Intra Pre - Intra Post), all exact-time |

Primary patient/state means average the available regional means with equal
region weights; they do not pool all epochs. The five columns are not merged
into one anonymous 'reduction' variable. Complete cases can differ by source.

## Clinical input C

One row per unique pseudonymous `CaseNo`, with real numeric columns:
`AgeOnset`, `AgeSurgery`, `Duration` (years); `Sex` (0 male, 1 female);
`MRIAbnormality` (0 absent, 1 present); `MRILaterality` (0 none, 1 bilateral,
2 unilateral); `OverallOutcome`, `DropOutcome` (Williamson grade 1-5, higher
worse). Missing observations use NaN. No imputation is performed.

**Outcome eligibility is an upstream responsibility.** These columns must
already reflect the study's follow-up and drop-attack applicability criteria.
The demo does not calculate follow-up duration, inspect dates, establish
eligibility or convert missing outcomes into seizure freedom. The synthetic
fixture uses arbitrary missing values solely to exercise per-analysis masks.

New interface guards reject duplicate keys, infinite values, invalid code
values, and inconsistent finite MRI binary/laterality codes. These guards are
not substitutes for checking source records and do not recode observations.
Extra EEG or clinical rows do not cause an automatic 32-person count check.
The join is by key, not input row number.

## Routing in cc_clinical_test_plan

- Original age-at-onset/age-at-surgery/duration rank correlations: three
  exact-time measures.
- Additional age-at-onset source-sensitivity correlations: two primary
  reductions, explicitly marked as post hoc source-sensitivity outputs.
- Binary sex/MRI and seizure-outcome tests: two primary reductions and the
  exact-time selective reduction (as clarified in the final manuscript).
- MRI laterality: both primary and exact-time versions of the two ordinary
  reductions, plus exact-time selective reduction. These alternative routes
  are labelled explicitly; the package does not assert which generated the
  historical clinical Table 5C or silently choose between them.

The plan returns 28 labelled tests. It does not select significant rows.
Retain the `Metric` and `Source` columns when inspecting any generated output.

## Modifier models

Modifier LMMs use the primary regional table joined to clinical covariates,
not the exact-time table and not the reduced paired-patient subset. Centering
and standardization are over joined regional rows, including repeated
patient covariates, as in the supplied script. They are NOT silently changed
to equal-patient centering. Each model subsequently handles its own missing
covariates through fitlme's row exclusion; the joint models require both onset
and duration. The model includes State interaction(s), Region, and random
intercepts for CaseNo and CaseNo:Region.

The wrapper explicitly sets FitMethod='ML', equivalent to the supplied
script's default. F-tests use Satterthwaite df; the supplied Coefficients
property uses Residual df for t-tests/CIs. Bootstrap is not involved.

## Rank inference

Spearman tests use `corr(...,'Type','Spearman')` on each pair of finite
vectors. Wilcoxon tests call `ranksum(group0,group1)` without forcing the
exact/approximate choice; the default native MATLAB choice is recorded.
Group-0 rank sum is the pooled-rank sum of the first sample, not U.
Kruskal-Wallis tests use `kruskalwallis(values,groups,'off')`. No figures are
opened and no multiplicity corrections are added. Undefined tests have a
reason code and NaN rather than a made-up P value.
