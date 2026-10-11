# Dependencies and execution scope

Intended first test environment: MATLAB R2026a, Signal Processing Toolbox and
Wavelet Toolbox. MATLAB source code / toolbox binaries are not distributed.
This candidate uses built-in MATLAB table, filesystem and Java checksum APIs.

Primary documentation consulted for the new test harness:

- https://www.mathworks.com/help/signal/ref/edfheader.html
- https://www.mathworks.com/help/signal/ref/edfwrite.html
- https://www.mathworks.com/help/wavelet/ref/wcoherence.html
- https://www.mathworks.com/help/signal/ref/bandpower.html
- https://www.mathworks.com/help/matlab/ref/run.html

`edfwrite(...,'InputSampleType','physical')` is used for newly generated
physical-valued synthetic signals. The source loader reads those files only.
`wcoherence` and `bandpower` calls remain in the unchanged supplied sources.

The output directory is created below the extracted package. Do not edit or run
this candidate in the private study project. The function restores the prior
MATLAB path and directory but deliberately keeps the new synthetic outputs and
reports for inspection.

No Statistics and Machine Learning Toolbox function is invoked in this stage.
The planned cohort models are outside this test and will require that toolbox.
