# Source provenance

These seven files are byte-for-byte copies of the supplied source files. Only upload suffixes in filenames were removed. No numerical computation, input selection, or threshold was edited.

| Candidate file | Supplied filename | SHA-256 |
|---|---|---|
| `src/analyze_cc_case.m` | `analyze_cc_case(2).m` | `8670ef6abd956cc4a89ad931383d7bc98b4b0f53ee56e4ca9a4de47a8cdca515` |
| `src/analyze_cc_case_multiband.m` | `analyze_cc_case_multiband.m` | `9d51d4e312448c69eb2984168684a04bf5e8db8b28dc7222304fac2f344ecf65` |
| `src/analyze_cc_case_signalmetrics.m` | `analyze_cc_case_signalmetrics.m` | `00da559323cecce3362e17aec6a7960e5d247a7ce8a36b9989805925b838d874` |
| `src/calculate_dwpli.m` | `calculate_dwpli(2).m` | `a1d1538e3b930320027c9b27c9dd89fd12df0f9b6afa75a8907a052333008f18` |
| `src/load_cc_edf.m` | `load_cc_edf.m` | `6d11eba1005456ceee7ae537eead0d46235cf7a20a9888884b45496383d668e2` |
| `src/check_multifile_continuity.m` | `check_multifile_continuity.m` | `e3b22890f3314e46d2a56dd6bd0cf9a42e96588f7fcad8e91c339e8134c8f752` |
| `src/channel_map.m` | `channel_map.m` | `e4d2bc65c0e04e4e50b2be5a06b8a3c958a4659e2d82975c9c7fb069fd2b17a0` |

## New files and scope

`run_synthetic_demo.m`, `tools/cc_demo_configuration.m`, `tools/cc_demo_make_recording.m` and `tools/cc_demo_write_edf.m` are NEW packaging / test utilities. They are not historical study analysis scripts. Their signal amplitudes, random seed, recording length, artificial record identifier, start date, event times and file boundaries are new software-test fixtures, not patient-derived values.

The configuration in the test specifies the documented processing parameters: native demo sampling at 500 Hz, target 200 Hz, 30-s epochs, 1-40 Hz filtering, primary 4-13 Hz, 600-s Pre search, 10 accepted Pre epochs, 120-s post guard, 600-s Post search, minimum 3 and maximum 10 Post epochs, electrode absolute amplitude 1000 uV, range 2000 uV and SD 0.5 uV. This test configuration does not read or replace project_config.m.

## Important distinctions

- These source files are reusable per-recording functions, not the final 32-patient cohort assembly. The nine technical epochs and seven exact-time exclusions are not generated or applied by this demo.
- The two complementary per-recording functions also compute WTC/intrahemispheric summaries; the demo checks consistency of shared outputs. It does not reproduce the later cohort-level post hoc epoch-matching procedure.
- In historical load_cc_edf.m, the opening comment describes an older small-gap rule. The actual executed branches trim negative overlaps of up to 2 s and preserve every positive gap by padding with NaN. This code/comment discrepancy is documented, not silently corrected here. Both executed branches are tested on artificial EDFs.
- Some historical comments describing pipeline order or Pre/Post selection are abbreviated. Numerical operations are preserved exactly. Publication documentation should describe the executed operations, not rely on abbreviated historical comments.
- Generic variable names such as StudyID remain in the source interface. The test supplies only the explicitly artificial identifier 900001. No real identifier or patient event time is bundled.
- Global LMMs, original-versus-matched cohort comparisons, clinical analyses, the saved-CORE audit and Figure 4 v3 packaging remain to be assembled into the later release candidate. This stage is not the v1.0.0 archive.
