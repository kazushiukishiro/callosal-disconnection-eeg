# Stage 2 v3: empty selected-time comparison in the test harness

## Evidence and scope

The user's R2026a Update 4 v2 report passed package checksums/function
resolution, then stopped with `CCGroupDemo:Selection` in the selection unit
stage. That identifier is emitted by the single assertion in
`verifySelection`, not by the primary selection algorithm or an LMM.
The short report did not record the actual compared shapes/times.

The v2 verifier uses `a=[]` for an under-threshold group and compares
`sort(got)` with `sort(E.StartSec(a))` via `isequal`. An empty logical
selection from a column can be 0-by-1, whereas `[]` indexing can produce
0-by-0. Equality of numeric arrays includes shape. Both lists can therefore
contain zero times but be flagged as different. This is an identified defect
in the newly written verifier, consistent with the failure location.

## Change

Only `run_synthetic_group_demo.m` is changed among the MATLAB source files.
The verifier now compares `isequal(sort(got(:)),sort(expected(:)))` via a
small local helper. It still demands identical time values and multiplicity;
no tolerance, clinical count, threshold, or significant-result target was added.
The original selector, numeric helpers, four `src/*.m` files, model formulas,
synthetic-group fixture, random seeds, and bootstrap settings are unchanged
from v2 (verified byte-for-byte). The v2 parenthesis repair is retained.

The runner also adds:
- ten deterministic boundary-test groups, including fewer than ten Pre epochs,
  fewer than three Post epochs, priority/cap checks, bad flags and NaN values;
- negative tests that deliberately insert/delete/swap a selected epoch, which
  must still raise a selection error;
- an empty-array shape probe in the shared report to record the user's actual
  runtime behavior instead of asserting the dimensions in advance;
- more specific stage labels and basename/line-number error locations;
- selection mismatch details (fictional keys/times only) in the share report.
Arbitrary exception text and absolute paths remain in LOCAL_DIAGNOSTICS.txt.

## Validation limits

The repair environment has no MATLAB executable. Source differences, package
hashes, and an independent Python count/time logic check were examined. The
Python check is not a MATLAB runtime test or a test of MATLAB LMM functions.
Do not describe v3 or stage 2 as PASS until the new user-generated report shows it.
The previous FAIL report is retained unmodified in validation/STAGE2_V2_FAIL_REPORT.txt.

Extract this ZIP into a NEW folder; do not overlay v2 or disable checksum tests.
The inner folder remains `CC_public_code_stage2`.
Keep this candidate separate from clinical project data and the GitHub release.
