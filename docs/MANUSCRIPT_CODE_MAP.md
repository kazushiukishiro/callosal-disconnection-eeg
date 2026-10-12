# Manuscript-to-code map and release boundaries

This map describes the source files actually shipped, not a promise that all
clinical results or publication figures can be reconstructed from public inputs.
No new analysis was invented to fill a missing-source gap.

| Manuscript area | Public source | What remains external / unverified |
|---|---|---|
| EDF acquisition/import, channel mapping, bipolar derivations, QC, epoch windows, resampling/filtering, WTC and dwPLI | Stage-1 `src/analyze_cc_case.m`, `load_cc_edf.m`, `check_multifile_continuity.m`, `channel_map.m`, `calculate_dwpli.m` | Patient EDFs, actual event offsets and private technical exclusions; synthetic test at 500 Hz only |
| Frequency-resolved WTC and amplitude/power | Stage-1 `analyze_cc_case_multiband.m`, `analyze_cc_case_signalmetrics.m` | Final clinical epoch-selection/exclusion decisions are not inferred by the demos |
| Primary-key matching, regional/patient aggregation, patient-first normalization | Stage-2 `src/cc_public_group_ops.m` and example driver | Final cohort-specific assembly from private sources is not a shipped one-command workflow |
| Primary, regional, exact-time and complementary mixed models | Explicit fits in stage-2 `run_synthetic_group_demo.m`; reusable table/inference helpers | Driver inputs are synthetic, not the final clinical cohort |
| Regional contrasts / Supplementary Table 1 | Stage-2 `cc_regional_contrasts.m` | Synthetic contrast/invariant checks are not clinical table equality checks |
| Matched dwPLI contrasts / bootstrap | Stage-2 group helpers | Patient-paired resampling is distinct from LMM cluster resampling |
| LOO, refitted cluster bootstrap and logit / Supplementary Table 3A | Stage-3 `src/cc_wtc_sensitivity.m`; extracted historical source blocks | New callable wrappers; clinical-output equivalence and full 2,000-replicate run not tested |
| Clinical modifiers and ranked comparisons / Supplementary Tables 5-6 | Stage-4 join, routing, rank-test and modifier functions; extracted reference blocks | Real follow-up eligibility and the historical MRI-laterality source route not established |
| Figure 4 matched colour-v3 plotting | `supplementary_code/figure4/make_figure4_matched_epoch_v3.m` | Authentic five-file analysis CSV inputs required; none bundled; no new automated export test |
| Residual splenial completion analysis | `supplementary_code/residual_splenium/analyze_residual_splenium_case.m` | Supplied original function, not covered by the four synthetic tests |
| Figure 1 illustration; Figure 2/3 final rendering; Figure 5 composite and MRI panels | Not supplied as final graphics-generation workflows | No claim that all publication figures are reproducible from the public archive |

The original-epoch and post hoc epoch-matched paths are distinct. Do not present
an original-epoch figure as matched, place Matched F/P annotations on Original
rows, or merge the primary and exact-time clinical metrics under an ambiguous
column name. Historical code/notes are identified as such.

The scope for version 1.0.0 is **analysis sources and refactored components with
synthetic demonstrations**, plus the two separately labelled supplementary
sources. It is not a complete raw-EEG-to-all-tables-and-figures clinical package.
The manuscript availability wording must reflect this scope.
