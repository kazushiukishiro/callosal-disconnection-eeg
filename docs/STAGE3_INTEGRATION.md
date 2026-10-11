# Stage-3 sensitivity integration into the private preparation repository

The new runtime evidence is `validation/stage3_v2_pass_report.txt`, copied
verbatim from the author-supplied SHARE_STAGE3_REPORT(1).txt. It reports PASS
on MATLAB 26.1.0.3312084 (R2026a) Update 4. No test run date or duration is
inferred from the uploaded filename or file timestamp.

## Files and changes

- Add the intact 17-file `components/CC_public_code_stage3/` directory from
  CC_public_code_stage3_sensitivity_v2.zip, including four MATLAB files.
- Add the latest stage-3 PASS report. Keep the original component documentation,
  source excerpts, preparation-time pending-validation notes and hashes intact.
  Those notes describe the preparation history; the later report documents
  success for the stated synthetic test only.
- Update the root README, validation/coverage documentation and inventory.
- Add `sensitivity_demo_output/` to the root .gitignore. This excludes newly
  generated stage-3 output directories when using Git, but does not certify
  file privacy or protect manual browser uploads.
- Regenerate the root PACKAGE_SHA256SUMS.txt for the assembled repository
  snapshot, excluding that manifest itself.

All stage-1 and stage-2 component files are unchanged. The stage-3 component
is unchanged from the tested v2 ZIP. No MATLAB source or test criterion was
edited during this integration. No MATLAB execution was performed here.

## Evidence boundaries

The report records 72 LOO fits and 50 successful primary plus 50 successful
exact-time bootstrap fits, with no recorded failed fits or fit/baseline warnings.
Warning monitoring records the last warning per fit/test, not all diagnostics.
The 50-resample test is not the full 2000-resample run. This integration does
not establish original-versus-wrapper clinical numerical equivalence,
real-cohort exclusion correctness, EDF-to-cohort reproduction, clinical
modifier/rank-test coverage or figure export.

## Upload scope

The distributed update is a delta against CC_GitHub_private_stage12.zip,
not a full clone and not evidence that the live GitHub files have been checked.
Upload the CONTENTS of UPLOAD_CONTENTS at repository root. Do not upload the
ZIP or add an UPLOAD_CONTENTS parent folder to the repository. No existing
stage-1/stage-2 directory needs to be deleted or uploaded again.

Keep this as a private preparation snapshot. License, creators/citation
metadata, remaining manuscript code coverage and release/archive steps
still need to be finalized. No public release or DOI is created by this update.
