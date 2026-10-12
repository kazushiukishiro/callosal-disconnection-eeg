# Supplementary source provenance

These are existing supplied sources, not new replacements for missing analyses.
No content, names inside the functions, numerical conditions, plotting limits
or data-selection checks were changed when copying them into this source tree.

| Repository path | Source | SHA-256 |
|---|---|---|
| `supplementary_code/figure4/make_figure4_matched_epoch_v3.m` | `CC_Figure4_colours_v3.zip`, member `CC_Figure4_colours_v3/make_figure4_matched_epoch_v3.m` | `19005ab6a97b8f7224833aeb0545a0f340ce471e7d4e81c0d879b9ce3444853e` |
| `supplementary_code/residual_splenium/analyze_residual_splenium_case.m` | Supplied `analyze_residual_splenium_case.m`; duplicate supplied copy has identical bytes | `6b351bac17999ef276283b0a7b20b353566c9d38ea1cc694c380c99899c0e539` |

Only the named `.m` files were copied. The Figure 4 ZIP's input CSVs, shortcut
script, figures and any patient-derived data were not added. The original
residual-splenium function has no hard-coded patient identifier or recording
path. A caller-provided identifier is printed at runtime.

The four component PASS reports cannot be extended to these supplementary
sources. Their status is **source supplied; no new automated runtime validation
in stage 5**. Their inclusion records what is available without claiming that
all manuscript figures can be reconstructed from the public package.
