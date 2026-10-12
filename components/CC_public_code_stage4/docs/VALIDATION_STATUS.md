# Validation status before author execution

- No MATLAB runtime is available in the preparation environment.
- The new stage-4 demo has NOT yet passed MATLAB execution.
- Earlier author-supplied PASS reports apply only to their corresponding
  stage-1, stage-2 v3 and stage-3 v2 components; they are not stage-4 evidence.
- Static preparation checks include source-block comparison, dependency byte
  equality, delimiter/block checks, custom-function presence and manifest
  verification. They are not a MATLAB parser or numerical runtime test.

The demo writes RUNNING, PASS, REVIEW_REQUIRED or FAIL to a new report.
A fatal assertion or MATLAB error makes the run FAIL. Any recorded fitting
warning makes completed checks REVIEW_REQUIRED. Warning capture records the
last warning per monitored call/fit, not every possible warning; no warnings
are suppressed. The source defaults, including optimizer/Hessian settings,
are not tightened or relaxed to obtain PASS.

Numerical checks compare deterministic small rank calculations and native
MATLAB calls, and compare five source-block model refits on artificial input.
They do not compare against clinical effect sizes or counts. The small exact
rank test has 6 artificial observations and an enumerated 2/20 tail outcome;
that value is a mathematical unit-test target, not a clinical finding.

Per-model source comparisons use absolute/relative mixed tolerances:
`tol * max(1, abs(reference))`; 1e-6 for F/denominator-df outputs and 1e-7
for source model coefficients/SE/t/df/P/CI; deterministic rank and transform
checks are normally 1e-12. Near-zero P comparisons are not relative-accuracy
certifications. Real-cohort numerical equivalence remains untested.

Remaining scope outside this test: patient-record eligibility, real exclusions,
clinical route equivalence, EDF rates other than the earlier tested 500-Hz
fixture, figure export, full reproducibility packaging, license/citation
metadata and a final clean checkout review. This component does not authorize
publication of a repository or create a DOI.
