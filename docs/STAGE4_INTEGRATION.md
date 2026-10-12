# Stage-4 clinical integration into the private preparation repository

This is the storage step closing stage 4, not a new analysis stage.
The runtime evidence is validation/stage4_v1_pass_report.txt, copied verbatim
from the author-supplied SHARE_STAGE4_REPORT.txt. It reports PASS on MATLAB
26.1.0.3312084 (R2026a) Update 4 for package stage4-clinical-v1.
No execution date or run duration is inferred from upload timestamps.

## Files and changes

- Add the intact 18-file components/CC_public_code_stage4/ directory from
  CC_public_code_stage4_clinical.zip, including 10 MATLAB files.
- Add the report without alteration. Preserve component preparation-time
  pending-validation notes and internal checksums as history; the new outer
  validation record and author report establish the later, bounded test status.
- Update root README, validation/coverage documentation and file inventory.
- Add clinical_demo_output/ to .gitignore for generated local outputs.
- Regenerate PACKAGE_SHA256SUMS.txt for the assembled repository snapshot,
  excluding that manifest itself.

Stage-1, stage-2 and stage-3 component files are unchanged. Stage-4 files match
the supplied, author-tested v1 ZIP byte for byte. No MATLAB source or test
criterion was edited, and no MATLAB execution was performed during packaging.

## Evidence boundaries

The report covers 24 fictional covariate rows and 469 primary regional rows,
five reconstructed source-specific measures, 28 source-routed tests, five ML
modifier models and numerical source-block comparisons on artificial inputs.
Recorded fit-warning counts were zero, with only the last warning per monitored
call captured. There is no clinical significance/direction target.

This does not establish patient-record eligibility, real-cohort numerical
reproduction, real exclusions, the historical MRI-laterality route, or figure
export. The source inputs are summaries rather than the stage-1 EDF output.

## Upload scope

The supplied ZIP is a 26-file delta against the prior stage-1/stage-2/stage-3
private preparation snapshot. It is not a full clone and does not establish
that the live GitHub repository matches the assembled local reference.
Upload the CONTENTS of UPLOAD_CONTENTS at repository root. Do not add the ZIP
or the UPLOAD_CONTENTS parent folder to the repository. Do not delete existing
component directories. Include the updated .gitignore explicitly.

No patient EDF, clinical Excel, patient-level CSV, saved clinical model object,
patient image, local diagnostic log, or local command history is included.
The six-stage plan remains: finish stage-5 assembly/release review, then
stage-6 publication and archival. Keep this storage snapshot private.
