# Stage 2 v2: synthetic-fixture syntax correction

The original stage-2 package stopped at stage 1/5 in the user's MATLAB
session with a parse error at line 59 of `src/cc_synthetic_group_fixture.m`.
That line was missing the final closing parenthesis of the denominator.

The only MATLAB source edit in v2 adds that single `)` before the semicolon.
No other MATLAB file is changed. No random seed, artificial-data constant,
model formula, statistical helper, validation threshold, or failure check is
changed. `SHA256SUMS.txt` is regenerated to match the corrected package.

The package root remains `CC_public_code_stage2`; the ZIP filename is
`CC_public_code_stage2_v2.zip`. Extract v2 into a NEW folder. Do not mix it
with the original package or manually bypass its checksum verification.

The original failure is a synthetic test-code syntax error, not a clinical
analysis result. The original run did not reach the synthetic LMM fits.
Stage-1 PASS evidence remains unchanged in `validation/STAGE1_REPORT.txt`.

Validation limits: the source diff and all file hashes were checked during
repair. The corrected package has NOT been executed in MATLAB in the
repair environment. A user-generated SHARE_STAGE2_REPORT.txt is required
before any stage-2 runtime success can be claimed. Any further warning or
error must be reported, not suppressed to obtain a passing status.

Do not upload this preparatory package as a completed public release.
