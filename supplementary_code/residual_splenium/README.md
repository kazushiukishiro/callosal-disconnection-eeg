# Supplied residual-splenium analysis source

`analyze_residual_splenium_case.m` is an unchanged copy of the supplied study
function. It accepts the recording folder, study identifier, residual-section
start/completion offsets, configuration and electrode mappings as arguments.
It defines Pre, Splenium and Post states for the completion procedure.

## Dependencies and privacy

The shared original functions `load_cc_edf.m`,
`check_multifile_continuity.m` and `calculate_dwpli.m`, plus `channel_map.m`,
are under `components/CC_public_code_stage1/src/`. Required configuration fields
are read explicitly at the start of the supplied function. The stage-1
`cc_demo_configuration.m` is a synthetic-test configuration, not an automatically
validated replacement for a particular clinical recording's configuration.

No patient EDF, identifier, surgery time, MRI or outcome is bundled here. The
function prints the identifier and recording information provided by the caller.
Use an authorized local working folder, never a public-repository output log,
when processing private records. No real study files are opened merely by
storing or inspecting the function.

## Scope

This is a per-recording analysis function, not a Figure 5 composite renderer or
a cohort-selection script. Clinical MRI panels and complete Figure 5 assembly
are outside this release. The four component PASS reports do not test this
function. It was not executed anew during stage-5 packaging, and equivalence
with the clinical Figure 5 results is not asserted.
