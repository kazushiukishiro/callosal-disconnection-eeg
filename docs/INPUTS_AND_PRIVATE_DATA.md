# Inputs, private-data boundary and reproducibility limits

## Per-recording functions

The original functions accept a recording folder, an event-row table, a config
structure and electrode mappings. Their exact arguments are in the function
headers. The original `eventRow` interface uses column 2 for the identifier and
columns 8, 10 and 12 for the start/transition/completion offsets in seconds.
Do not substitute a clinical table with a different positional layout. The
stage-1 synthetic recording builder demonstrates the interface without using
patient headers. `channel_map.m` records the supplied Nihon Kohden A-channel
mapping and five bipolar regions; a different acquisition montage requires a
separate justified mapping, not silent relabelling.

The synthetic configuration is supplied as a test fixture. It uses a 200-Hz
target rate, 30-second epochs, a 1-40-Hz filter, a 4-13-Hz primary band, a
600-second Pre search, ten required Pre epochs, a 120-second post guard and a
600-second Post search with 3-10 retained Post epochs. Those values do not
by themselves validate every clinical recording or native sampling rate.

## Group and sensitivity components

Stage 2 documents candidate epoch keys `(CaseNo, State, Region, StartSec)` and
primary-selected keys. Its source checks uniqueness, finite values, group counts
and explicit selection limits. The primary and exact-time tables are distinct
inputs. Stage 3 consumes regional and exact-time summary tables with their
required variables and category levels; see its `docs/INPUTS_AND_LIMITS.md`.
No cohort of 32 patients is reconstructed or selected by these synthetic drivers.

## Clinical functions

See stage-4 `docs/INPUT_SCHEMA_AND_ROUTING.md` for exact columns, categorical
codes and the explicit primary/exact-time routing plan. Joins require unique
patient keys and valid input coding. Missingness is applied per comparison.
Outcome inputs must be masked upstream for valid follow-up and applicability.
No clinical date is read, and a test does not establish a patient's eligibility.

## Private technical exclusions

Keep the final approved patient-level exclusions and their reasons in an
access-controlled manifest outside this repository. Apply them to the correct
input level before the corresponding clinical analysis: an epoch-region key is
not interchangeable with an exact-time Inter/Intra row. Verify the keys and
counts against the authorized saved dataset. Do not substitute synthetic
exclusions for real decisions, infer a private manifest from a P value, refill
excluded rows without an explicit justified rule, or place patient identifiers
in public source literals.

This source tree does not include a complete clinical manifest loader or
private-cohort assembly driver. The source/manifest interface is documented here
as a requirement; it is not claimed to have been implemented or clinically
validated as a one-command public workflow.

## Synthetic data and figures

Synthetic inputs are constructed at runtime by the included source code; no
pre-generated patient-like dataset or patient-derived model container is shipped.
Stages 2-4 create artificial summaries independently, not by carrying forward
stage-1 EDF outputs. These fixtures illustrate software operation, not the
study's effect sizes or statistical significance.

The supplementary Figure 4 function reads authentic analysis-summary/status
CSVs and makes an output copy of them. Run it with private inputs only from a
separate local working copy. Its README lists all five required input files and
its checks. Figure 1 artwork, Figure 2/3 final rendering and the Figure 5 MRI
composite are not part of the public reproduction scope.
