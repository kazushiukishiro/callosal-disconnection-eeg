# Callosal-disconnection EEG: stage-1 synthetic execution check

**Status: local validation candidate. Not a public release and not the complete
manuscript reproduction package.** Do not replace the repository README or
create a GitHub/Zenodo Release with this candidate.

This package contains seven byte-identical copies of previously supplied
per-recording MATLAB sources and a new, self-contained synthetic test harness.
It is the first executable component for the planned code release accompanying:

**Sequential corpus callosal disconnection reveals preferential interhemispheric
network disruption**

## Run

Use MATLAB R2026a with Signal Processing Toolbox and Wavelet Toolbox. The
harness checks the actual availability and resolution of its dependencies.
Statistics and Machine Learning Toolbox is not exercised in this stage; it will
be needed for the later cohort-model component.

Extract the complete package into a new folder outside the research project.
Do not copy a single `.m` file out of the package, and do not edit files before
the initial checksum-verified test.

```matlab
cd('path_to_extracted_CC_public_code_stage1')
reportDir = run_synthetic_demo();
winopen(reportDir); % Windows only; otherwise open the printed directory.
```

There are no patient-file prompts. No EDF/MAT/Excel file supplied by a user is
read. The harness creates fresh artificial EDFs and a new output folder.
It restores the previous working directory and MATLAB path on return.

Send only `SHARE_DEMO_REPORT.txt` for review. `LOCAL_DIAGNOSTICS.txt` may contain
workstation paths and is not for public distribution. The generated EDFs and
`SYNTHETIC_ONLY_state_summary.csv` are synthetic-only, but are not part of the
source ZIP and should not be uploaded at this stage.

## What is exercised

- Artificial EDF headers, a two-file contiguous recording, and a separate
  small-overlap / positive-gap import test.
- The supplied electrode mapping and bipolar montage.
- Epoch QC, per-epoch resampling/filtering, WTC and dwPLI, and per-recording
  interhemispheric/intrahemispheric exact-time summaries.
- The supplied multiband and signal-metrics per-recording functions.
- Agreement of common WTC/dwPLI outputs among the three per-recording functions.
- Selected numerical edge cases of the supplied dwPLI function.

Processing parameters are explicit in `tools/cc_demo_configuration.m`.
The artificial recording is 630 s at 500 Hz with 16 channels. Its event offsets
330/360/390 s, date, record identifier and stationary signal generator are NEW
software-test choices, not patient data. The expected 85 candidate epoch-region
rows, 80 selected rows, 20 state-region summaries and 16 exact-time rows derive
from this artificial fixture alone. They are unrelated to the manuscript's
patient counts or fitted statistics.

The recording is intentionally stationary across its artificial event labels.
No decrease, P value or clinical effect size is imposed or required to pass.

## Scope limits

This is a **smoke test**, not clinical validation. It does not test every QC
failure mode, every supported native sample rate, all possible gaps, the final
cohort's technical exclusions, cohort-level post hoc epoch matching, Figure 4
v3, LMMs, patient-cluster bootstrap, clinical analyses or postoperative follow-up.
Those components must still be assembled, documented and checked before the
complete repository is described as available in the manuscript.

The historical per-recording source files are not a substitute for the later
final-cohort assembly scripts. In particular, the historical source comments
are not all accurate descriptions of the executed small-gap / selection rules;
see `docs/SOURCE_PROVENANCE.md`. This candidate preserves the source bytes
instead of silently correcting their logic or comments.

The authoring environment did not have MATLAB. No claim of successful MATLAB
execution is made until the user's report confirms it.

## Privacy and licensing

Only source code and documentation are bundled. There are no real patient
records, patient-derived model objects, clinical spreadsheets, EEG files,
credentials, local command histories, actual event tables or MRI images.
Synthetic EDFs are generated locally with explicitly fictional headers.

A redistributable software license has not yet been assigned. Confirm source
ownership, institutional requirements and third-party terms before public
release. This ZIP must not be described as the final licensed software archive.
