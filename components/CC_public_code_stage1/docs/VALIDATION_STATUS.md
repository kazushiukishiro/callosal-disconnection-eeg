# Validation status

## Completed in the authoring environment

- Original-source identity checked using SHA-256 for all seven source files.
- Required configuration fields compared with all `config.*` references in the sources.
- Artificial fixture count arithmetic checked independently: 85 candidate
  epoch-region rows, 80 selected rows, 20 state-region summaries and 16 paired times.
- The 30-s / 200-Hz dwPLI spectral window arithmetic gives 29 windows of 2 s
  with 50% overlap.
- The assembled file list and source text were reviewed for unintended bundled
  raw data, long literal identifiers, workstation paths and credentials.
- Archive members are only MATLAB source, text and Markdown. This review is not
  a universal sensitive-information detector or a legal/licensing clearance.

## Not completed in the authoring environment

- No MATLAB installation or execution was available.
- No MATLAB syntax checker/compiler or full functional execution was available.
- MATLAB `edfwrite` / `edfread` round trip, Wavelet Toolbox calculations and
  the newly assembled harness require the user's run.
- No claim of numerical or scientific validation follows from the static checks.

## Runtime checks implemented in the new harness

1. Checksum manifest and source/dependency resolution.
2. Artificial small-overlap and positive-gap handling by supplied EDF loader.
3. Selected dwPLI edge cases and signal-exchange symmetry.
4. Per-recording pipeline execution on a newly generated two-file recording.
5. Artificial Pre selection, Post guard/selection and exact-time output coverage.
6. Finite/range checks on selected synthetic WTC and signal metrics.
7. Shared-output consistency among primary, multiband and signal-metrics functions.

No threshold is tuned after looking at the report, and no clinical statistic is
used as the expected value. A failure must be examined, not bypassed.

## Current overall status

**AWAITING MATLAB RUN.** Neither the GitHub repository nor Zenodo has been
modified by creation of this local package.
