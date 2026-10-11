# Coverage and release preparation

## What this snapshot contains

| Area | Included | Evidence / limit |
|---|---|---|
| Per-recording EDF import, QC, bipolar mapping, resampling/filtering, WTC/dwPLI, exact-time summaries | Seven supplied source files and a new artificial-EDF test driver | Stage-1 PASS for its 500-Hz fixture, not all native rates |
| Multiband and signal metrics | Supplied per-recording functions | Stage-1 common-output agreement on the artificial fixture |
| Group selection, keyed matching, grouping and patient-first normalization | Retained numerical helpers and new validated-input dispatcher | Stage-2 v3 PASS on independent artificial summary tables |
| Primary/regional/exact-time/complementary models and inference interfaces | Synthetic driver and retained helpers | Stage-2 PASS, not a final-cohort input/assembly command |
| Regional adjacent-stage contrasts and Holm adjustment | Newly packaged contrast wrapper | 15-contrast construction/invariant checks; no clinical-output equality claim |
| Paired-patient dwPLI bootstrap | Retained helper, 10,000 resamples per contrast | Stage-2 PASS; not a patient-cluster LMM-refit bootstrap |
| Primary/exact-time connectivity-change definitions | Newly packaged source-separation function | Artificial missing-pair and source-subset checks |
| Final-cohort exclusions and initial cohort assembly | Not assembled as a clinical release workflow | Must use an explicitly documented interface for a private manifest; never copy patient identifiers into public source |
| LOO, refitted patient-cluster bootstrap, logit sensitivity | Stage-3 v2 callable wrappers with historical source excerpts | Stage-3 PASS for logit, 72 LOO fits and 50 bootstrap draws per paired model family; not clinical-output equivalence or the full 2000-resample run |
| Modifier LMMs, clinical rank tests, outcome eligibility | Not assembled in this snapshot | Need final-source mapping and declared validation status |
| Manuscript Figures 2-5, including matched Figure 4 v3 | Not included | Preserve the final source-data/plotting relationship; do not substitute old Figure 4 code |

## Next step after private upload

Finish a source-to-manuscript map for the remaining final scripts. Separate
unchanged historical numerical code from new wrappers, synthetic fixtures and
plotting changes. Include public input schemas and a private-manifest interface,
not actual clinical records. New or adapted code needs an appropriate check;
previous PASS reports must not be carried forward as proof of modified code.

There is no need to repeat the three unchanged component tests merely to store this
snapshot. Their evidence is preserved. Untested features must be labelled as
untested; missing workflows must not be described as included.

Before public release, either assemble the stated manuscript-wide code scope,
or explicitly narrow the repository and manuscript availability statements to
what is actually provided. Do not silently replace study code with a newly
invented analysis pipeline to fill a missing-source gap.

## Release gates

1. Finalize scope, source provenance, entry points, dependency/input documentation
   and the validation status of each shipped component.
2. Review the actual upload set for patient data, private paths, credentials and
   patient-derived objects. Review ownership/third-party terms and finalize a
   license with the authorized rights holder. Confirm software creators for the
   citation metadata; paper authorship is not automatically software authorship.
3. Verify the repository snapshot to be released, then complete public release
   and archival steps. Confirm that the specific archived software DOI resolves
   before inserting it in the manuscript. No v1.0.0 or DOI is assigned here.

This preparation snapshot is not a statement that those gates have been met.
